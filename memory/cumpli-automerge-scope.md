---
name: cumpli-automerge-scope
description: "cumpli auto-merge is handled by the repo's own GitHub Actions (auto-merge.yml) — do NOT build a redundant local cron"
metadata: 
  node_type: memory
  type: project
  originSessionId: 280d967e-36b0-43c6-b538-7e2c3b45d0f5
---

The cumpli repo (spiegel21/cumpli) already has a **native GitHub Actions auto-merge**: `.github/workflows/auto-merge.yml`. It fires on CI success (and on draft→ready), gates on the full `CI` workflow — both the `verify` and `e2e` (Playwright, demo-mode) jobs in `ci.yml` — handles the stale-base race by updating the branch and waiting for a fresh green run, then squash-merges + deletes the branch and dispatches Deploy. It merges **any** author's green PR (the team's shared pipeline: user is `spiegel21`, collaborator `Napoleon1414`).

We briefly ran a **local CronCreate** auto-merge job as a stopgap (the cloud `/schedule` was unreachable), scoped to the user's own PRs via `--author "@me"`. On 2026-07-02 the user chose to **retire it and rely on the repo's Actions workflow** instead — it's strictly better (runs verify+e2e in the cloud, no laptop needed, handles stale base). The local cron was cancelled.

**Why:** the Actions workflow already enforces the exact gate the user wanted (verify+e2e green) and runs unattended; a local cron duplicated it and only fired while a Claude session was open.
**How to apply:** do NOT re-create a local auto-merge cron for cumpli. If auto-merge misbehaves, fix `auto-merge.yml`/`ci.yml`, not a side-channel poller. For a PR to auto-land it must be non-draft with CI green. See [[cumpli-local-toolchain]], [[ci-wait-use-loop]].
