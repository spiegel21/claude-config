#!/bin/sh
# PostToolUse hook: after Edit/Write, if the touched file is a tracked personal
# config under ~/.claude, mirror it into ~/claude-config and push.
set -eu

REPO="$HOME/claude-config"
[ -x "$REPO/sync.sh" ] || exit 0

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  "$HOME/.claude/CLAUDE.md"|"$HOME/.claude/settings.json"|"$HOME/.claude/settings.local.json"|"$HOME/.claude/statusline-command.sh") ;;
  "$HOME/.claude/agents/"*|"$HOME/.claude/skills/"*|"$HOME/.claude/commands/"*|"$HOME/.claude/hooks/"*) ;;
  "$HOME/.claude/projects/"*/memory/*) ;;
  *) exit 0 ;;
esac

"$REPO/sync.sh" >/tmp/claude-config-sync.log 2>&1 || true
exit 0
