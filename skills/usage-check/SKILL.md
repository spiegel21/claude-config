---
name: usage-check
description: >-
  Analyze Claude Code session transcripts on this machine to find what is actually
  driving token cost — per-session totals, the worst-offender sessions, tool-call
  and shell-habit patterns, compaction counts — and report specific, data-backed
  fixes instead of generic advice. Use when the user asks to "check my usage",
  "analyze my token usage", "why am I burning tokens", "usage check", "am I
  working efficiently", or wants a periodic review of how their sessions spend.
---

# /usage-check — data-backed session-usage audit

Answer from the transcripts, not from theory. Every claim in the report must trace
to a number you computed. Transcripts live in `~/.claude/projects/<project-key>/*.jsonl`
(one file per session; the key encodes the repo path).

## Procedure

1. **Scope.** Default to the current project's key; if the user says "everything",
   sweep all keys under `~/.claude/projects/`. List files with sizes first — size
   alone usually identifies the outliers.

2. **Per-session token totals.** For each `.jsonl`, sum the `usage` objects
   (fields: `output_tokens`, `cache_creation_input_tokens`,
   `cache_read_input_tokens`, `input_tokens`) with a python3 heredoc — each line is
   a JSON object; usage sits at `.message.usage` or `.usage`; skip unparseable
   lines. Sort descending by cache-read: **cache-read volume is the compounding
   cost signal**, because every turn re-sends the whole accumulated context, so
   session cost is superlinear in session length.

3. **Autopsy the worst 1–2 sessions.** For each:
   - Tool-call frequency: count `"name":"..."` occurrences of tool_use blocks.
   - Shell habits: first verb of every Bash command (`cd`, `grep`, `cat`, `ls`
     counts reveal recon done inline instead of delegated).
   - Compaction count (`grep -c isCompactSummary`) and wall-clock span
     (first/last `timestamp`).

4. **Diagnose against the known anti-patterns**, citing the numbers:
   - **Mega-session** — one session spanning days / compacted many times → should
     have been several `/clear`-separated sessions seeded from notes files.
   - **Inline recon** — high `grep`/`cat`/`ls`/`cd` Bash counts vs low Agent
     counts → sweeps belong in scout/Explore subagents; reads belong in
     Grep/Read/Glob tools.
   - **Flat model routing** — mechanical work (verify loops, spec'd edits) run on
     the top-tier session model instead of haiku/sonnet subagents.
   - **Compaction as a habit** — repeated `/compact` instead of externalizing
     state and starting fresh.

5. **Report** (keep it tight):
   - A per-session table: output / cache-write / cache-read tokens, flagging
     outliers with % of total.
   - For each worst session: 2–3 lines of what it did wrong, with counts.
   - Ranked fixes, most-impactful first, each tied to a number from the data.
   - One closing line naming **the single biggest lever** right now.

## Notes

- Cache reads bill at ~10% of input price; they dominate through *volume*, not
  rate. Two 500-message sessions are much cheaper than one 1000-message session.
- Don't dump raw transcript lines into context — compute aggregates in python3 /
  shell and report only the numbers. For very large sweeps, delegate the
  computation to a scout and keep only its summary.
- If the data shows a habit already fixed in the user's CLAUDE.md defaults, say
  "already addressed — verify it's holding" rather than re-recommending it.
