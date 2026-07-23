#!/usr/bin/env bash
# git-sync-on-start.sh
#
# Runs at SessionStart and after EnterWorktree. Purpose: never start work on a
# stale base again.
#
# Policy, deliberately asymmetric:
#   - ALWAYS fetch (read-only; cannot touch the working tree).
#   - Fast-forward ONLY when provably safe: an upstream exists, the tree is
#     clean, and HEAD is strictly behind it (no divergence). A plain `git pull`
#     is avoided on purpose -- it can start a merge on a feature branch, or
#     fail halfway on a dirty tree, neither of which belongs in an automatic hook.
#   - Otherwise report the divergence and change nothing.
#
# Also reports how far the current branch is behind the remote default branch,
# which is the failure this hook exists to prevent: the branch is in sync with
# its own upstream while the base it was cut from has moved on.
#
# Emits JSON so the state is visible to the user AND injected into Claude's
# context at turn 1.

set -uo pipefail

payload=$(cat 2>/dev/null || true)
event=$(printf '%s' "$payload" | jq -r '.hook_event_name // empty' 2>/dev/null)
[ -z "$event" ] && event="SessionStart"

emit() {
  jq -n --arg m "$1" --arg e "$event" \
    '{systemMessage:$m, hookSpecificOutput:{hookEventName:$e, additionalContext:("[git-sync] " + $m)}}'
}

# Not a git repo -> silent no-op.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Mid-operation -> never touch it.
gitdir=$(git rev-parse --git-dir 2>/dev/null) || exit 0
for marker in MERGE_HEAD REBASE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG rebase-merge rebase-apply; do
  if [ -e "$gitdir/$marker" ]; then
    emit "git in progress (${marker}) - auto-sync skipped."
    exit 0
  fi
done

# No remote -> nothing to do.
git remote 2>/dev/null | grep -q . || exit 0

if ! git fetch --prune --quiet 2>/dev/null; then
  emit "git fetch failed (offline or no access) - working from local refs."
  exit 0
fi

branch=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo "")
[ -z "$branch" ] && { emit "detached HEAD - fetched, nothing to fast-forward."; exit 0; }

dirty=""
[ -n "$(git status --porcelain 2>/dev/null | head -1)" ] && dirty="yes"

parts=()

upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
if [ -n "$upstream" ]; then
  behind=$(git rev-list --count "HEAD..$upstream" 2>/dev/null || echo 0)
  ahead=$(git rev-list --count "$upstream..HEAD" 2>/dev/null || echo 0)

  if [ "$behind" -gt 0 ] && [ "$ahead" -eq 0 ] && [ -z "$dirty" ]; then
    if git merge --ff-only "$upstream" --quiet 2>/dev/null; then
      parts+=("fast-forwarded ${branch} +${behind} from ${upstream}")
    else
      parts+=("${branch} is ${behind} behind ${upstream} (fast-forward refused)")
    fi
  elif [ "$behind" -gt 0 ]; then
    if [ -n "$dirty" ]; then
      why="uncommitted changes"
    else
      why="diverged +${ahead}/-${behind}"
    fi
    parts+=("${branch} is ${behind} behind ${upstream} - NOT pulled (${why})")
  fi
else
  parts+=("${branch} has no upstream")
fi

# The check that matters most: is the BASE stale, even if upstream is in sync?
def=$(git symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
if [ -z "$def" ]; then
  for cand in main master; do
    git show-ref --verify --quiet "refs/remotes/origin/$cand" && { def="$cand"; break; }
  done
fi
if [ -n "$def" ] && [ "$branch" != "$def" ]; then
  b2=$(git rev-list --count "HEAD..origin/$def" 2>/dev/null || echo 0)
  [ "$b2" -gt 0 ] && parts+=("${b2} behind origin/${def} - rebase or merge before building on it")
fi

if [ ${#parts[@]} -eq 0 ]; then
  exit 0   # fully in sync: stay quiet
fi

out=$(printf '%s; ' "${parts[@]}")
emit "${out%; }"
