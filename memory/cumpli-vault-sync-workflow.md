---
name: cumpli-vault-sync-workflow
description: "cumpli's cloud vault auto-sync GitHub Action + the gotchas for running Claude headless in this repo's CI"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 896bd5e4-7240-47b9-847e-2bc3877839fb
---

`.github/workflows/vault-sync.yml` keeps the Obsidian vault ([[cumpli-obsidian-vault]]) in
sync on every push to `main` + `feat/demo-digest-slack` — cloud-side, so it covers **all
clones** (reacts to the remote, not a local HEAD). It computes the changed files for the
push range, runs Claude headless to refresh only the affected notes, then a CI step commits
them back (direct on feature branches, PR on protected `main`). Went green 2026-07-08 at
commit `10d6055`.

**Hard-won gotchas for running Claude in this repo's CI (reuse these):**
- **Use `anthropics/claude-code-base-action`, NOT `claude-code-action@v1`.** The latter
  rejects non-PR/issue events: `Action failed with error: Unsupported event type: push`.
  base-action is event-agnostic; inputs are `prompt`, `allowed_tools` (comma-sep),
  `claude_code_oauth_token`, `model`, `timeout_minutes`.
- **Pin an explicit CURRENT model id.** The base-action default (`claude-sonnet-4-20250514`)
  AND the CLI aliases `haiku`/`sonnet` all resolve to **retired snapshots** that 404
  (`not_found_error`) on the `CLAUDE_CODE_OAUTH_TOKEN` account. `model: claude-sonnet-5`
  works (~$0.11/run). Haiku alias resolved to the dead `claude-3-5-haiku-20241022`; if you
  want cheaper, try the explicit `claude-haiku-4-5-20251001` (untested here).
- **Reuse the existing `secrets.CLAUDE_CODE_OAUTH_TOKEN`** (already used by `claude.yml` /
  `claude-code-review.yml`). No new secret, no Bedrock-OIDC needed.
- **Repo default workflow permission is `read`, but an explicit `permissions:` block DOES
  elevate** — the run log's "GITHUB_TOKEN Permissions" group confirmed `Contents: write` +
  `PullRequests: write` were granted. So push-back to a feature branch works.
- **`gh pr create` on `main`** additionally needs the org toggle "Allow GitHub Actions to
  create and approve pull requests" (repo currently `can_approve_pull_request_reviews:false`)
  — only matters for the main-branch PR path, not feature-branch direct push.
- **Loop guards (3):** `paths-ignore: docs/vault/**` + push-back via `GITHUB_TOKEN` (never
  re-triggers workflows) + job `if:` skipping the `cumpli-vault-bot` author. Do NOT guard on
  a commit-**message** substring — it skips any commit that merely mentions the marker.

Verify runs via the GitHub API with `curl -k` (see the proxy note in
[[cumpli-local-toolchain]]); `gh` fails cert verification through the TLS proxy.
