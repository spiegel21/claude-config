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
