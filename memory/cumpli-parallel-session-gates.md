---
name: cumpli-parallel-session-gates
description: "Running cumpli verify gates/e2e when parallel sessions occupy ports — own vite via E2E_BASE_URL, throwaway DB on Postgres.app 5433"
metadata: 
  node_type: memory
  type: project
  originSessionId: cfabaf21-d6fa-47e9-b299-bd2f3133d288
---

With multiple Claude sessions on cumpli worktrees, the /verify + e2e gates collide with other sessions' servers. As of 2026-07: main `~/cumpli` checkout holds vite on 5173, `cumpli-reachout` holds 5174 and the Postgres.app `cumpli` db on 5433. Never kill those processes.

**Why:** Playwright's config reuses an existing server on its port (`reuseExistingServer`), so a stale/foreign vite silently makes ~26 e2e tests time out — it looks like real failures.

**How to apply:**
- E2e from a worktree: boot your own vite on a free port (`VITE_DEMO=true node node_modules/vite/bin/vite.js --port <free> --strictPort`) and run `./node_modules/.bin/playwright test` with `E2E_BASE_URL=http://localhost:<free>` (that env skips the webServer block). Don't feed `.bin/playwright` to `node` — it's a shell script.
- Integration tests when Docker daemon is dead: create a throwaway db on the Postgres.app instance (`psql -p 5433 -c "CREATE DATABASE <name>"`) and run with `TEST_DATABASE_URL=postgres://espiegel@localhost:5433/<name>`; drop it after. Never point tests at another session's db.
- Infra tests locally fail with FailedToBundleAsset exit 254 (nested bare pnpm) UNLESS run via `pnpm -r test` with the PATH shim from [[cumpli-local-toolchain]] — then CDK bundling actually runs and real bundling errors surface.
