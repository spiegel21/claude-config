---
name: ""
metadata: 
  node_type: memory
  originSessionId: 1a6a17b4-ddc0-4264-9b12-4c40601cda00
---

When the user asks to "commit", "merge", or "push" something, that means carry out the
whole process to completion — not just the single git step in isolation. "commit" → also
push. **"push" → also open the PR** (branch push + `gh pr create`), not just `git push`.
"merge" → whatever follow-through completes it (push, branch cleanup). Don't stop partway
to ask for the next obvious step.

**Why:** User corrected this twice — first after I committed to `~/claude-config` and paused
to ask whether to push; then again (2026-07-09) after I pushed a branch and asked whether to
open the PR instead of just opening it. "push" = the whole publish flow through the PR.

**How to apply:** On "commit"/"merge"/"push", default to completing the full flow: commit →
push → open PR (draft title/body from the commits). On this Mac a TLS-intercepting proxy makes
`gh` fail cert verification in the sandbox — run the `gh pr create` call with the sandbox
disabled (works). `git push -u` may fail to write `.git/config` upstream tracking under the
sandbox, but the branch/commits still land on the remote — that error is cosmetic. Still pause
for genuinely separate risky actions (force-push, deleting branches) per normal safety judgment.
