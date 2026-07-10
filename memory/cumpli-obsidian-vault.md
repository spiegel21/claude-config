---
name: cumpli-obsidian-vault
description: cumpli has an Obsidian knowledge-graph vault at docs/vault (start at Home.md) — vault-first is enforced via CLAUDE.md + session-start hook; Slack context is active via /slack-ingest
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
- **Vault-first is now enforced (2026-07-09):** `cumpli/CLAUDE.md` has a hard "start at the vault
  first" directive with a per-task procedure, AND `.claude/hooks/session-start.sh` emits a vault +
  Slack pointer on **every** session (local + remote) — so agents are told to start here each time.
- Obsidian.app is installed on this Mac (brew cask); the vault is registered — `open -a Obsidian`.
- **Slack context is ACTIVE (no longer future work):** the **`/slack-ingest`** skill
  (`.claude/skills/slack-ingest/`) distills Slack threads into atomic, wikilinked notes under
  `docs/vault/slack/{decisions,threads,minutes}` + `people.md`. **Whole workspace already ingested
  (2026-07-09)** via a multi-agent workflow: 29 notes total (20 decisions, 5 threads, 3 minutes,
  people.md), deduped. Workspace = 7 public channels: `#all-cumpli` (main), `#minutes`, `#backend`,
  `#dev`, `#ui`, `#git` (bot PR digests), `#social`. Re-run `/slack-ingest` for new context. Note:
  user chose "distill everything as-is" (no redaction) since it's their own team workspace.
  See [[ship-gifs-to-slack]].
- Open thread from Slack: whether to layer **graphify** (`graphifyy` — AST→graph, GraphRAG/MCP,
  can export an Obsidian vault) on top of the hand-authored vault — Eduardo wasn't fully sold on
  the by-hand markdown approach.
- Config changes committed on branch `claude/vault-slack-config` (not pushed as of 2026-07-09).
