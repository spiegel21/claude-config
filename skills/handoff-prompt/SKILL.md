---
name: handoff-prompt
description: >-
  Compose a self-contained execution prompt from the current session's plan — goal,
  verified ground truth with file paths, exact design, constraints, verification
  gates — for handoff to a fresh session or another agent. Use when the user says
  "make a prompt for this plan", "prepare a handoff", "I'll pass this to
  Fable/another session/another agent", or asks to paste a plan as a prompt.
---

# /handoff-prompt — package a plan for a fresh session

A fresh session knows nothing this conversation knows. The prompt must carry every
load-bearing fact — and only verified ones: a wrong "fact" in the ground-truth section
sends the executor confidently in the wrong direction.

## Before writing

1. **Verify every claim you're about to embed.** Re-check file paths, symbol names,
   function signatures, and "X already exists / is merged" statements against the
   current code — not against memory of this conversation. Drop or flag anything you
   can't confirm.
2. **Identify what the executor must NOT do** (scope boundaries, invariants, files to
   leave alone, decisions already made that it shouldn't re-litigate).

## Prompt structure (this shape has executed cleanly before)

```
# Task for <executor> — <one-line title>

<Repo + absolute path, toolchain one-liner. "Read <repo>/CLAUDE.md first" if it exists.>

## Goal
<2-4 sentences: the user-visible outcome and the proof required ("...and prove it
works against X").>

## Ground truth (already verified — build on it, don't re-litigate)
<Bulleted facts with exact file paths: what exists, what's missing, known constraints,
environment gotchas. Each bullet is something you re-verified in step 1.>

## Design (implement exactly this shape)
<Numbered, per-package/area: the decided approach. Specific enough that two competent
executors would produce interchangeable results.>

## Constraints
<Invariants, what not to touch, conventions (e.g. i18n locale, no new deps).>

## Definition of done
<The gates/commands that must pass, the end-to-end proof to run, what to include in
the final report.>
```

## Rules

- Absolute paths; never "the file we discussed".
- Include environment/machine quirks the executor will hit (sandbox, toolchain
  versions, proxies) — these cost the most time to rediscover.
- State decided trade-offs as decisions ("reuse action `expediente.create`"), with a
  one-clause why, so the executor doesn't reopen them.
- End the prompt with reporting expectations, not pleasantries.
- Deliver the prompt in a fenced block so the user can copy it verbatim; offer to
  also write it to a file (e.g. `docs/<task>-prompt.md`) if it's long.
