# Memory index

- [CI waits → /loop 5m auto-merge](ci-wait-use-loop.md) — when waiting on CI, run /loop every 5 min to check and merge, not a background poll
- [cumpli local toolchain](cumpli-local-toolchain.md) — running gates on this Mac: use `corepack pnpm@9.15.0` + PATH shim (node 21 vs global pnpm); `curl -kL` for sanctions lists (TLS proxy)
- [cumpli auto-merge scope](cumpli-automerge-scope.md) — auto-merge handled by repo's own GitHub Actions (auto-merge.yml, verify+e2e gated); don't build a redundant local cron
- [cumpli local real backend](cumpli-local-real-backend.md) — run real validation API locally (no AWS): dev-server.ts + Postgres.app + dev-auth; 6/12 validations really work free
- [Ship GIFs to Slack](ship-gifs-to-slack.md) — post demo GIF to backend/UI Slack channel whenever a feature ships; no Slack integration connected yet
- [Commit means full process](commit-means-full-process.md) — "commit"/"merge"/"push" = full flow (commit→push→open PR); don't stop to ask; disable sandbox for gh (TLS proxy)
- [cumpli Obsidian vault](cumpli-obsidian-vault.md) — navigate cumpli via docs/vault/Home.md; vault-first enforced (CLAUDE.md + session-start hook); Slack context active via /slack-ingest
- [cumpli vault-sync workflow](cumpli-vault-sync-workflow.md) — cloud GitHub Action auto-syncs the vault on push (all clones); Claude-in-CI gotchas: base-action not claude-code-action, pin claude-sonnet-5
- [Background orchestrator CI-watch](background-orchestrator-ci-watch.md) — background orchestrator agents stall on phantom "watchers"; drive CI-watch from main via /loop + dispatch fresh executors per fix
- [cumpli intake e2e specs](cumpli-intake-e2e-specs.md) — changing the intake wizard breaks e2e specs that walk registration (validations.spec/intake-scan); run the FULL web e2e suite
- [cumpli parallel-session gates](cumpli-parallel-session-gates.md) — verify/e2e with parallel sessions: own vite + E2E_BASE_URL (5173/5174 taken), throwaway test DB on Postgres.app 5433, infra tests need shimmed `pnpm -r test`
- [Connect Outlook outreach — DEFERRED](outlook-outreach-deferred.md) — full "connect your Outlook mailbox" email-outreach design captured but NOT built/activated (sensitive); build-vs-buy still open; target = cumpli-reachout worktree
