---
name: ci-wait-use-loop
description: "How to wait on CI — use a /loop that polls every 5 min and merges when green, not an ad-hoc background poll"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 31292bed-727e-454a-8acf-8c8b752fc02b
---

When waiting for CI to finish on a PR, run the `/loop` skill at a **5-minute** interval (`/loop 5m ...`) that each tick checks whether CI has finished and merges automatically when it's green — keep looping until the PR is MERGED, then stop and report.

**Why:** The user explicitly wants CI waits handled as an explicit recurring auto-merge loop, not a one-off background watcher.

**How to apply:** Whenever a PR's CI is pending and the goal is to land it, invoke `/loop 5m` with a task that: views the PR's CI status; if green and not yet merged, ensures it merges (in the cumpli repo, marking the PR ready lets the auto-merge pipeline squash it — see the repo's `ci-cd` skill; in a generic repo, run the merge directly); if red, stop and report; once MERGED, stop the loop and report. Prefer this over a background bash poll.

**Gotcha (cumpli auto-merge stall, seen 2026-07-01 on PR #134):** the auto-merge pipeline sometimes has `github-actions[bot]` merge `main` into the PR branch to keep it current. That moves the PR head to a new merge commit whose CI workflows land in `action_required` (GitHub won't auto-run workflows triggered by the bot's own GITHUB_TOKEN push), so combined status sticks at `pending`/`UNSTABLE` and the PR never auto-lands — even though CI passed on your actual code commit. `main` is **not** branch-protected, so when the green CI run was for your real commit and the new head only merges unrelated main changes, just merge directly: `gh pr merge <n> --squash --delete-branch`. Verify first that the successful CI run's `headSha` matches your code commit (`gh run view <id> --json headSha,jobs`).
