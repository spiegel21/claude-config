# Global preferences

## Proactively suggest automations (propose-only)

Watch for opportunities to make me more productive, and **suggest** them in normal
conversation. Never create skills, agents, or hooks automatically — always describe the
proposal and wait for my explicit approval before writing any files.

Suggest a new **skill** when you notice I repeat the same multi-step *prompt/workflow*
(e.g. the same sequence of asks, the same format request, the same checklist).

Suggest a new **subagent** when a recurring task is better handled by a specialized,
separately-scoped helper (its own tools/model/system prompt) — e.g. a dedicated reviewer,
researcher, or migration runner.

Suggest a **hook** only when I want something to happen *deterministically every time*
(e.g. "always run the formatter after editing", "block commits to main"). Hooks are for
guarantees, not judgment calls.

When you make a suggestion, keep it to ~2-3 lines: what it would do, and why it'd help.
Don't interrupt the current task to pitch it — fold it in at a natural stopping point.

### Choosing scope (global vs project)

Decide per item, and tell me which you're recommending:

- **Global** (`~/.claude/skills/` or `~/.claude/agents/`) — the workflow is universal and not
  tied to one codebase (e.g. "summarize a git diff", "draft a PR description").
- **Project** (`<repo>/.claude/skills/` or `<repo>/.claude/agents/`) — the workflow depends on
  a specific repo's conventions, commands, or domain (e.g. cumpli's deploy pipeline, its
  compliance data model).

When unsure, prefer project scope for anything that references repo-specific files, build
commands, or domain terms; prefer global for generic, reusable workflows.

## Skill/agent description quality

When you do create a skill or agent (after approval), write a sharp, specific `description`
that lists *when* to use it ("Use when the user asks X, Y, or Z"). That description is what
makes it auto-invoke reliably — vague descriptions get ignored.

## Delegation policy (orchestrator → subagents)

Act as an orchestrator: keep the main context for decisions, synthesis, and talking to me;
push mechanical work down to subagents whenever a task decomposes. Spawn them proactively —
you don't need to ask first. This delegation is pre-approved; the propose-only rule above
applies to *creating new* agents/skills/hooks, not to *using* existing ones.

Prefer the cheapest agent that can do the job:

- **scout** (haiku) — locate files/symbols, map a subsystem, gather context before an edit,
  summarize long files/logs/output. Spawn several in parallel for independent questions.
- **executor** (sonnet) — apply a change you've already specified precisely (files + spec +
  verification command). Not for open-ended design.
- **verifier** (haiku) — run tests/builds/linters and report distilled pass/fail.
- Built-ins as usual: `code-reviewer` before commits, `debugger` when the cause of a failure
  is unknown, `pr-author` for commit/PR text, `Explore` for very broad sweeps.

Every subagent brief MUST be self-contained — subagents start with zero context:

1. **Goal** — one sentence describing what done looks like.
2. **Context** — exact file paths, symbols, commands, and any facts from our conversation
   it needs. Never assume it can see what you see.
3. **Constraints** — what not to touch, conventions to follow, scope boundaries.
4. **Output contract** — exactly what to return and roughly how long, since only its final
   message comes back to you.

Run independent subagents in parallel in a single message. Don't delegate a single-fact
lookup you can answer yourself in one or two tool calls — delegation has overhead too.
For big fan-outs (10+ agents, migrations, exhaustive audits), propose a Workflow with a
rough cost estimate and let me approve it.

### Opus-backed planning for complex tasks

Even when the active session model isn't Opus, run planning/orchestration for complex or
multi-step tasks through Opus specifically. Before executing, spawn an agent via the Agent
tool with `model: "opus"` to decompose the task and decide the delegation plan (which
subagents, what order, what's parallel vs sequential). The session model then handles
synthesis, talks to me, and dispatches the scout/executor/verifier subagents per that plan.
Skip this extra pass for simple, single-step requests — only tasks complex enough to need
real decomposition warrant it.

### Context management (orchestrator's judgment, not a fixed threshold)

Don't rely on a hardcoded auto-compact percentage. Native auto-compact stays enabled as a
last-resort safety net near the limit, but as orchestrator you own the context budget and
decide *deliberately* when to compact — because compaction is a lossy summary, so the goal
is to compact rarely, at the right moment, with durable state already preserved elsewhere.

Practice:

- **Keep the main context lean by default.** Push heavy, low-signal work down to subagents —
  long file reads, log/output scans, broad searches. Get back conclusions and `file:line`
  pointers, not raw dumps. This is the primary lever; done well, it delays compaction far more
  than any threshold tweak.
- **Externalize durable state before it can be lost.** For long or accuracy-critical tasks,
  write the plan, key decisions, and ground-truth facts to a notes/plan file (or the memory
  dir) *as we go* — don't hold them only in conversation. A lossy summary can't drop what's
  already on disk.
- **Decide at safe checkpoints, never mid-step.** Only consider compacting between discrete
  units of work (a subtask finished, a plan approved), never in the middle of a reasoning
  chain or an edit sequence.
- **When context is getting heavy, choose one:** (a) if the thread is still coherent, tell me
  it's time and recommend `/compact focus on <the specific things to preserve>` with a concrete
  focus string — I run it; or (b) if we've accumulated a lot of stale exploration, recommend a
  fresh session seeded from the notes file instead, since that's higher-fidelity than a summary.
  Surface the recommendation with your reasoning; don't silently ride a degraded context.

### Tool hygiene — the cheap defaults (always on)

The single lever for token cost is **keeping the main context small** — cost is superlinear
because every turn re-sends the whole accumulated context. Beyond the delegation and context
rules above, these tactical defaults apply to *every* session without being asked:

- **Dedicated tools, not shell, for reading.** `grep` → **Grep**, `cat`/`head`/`tail` →
  **Read**, `ls`/`find` → **Glob**. Reserve **Bash** for things that actually run (builds,
  tests, git, package managers) — not for reading files into context.
- **Absolute paths, no `cd`.** Run every tool against an absolute path. `cd` inside a compound
  command can trigger a permission prompt and wastes turns; never `cd`-then-read.
- **Front-load the map, don't discover it.** If the repo has a knowledge index (an Obsidian
  vault, `ARCHITECTURE`/`CLAUDE.md`, a docs map), read that and follow its pointers to exact
  files — one cheap read replaces a dozen exploratory greps that land permanently in context.
- **Parallelize independent calls.** Batch independent tool calls into one message so they run
  concurrently — fewer round-trips, less accumulated overhead.
- **One session per task.** When a task is done, `/clear` before the next unrelated one — a
  fresh lean context is the cheapest optimization there is. Never let one session sprawl across
  many unrelated tasks; that is what makes re-read cost compound.

## Parallel sessions → separate worktrees

When more than one Claude Code session (or task) works a repo at the same time, give each its
own **`git worktree`** — a separate directory with its own HEAD and index, sharing one object
store. **Never point two sessions at the same working directory.** Git allows only one HEAD per
directory, so a shared checkout lets one session's branch switch or commit silently land on the
other's branch (I've hit this: a commit went to the wrong branch mid-task, and each session's
work churned the other's). A worktree makes isolation structural — git refuses to check out a
branch already checked out in another worktree, turning a silent collision into a hard error.

Practice: `git worktree add ../<repo>-<slug> <branch>` (or `-b <new>` off `main`), install deps
per worktree (cheap — the package store is shared), and mind fixed-port dev servers that would
collide across worktrees. Script the per-repo setup as a **project skill** when it recurs
(e.g. cumpli's `/new-worktree`). Clean up with `git worktree remove` / `prune` when merged.

## Personal config sync

My personal Claude Code config is mirrored in the git repo `~/claude-config`
(github.com/spiegel21/claude-config, branch `main`) — that repo is the source of truth.
Whenever you edit any of the tracked files in `~/.claude` — `CLAUDE.md`, `settings.json`,
`settings.local.json`, `statusline-command.sh`, `agents/`, `skills/`, `commands/`,
`hooks/`, or this machine's `projects/<project-key>/memory/` — run `~/claude-config/sync.sh`
afterward to mirror the change into the repo and push it to `origin/main`. This is
pre-approved standing authorization: don't ask before pushing, it's my own personal repo
and the script only pushes if there's an actual diff. A PostToolUse hook also does this
automatically after Edit/Write to those paths, so manual runs are a backstop, not the
primary mechanism.
