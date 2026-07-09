---
name: cumpli-local-toolchain
description: "Running cumpli's gates locally on this Mac — pnpm/node version mismatch + TLS proxy workarounds"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 874268ba-dd33-4f22-9553-080c4c5261e5
---

On this Mac the active Node is v21.7.3 but the globally-installed `pnpm` requires
Node ≥22.13, so a bare `pnpm` aborts. cumpli pins `pnpm@9.15.0` (works on Node 21),
so run gates via **`corepack pnpm@9.15.0 …`**.

Gotcha: the root scripts (`typecheck`, `test`, `build`) and CDK asset bundling call
**bare `pnpm`** internally, which re-hits the too-new global pnpm and fails
(`infra` audit-iam test "FailedToBundleAsset" is this, not a code bug). Fix: put a
shim on PATH so nested calls resolve to 9.15.0:

```sh
printf '#!/bin/sh\nexec corepack pnpm@9.15.0 "$@"\n' > /tmp/shim/pnpm; chmod +x /tmp/shim/pnpm
PATH=/tmp/shim:$PATH corepack pnpm@9.15.0 -r test   # then `… build`
```

Run order that works: `corepack pnpm@9.15.0 install --frozen-lockfile` → build
`@cumpli/shared` first → lint/typecheck/test/build. `tsx`/`vitest` live in
`packages/api/node_modules/.bin`, not the workspace root. tsx needs a unix socket
the command sandbox blocks (`listen EPERM`), so run scripts with the sandbox off.

Confirmed 2026-06-29: even with the shim on PATH, the **wrapper npm-scripts**
(`typecheck`, `build`) still escape to the global pnpm and abort. Reliable fix is
to skip the wrapper and run the leaf steps directly via corepack:
`corepack pnpm@9.15.0 --filter @cumpli/shared build` then
`corepack pnpm@9.15.0 -r --parallel typecheck`. For build, the root script's
`--filter '!@cumpli/electron'` matched **no projects** here — build each package
explicitly instead: shared → api → web → infra (then electron's `copy-web.cjs`).
A full local gate run (lint/typecheck/test/build) this way = green and matches CI;
`-r test` needs `docker compose up -d` (Postgres) and sandbox off (port bind).

Reaching the sanctions list endpoints (OFAC/UN/EU/UK) from here goes through a
TLS-intercepting proxy: plain `curl` fails (HTTP 000); use **`curl -kL`** (insecure
+ follow redirects — OFAC/UN 302 to presigned S3/Azure URLs). The production Lambda
`fetch` won't have this proxy. See [[ci-wait-use-loop]].

**git-over-https lies through this proxy (2026-07-08).** The same TLS proxy caches
git smart-HTTP `info/refs` GETs, so `git ls-remote`/`git fetch` can return a **stale**
branch SHA, and `git push` can falsely print **"Everything up-to-date"** (it trusted a
stale local `refs/remotes/origin/…` tracking ref + cached advert and skipped a real
push). Symptoms diverge per service (upload-pack vs receive-pack cached separately).
Reliable moves:
- **Verify remote truth via the GitHub API, not git:** `TOKEN=$(gh auth token)` then
  `curl -ksL -H "Authorization: Bearer $TOKEN" ".../git/ref/heads/<branch>?nc=$RANDOM"`
  (gh itself fails cert verify here — must be `curl -k`; add a random query param to
  bust cache). This is authoritative.
- **Force a real push when git thinks it's up-to-date:** reset the stale tracking ref
  to the API truth (`git update-ref refs/remotes/origin/<branch> <realSHA>`), then
  `git push -v origin HEAD:refs/heads/<branch>` — verbose shows the actual
  `POST git-receive-pack` + `a..b` line proving it transferred.
- Ignore the harmless `failed to store: 100001` (keychain write blocked by sandbox)
  and `.git/config: Operation not permitted` (`-u` config write) — non-fatal; the ref
  update is what matters. Push with the sandbox on works; `-u` is what trips it.
