#!/bin/sh
# Container entrypoint.
#
# Runs as the non-root `dev` user. It locks down egress with the firewall, seeds
# the sandbox's default Claude Code guidance/settings into the bind-mounted
# config dir on first start (without overwriting anything the user already has),
# then sleeps forever so the real work can happen in long-lived tmux sessions.
set -eu

# Firewall first: the dev user is allowed to run only this script via sudo.
sudo /usr/local/bin/init-firewall.sh

# CLAUDE_CONFIG_DIR is set in the image and points at the bind-mounted dir
# (/home/dev/.claude by default), so seeded files persist across recreation.
claude_home="${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}"
mkdir -p "$claude_home"

# Seed defaults only when absent: never clobber the user's own CLAUDE.md/settings.
if [ ! -e "$claude_home/CLAUDE.md" ]; then
  cp /usr/local/share/claude-code-sandbox/sandbox-CLAUDE.md "$claude_home/CLAUDE.md"
fi

if [ ! -e "$claude_home/settings.json" ]; then
  cp /usr/local/share/claude-code-sandbox/sandbox-settings.json "$claude_home/settings.json"
fi

# Ensure the shell-history file exists in the bind mount so zsh can append to it.
mkdir -p /commandhistory
touch "${HISTFILE:-/commandhistory/.zsh_history}"

exec sleep infinity
