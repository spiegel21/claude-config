#!/bin/sh
# Mirror live ~/.claude personal config into this repo and push if anything changed.
# Reverse of install.sh. Safe to run repeatedly; no-ops when there's nothing new.
set -eu

cd "$(dirname "$0")"
SRC="$HOME/.claude"

copy_if_present() {
  src="$1"; dst="$2"
  [ -e "$src" ] && cp "$src" "$dst"
}

copy_if_present "$SRC/CLAUDE.md" "./CLAUDE.md"
copy_if_present "$SRC/settings.json" "./settings.json"
copy_if_present "$SRC/settings.local.json" "./settings.local.json"
copy_if_present "$SRC/statusline-command.sh" "./statusline-command.sh"

for dir in agents skills commands hooks; do
  if [ -d "$SRC/$dir" ]; then
    rm -rf "./$dir"
    cp -R "$SRC/$dir" "./$dir"
  fi
done

# Memory is keyed by project path; sync this machine's $HOME project key.
PROJECT_KEY=$(printf '%s' "$HOME" | tr '/' '-')
MEM_SRC="$SRC/projects/$PROJECT_KEY/memory"
if [ -d "$MEM_SRC" ]; then
  rm -rf ./memory
  cp -R "$MEM_SRC" ./memory
fi

git add -A

if git diff --cached --quiet; then
  echo "sync.sh: no changes"
  exit 0
fi

git commit -m "Sync personal config from ~/.claude" >/dev/null
git push >/dev/null 2>&1
echo "sync.sh: pushed config update"
