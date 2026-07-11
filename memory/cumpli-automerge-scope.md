---
name: cumpli-automerge-scope
description: "cumpli auto-merge is handled by the repo's own GitHub Actions (auto-merge.yml) — do NOT build a redundant local cron; known gap: it never rechecks a PR after main moves from other merges, so green PRs can sit stale — see the diagnosis/fix steps here"
metadata: 
  node_type: memory
  type: project
  originSessionId: 280d967e-36b0-43c6-b538-7e2c3b45d0f5
---

The cumpli repo (spiegel21/cumpli) already has a **native GitHub Actions auto-merge**: `.github/workflows/auto-merge.yml`. It fires on CI success (and on draft→ready), gates on the full `CI` workflow — both the `verify` and `e2e` (Playwright, demo-mode) jobs in `ci.yml` — handles the stale-base race by updating the branch and waiting for a fresh green run, then squash-merges + deletes the branch and dispatches Deploy. It merges **any** author's green PR (the team's shared pipeline: user is `spiegel21`, collaborator `Napoleon1414`).

We briefly ran a **local CronCreate** auto-merge job as a stopgap (the cloud `/schedule` was unreachable), scoped to the user's own PRs via `--author "@me"`. On 2026-07-02 the user chose to **retire it and rely on the repo's Actions workflow** instead — it's strictly better (runs verify+e2e in the cloud, no laptop needed, handles stale base). The local cron was cancelled.

**Why:** the Actions workflow already enforces the exact gate the user wanted (verify+e2e green) and runs unattended; a local cron duplicated it and only fired while a Claude session was open.
**How to apply:** do NOT re-create a local auto-merge cron for cumpli. If auto-merge misbehaves, fix `auto-merge.yml`/`ci.yml`, not a side-channel poller. For a PR to auto-land it must be non-draft with CI green. See [[cumpli-local-toolchain]], [[ci-wait-use-loop]].

### Known gap: stale PRs never get re-checked (found 2026-07-11)

`auto-merge.yml` is purely **event-reactive** — it only evaluates a PR when (a) *that PR's* CI
completes on a `pull_request` event, or (b) that PR flips draft→ready. It never rescans open PRs
when `main` advances from an unrelated merge. Since a push to `main` runs CI as a `push` event
(not `pull_request`), the workflow's own filter (`workflow_run.event == 'pull_request'`) skips it
entirely — so *nothing* re-evaluates other open PRs after each merge.

Net effect: on a busy day with several PRs merging, every other open PR silently drifts
`behind_by` main with no automatic nudge, and just sits there looking "green but not merging"
even though CI passed. Also saw once: a manual draft→ready flip (PR #217) did **not** produce a
new `auto-merge.yml` run at all (webhook flake, unconfirmed cause) — worth a re-check if it
recurs.

**Diagnosis when a PR "should have merged" but hasn't:**
1. `gh pr view <n> --json isDraft,mergeable,mergeStateStatus` — draft or real conflict blocks it.
2. `gh api repos/spiegel21/cumpli/compare/main...<head>  --jq .behind_by` — if >0 and otherwise
   clean, it's just stale, not broken.
3. `gh run list --workflow=auto-merge.yml` — check whether a run fired *after* the PR's last
   CI success; if not, it's waiting on a trigger that never came.

**Fix:** manually re-kick it — `gh api --method PUT repos/<repo>/pulls/<n>/update-branch -f
expected_head_sha=<sha>` — which is exactly what the bot itself does; this retriggers CI and lets
auto-merge land it once green. True `CONFLICTING` PRs need an actual manual rebase first.
