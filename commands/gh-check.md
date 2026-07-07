---
description: Check gh CLI auth status and say whether /web-setup will work
allowed-tools: Bash(gh auth status:*)
---

Here is the current GitHub CLI auth status:

!`gh auth status 2>&1`

Read the output above and tell me:
- Is there a valid, working token for github.com? (Look for an invalid/expired token warning.)
- Since `/web-setup` reads this local `gh` token, will `/web-setup` succeed right now or not?
- If the token is invalid, give the one command to fix it.

Be concise.
