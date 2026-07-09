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

**How to apply:** as of 2026-07-08 this is being automated, not done by hand.
The premise of a "desktop-control" Slack poster was wrong — none existed in the
repo. Two real mechanisms:
- `.github/workflows/slack-notify.yml` — text-only per-merge ping via
  `SLACK_WEBHOOK_URL` (webhooks CANNOT attach files).
- `.github/workflows/demo-digest.yml` (**PR #184, draft, branch
  `feat/slack-demo-digest`**) — daily cloud cron that records a slowed
  Playwright walkthrough, converts to **MP4 + GIF** (`scripts/demo/convert.sh`,
  ffmpeg), and posts via **Slack bot token** (`scripts/demo/post-to-slack.mjs`,
  files.uploadV2) so the MP4 plays inline. Chose bot token over webhook+public
  bucket. Setup + tuning: `docs/demo-digest.md`.

Blocked on two repo secrets Eduardo must add once: `SLACK_BOT_TOKEN`
(scopes files:write, chat:write) + `SLACK_CHANNEL_ID`. Without them the workflow
still builds the media and archives it as an artifact, just skips posting.

Gotcha: the intake wizard can't be captured in demo mode anymore — it routes to
the real backend (port 8787). The demo tour uses in-memory smoke-tested screens
(Home → officer console → users). Also a Slack MCP connection is now available in
sessions but has no file-upload tool (post-only). See [[cumpli-automerge-scope]]
for how PRs land.
