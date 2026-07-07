---
name: propose-automations
description: Review the user's recent Claude Code sessions to find repeated workflows and PROPOSE (never auto-create) new skills, subagents, or hooks that would save time. Use when the user asks to "review my usage", "what should I automate", "propose new skills/agents", "find automation opportunities", or runs a weekly usage review.
disable-model-invocation: false
---

# Propose automations from recent usage

Your job: analyze the user's recent Claude Code activity, identify repeated or
time-consuming patterns, and **propose** new skills / subagents / hooks. You must NOT
create any files — this is propose-only. The user approves, then (in a later step) you build
what they pick.

## Inputs

- Default window: the **last 7 days** of sessions. If the user gives a different window
  (e.g. "last 2 weeks", "today"), use that.
- Transcripts live in `~/.claude/projects/<slug>/*.jsonl` — one JSONL file per session.
  Each project the user works in has its own `<slug>` directory.
- Existing skills: `~/.claude/skills/` (global) and any `<repo>/.claude/skills/`.
- Existing agents: `~/.claude/agents/` (global) and any `<repo>/.claude/agents/`.

## Steps

1. **Find recent sessions.** List `*.jsonl` files across `~/.claude/projects/*/` modified
   within the window (use `find ~/.claude/projects -name '*.jsonl' -mtime -7`). Pick the most
   active ones; don't try to read everything if there are many — sample the largest/recent.

2. **Extract user intents.** From each transcript, pull the user's prompts (role: "user"
   messages). You only need the asks, not full assistant output. Look for:
   - The same kind of request repeated across sessions (same format, same checklist, same
     multi-step sequence).
   - Tasks that took many tool calls / back-and-forth that a packaged skill could shortcut.
   - Recurring corrections the user gives (candidates for a hook or a memory, not a skill).

3. **Check what already exists.** Read the names + descriptions of current skills and agents
   so you don't propose duplicates. If an existing one *almost* fits, propose improving its
   description instead of a new artifact.

4. **Classify each opportunity:**
   - **Skill** — a repeated prompt/workflow (most common).
   - **Subagent** — a recurring task better handled by a specialized helper with its own
     tools/model/system prompt.
   - **Hook** — something that should happen deterministically *every time* (formatting,
     guardrails). Not for judgment calls.

5. **Decide scope** for each: global (`~/.claude/...`) if universal, or project
   (`<repo>/.claude/...`) if it depends on a specific repo's conventions/commands/domain.

## Output

Present a short ranked table, highest-impact first:

| # | Type | Proposed name | Scope | What it does | Evidence (how often seen) |
|---|------|---------------|-------|--------------|---------------------------|

Then for the top 1-3, show the exact `description` line you'd write (since that drives
auto-invocation). End by asking which ones to build. **Do not write any files until the user
picks.** Cap the list at ~5 proposals; if you dropped weaker candidates, say so.
