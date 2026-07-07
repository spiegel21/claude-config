---
name: ship-gifs-to-slack
description: "When a feature ships (PR merged/ready), post the demo GIF to Slack — backend or UI channel — so the team sees it"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 58d8be0c-90b8-4917-b8bc-d4f32a652f9f
---

Eduardo wants every shipped feature announced on the team Slack with its demo GIF
(the E2E recordings we produce, e.g. `Desktop/cumpli client/intake-ocr-e2e.gif`).
Channel: either the backend channel or the UI channel — pick by the feature's
surface (UI-facing flow → UI channel), the point is that everyone gets updated.

**Why:** the GIFs already exist as E2E artifacts; posting them turns verification
output into team visibility for free.

**How to apply:** after a feature PR is shipped, post GIF + 2–3 line summary to
Slack. As of 2026-07-05 NO Slack integration was connected (no MCP tools, no CLI,
no webhook) — check for a Slack MCP server first and ask Eduardo to connect one
if missing. A `/ship-announce` skill in the cumpli repo was proposed but not yet
approved/created. See [[cumpli-automerge-scope]] for how PRs land.
