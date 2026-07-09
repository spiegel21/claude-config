---
name: cumpli-obsidian-vault
description: cumpli has an Obsidian knowledge-graph vault at docs/vault — start at Home.md to navigate the repo fast
metadata: 
  node_type: memory
  type: project
  originSessionId: 896bd5e4-7240-47b9-847e-2bc3877839fb
---

The cumpli repo has an **Obsidian vault at `cumpli/docs/vault/`** — a cross-linked knowledge
graph over the codebase, built 2026-07-08. **To navigate cumpli efficiently, read
`docs/vault/Home.md` first**, then follow the `[[wikilinks]]` to per-subsystem notes
(`packages-api`, `packages-web`, `packages-shared`, `infra`, `services-*`) and per-concept notes
(invariants I1–I8, multi-tenant isolation, RBAC, audit log, validations engine, third-party
integrations, tests T1–T5, verify loop). Each note is anchored to real file paths.

- The vault *points at* the code; when they disagree, **the code wins** — fix the note in the same change.
- `cumpli/CLAUDE.md` has a "Navigating the repo — the vault" section pointing here too.
- Obsidian.app is installed on this Mac (brew cask); the vault is registered — `open -a Obsidian`.
- **Future work:** `docs/vault/slack/` is seeded for Slack ingestion. The Slack MCP tools
  (`search_public`/`read_channel`/`read_thread`) are connected, so a `/slack-ingest` skill could
  distill threads into `decisions/` notes wikilinked to the subsystem they explain. See
  [[ship-gifs-to-slack]] for the other pending Slack integration.
