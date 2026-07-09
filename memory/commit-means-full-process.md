---
name: ""
metadata: 
  node_type: memory
  originSessionId: 1a6a17b4-ddc0-4264-9b12-4c40601cda00
---

When the user asks to "commit" or "merge" something, that means carry out the whole
process to completion — not just `git commit` in isolation. For a commit on a repo with
a remote, that includes pushing (`git push`) unless the user says otherwise. For a merge,
that includes whatever follow-through steps normally complete a merge (e.g. pushing,
cleaning up the branch) unless told to stop partway.

**Why:** User corrected this after I committed changes to `~/claude-config` and then
paused to ask whether to also push, instead of just doing it.

**How to apply:** When a request uses the word "commit" or "merge", default to completing
the full local→remote flow (commit → push, or merge → push/cleanup) without a separate
confirmation step for the push itself. Still pause first for genuinely separate risky
actions (e.g. force-push, deleting branches) per normal safety judgment — this only
covers the ordinary "finish what commit/merge implies" case.
