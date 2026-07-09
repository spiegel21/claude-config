# Memory index

- [CI waits → /loop 5m auto-merge](ci-wait-use-loop.md) — when waiting on CI, run /loop every 5 min to check and merge, not a background poll
- [cumpli local toolchain](cumpli-local-toolchain.md) — running gates on this Mac: use `corepack pnpm@9.15.0` + PATH shim (node 21 vs global pnpm); `curl -kL` for sanctions lists (TLS proxy)
- [cumpli auto-merge scope](cumpli-automerge-scope.md) — auto-merge handled by repo's own GitHub Actions (auto-merge.yml, verify+e2e gated); don't build a redundant local cron
- [cumpli local real backend](cumpli-local-real-backend.md) — run real validation API locally (no AWS): dev-server.ts + Postgres.app + dev-auth; 6/12 validations really work free
- [Ship GIFs to Slack](ship-gifs-to-slack.md) — post demo GIF to backend/UI Slack channel whenever a feature ships; no Slack integration connected yet
- [Commit means full process](commit-means-full-process.md) — "commit"/"merge" = go all the way through push, don't stop to ask
- [cumpli Obsidian vault](cumpli-obsidian-vault.md) — navigate cumpli via docs/vault/Home.md (cross-linked graph); Obsidian installed; slack/ seeded for future ingestion
- [cumpli vault-sync workflow](cumpli-vault-sync-workflow.md) — cloud GitHub Action auto-syncs the vault on push (all clones); Claude-in-CI gotchas: base-action not claude-code-action, pin claude-sonnet-5
