---
name: cumpli-local-real-backend
description: "How to run cumpli's real validation API locally with no AWS — dev-server, Postgres.app, dev-auth, which validations actually work"
metadata: 
  node_type: memory
  type: project
  originSessionId: ea99ca94-d4cb-4ede-bf84-b1ac2b04f117
---

Running the **real** cumpli backend locally (no AWS, no Cognito) to drive validations from the UI. Built 2026-07-03.

**Pieces added:**
- `packages/api/src/dev-server.ts` — dev-only Node HTTP server wrapping the same `createApp(deps)` as Lambda. Script: `corepack pnpm@9.15.0 --filter @cumpli/api dev` (tsx watch, port 8787). In-memory audit, `UnavailableCognito`, providers = sanctions/pep/adverseMedia/registry. Never imported by `lambda.ts`.
- **Dev-auth**: no JWT. Server reads `x-dev-sub` header (default `demo-sub-ana-robles` = compliance_manager) → looks up real tenant_id+roles from DB → injects as JWT claims. So authorize/audit/tenant-isolation are real.
- Web: `request()` in `packages/web/src/lib/api.ts` has a `VITE_DEV_AUTH=true` branch that skips Amplify and sends `x-dev-sub`. Config in `packages/web/.env.local` (`VITE_DEMO=false`, `VITE_API_BASE_URL=http://localhost:8787`, `VITE_DEV_AUTH=true`).
- UI: `packages/web/src/components/ValidationsPanel.tsx` runs each validation individually off `VALIDATION_CATALOG` + `listValidationRuns`; wired into `ExpedienteDetail`.

**Postgres**: Docker daemon wouldn't start in-sandbox, so used **Postgres.app binaries** instead: cluster at `~/.cumpli-localpg`, started with `pg_ctl -D ~/.cumpli-localpg -o "-p 5432 -k /tmp" start` (v15, trust on unix socket, md5 on TCP; role+db `cumpli`/`cumpli_local_only`). Matches the docker-compose `DATABASE_URL`. Then `pnpm migrate` + `pnpm seed`.

**Which validations actually run (no AWS, no account): 6 of 12.** Internal: document_completeness, document_expiry, risk_scoring (+ubo). Free live data: sanctions (OFAC/UN/EU/UK/Canada — real hits, needs `NODE_TLS_REJECT_UNAUTHORIZED=0` behind the TLS proxy), pep (Wikidata), adverse_media (GDELT — flaky/slow, sometimes honest `error`). **registry OpenCorporates now returns 401** (needs a token — no longer free). identity/credit/address/document_ocr need vendor accounts — UI gates them as "requiere proveedor externo".

**Everything (API + external fetch) must run un-sandboxed** — the command sandbox blocks Postgres TCP + external HTTPS + Postgres shmget.

Seed `demo-sub-ana-robles` etc. are fixed; demo tenant `00000000-0000-0000-0000-000000000099`. Added a designated-name case (Joaquín Guzmán Loera → real OFAC SDN hit → risk auto-escalates to alto). See [[cumpli-local-toolchain]], [[cumpli-automerge-scope]].
