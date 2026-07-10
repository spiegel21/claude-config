---
name: background-orchestrator-ci-watch
description: "Background orchestrator subagents stall on phantom \"watchers\"; drive CI-watch from main via /loop and dispatch fresh executors per fix"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5df92a05-a776-403a-9381-918af9ba4e87
---

When a long-running background orchestrator subagent (spawned via the Agent tool, e.g. a Fable-model general-purpose agent) is asked to "push, then watch CI to completion and land the PR," it repeatedly **stops early and defers to a non-existent "watcher"** it claims is armed — it has no live children, so nothing wakes it, and CI never actually gets watched. It also silently skipped the force-push after a clean local rebase once.

**Why:** background agents can't reliably hold a multi-minute wait-and-poll loop; their "I'll wait for the watcher" is a hallucinated hand-off, not a real monitor.

**How to apply:** Don't rely on a background agent to watch CI or land a PR. Instead: (1) drive the CI-watch from the **main session** with `/loop 5m` checking `gh pr view/checks` (matches [[ci-wait-use-loop]]); (2) when a check fails, dispatch a **fresh Sonnet executor** with the exact failure + a tight spec rather than resuming the flaky orchestrator; (3) verify ground truth yourself with `gh`/`git` (head SHA, mergeStateStatus) rather than trusting the agent's status text. Use the orchestrator agent for the *build*, not for the *watch-and-land*.
