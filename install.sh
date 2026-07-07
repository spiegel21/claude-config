#!/bin/sh
# Restore Claude Code personal config into ~/.claude
# Idempotent; backs up any existing file it would overwrite as <file>.bak
set -eu

cd "$(dirname "$0")"
DEST="$HOME/.claude"
mkdir -p "$DEST"

backup_cp() {
  src="$1"; dst="$2"
  [ -e "$dst" ] && cp "$dst" "$dst.bak"
  cp "$src" "$dst"
}

backup_cp CLAUDE.md "$DEST/CLAUDE.md"
backup_cp settings.json "$DEST/settings.json"
backup_cp settings.local.json "$DEST/settings.local.json"

for dir in agents skills commands; do
  mkdir -p "$DEST/$dir"
  cp -R "$dir/." "$DEST/$dir/"
done

# Memory is keyed by project path; install for this machine's $HOME project key
PROJECT_KEY=$(printf '%s' "$HOME" | tr '/' '-')
MEM_DEST="$DEST/projects/$PROJECT_KEY/memory"
mkdir -p "$MEM_DEST"
cp -R memory/. "$MEM_DEST/"

echo "Installed Claude config into $DEST"
echo "Memory installed into $MEM_DEST"
echo "Remember to: brew install jq && gh auth login"
