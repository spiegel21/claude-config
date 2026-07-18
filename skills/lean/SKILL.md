---
name: lean
description: >-
  Token-discipline operating mode for a session — keep the main context small so cost
  stops compounding. Adopt these habits for the rest of the session: delegate all recon
  to throwaway subagents, use the dedicated file tools instead of shell, run tools on
  absolute paths, route mechanical work to cheaper models, and start fresh instead of
  endlessly compacting. Use when the user says "/lean", "run lean", "keep this cheap",
  "minimize tokens", "do more with less", "be token-efficient", "stop burning context",
  or at the start of any task where the user wants disciplined, low-token execution.
---

# /lean — run this session on a token budget

Cost in a session is **superlinear**: every turn re-sends the whole accumulated context,
so a context that grows unchecked gets re-read hundreds of times. The single lever that
matters is **keeping the main context small**. Everything below serves that one goal.

Adopt these rules for the **rest of the session**, not just the next action. Announce
briefly that lean mode is on, then operate this way silently — don't narrate each rule.

## The rules, in priority order

**1. Delegate recon — never explore in the main context.**
Any time answering means sweeping files (grep/find/ls across the tree, reading long files,
scanning logs or command output), spawn a **scout** (haiku) or **Explore** subagent and get
back *conclusions + `file:line` pointers*, not raw dumps. The subagent's bloated context is
thrown away; yours stays lean. Spawn several in parallel for independent questions. Only skip
delegation for a genuine single-fact lookup you can resolve in one or two tool calls.

**2. Use the dedicated tools, not shell, for reading.**
`grep` → **Grep**. `cat`/`head`/`tail` → **Read**. `ls`/`find` → **Glob**. These are more
token-efficient and don't inject shell noise into context. Reserve **Bash** for things that
actually run (builds, tests, git, package managers) — not for reading files.

**3. Absolute paths, no `cd`.**
Run every tool against an absolute path. `cd` inside a compound command can trigger a
permission prompt (breaking auto-flow) and wastes turns. Never `cd`-then-read.

**4. Route by model — orchestrate high, execute low.**
Keep the main (expensive) context for decisions and synthesis. Push mechanical work down:
`scout`/`verifier` (haiku) for recon and running gates, `executor` (sonnet) for a change
you've already specified precisely. Reserve the top-tier model for judgment, not typing.

**5. Front-load the map instead of discovering it.**
If the repo has a knowledge index (an Obsidian vault, an `ARCHITECTURE`/`CLAUDE.md`, a docs
map), read *that* and follow its pointers to exact files — one cheap read replaces a dozen
exploratory greps that would each land permanently in context. In cumpli, that's
`docs/vault/Home.md`.

**6. Parallelize independent calls.**
Batch independent tool calls into one message so they run concurrently — fewer round-trips,
less accumulated overhead.

**7. Externalize state, then start fresh — don't ride a bloated context.**
For long tasks, write the plan and ground-truth facts to a notes file or the memory dir *as
you go*. When context gets heavy, prefer a **fresh session seeded from that file** over a
repeated `/compact` — it's higher-fidelity *and* resets the re-read cost to zero. Compaction
is lossy; use it rarely and deliberately, never as a routine.

## Anti-patterns this mode exists to kill

- A single session left open across many unrelated tasks (cost compounds every turn).
- `grep`/`ls`/`cat`/`tail` run inline in the main context instead of delegated or tooled.
- Dozens of `cd` calls and relative-path shell reads.
- Running the top-tier model for pure mechanical work.
- Compacting over and over instead of `/clear`-ing and starting fresh when a task is done.

## What "done with lean mode" looks like

You finished the task while the main context stayed lean: recon went to subagents, reads went
through Grep/Read/Glob, mechanical work went to cheaper models, and no exploratory dump
accumulated in the main thread. When the task is complete, remind the user that `/clear`
before the next unrelated task is the cheapest optimization available.
