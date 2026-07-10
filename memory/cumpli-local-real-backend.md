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

**Real-data intake works via the actual audited API, not a raw insert (2026-07-10):** `POST /api/v1/expedientes` with header `x-dev-sub: demo-sub-ana-robles`. Required fields only: `persona`(natural|legal), `nombre`, `docId`, `sector`, `kind`; optional `dateOfBirth` (ISO) feeds the identity/registry lookup. To make the local demo show *only* real records, seed for login rows then `TRUNCATE expedientes, alerts CASCADE;` (cascades to ~14 dependent tables) — keeps tenant/users/roles so dev-auth still logs in.

**Parallel-session collision hazard (bit us 2026-07-10):** a second worktree `~/cumpli-demo-flows` shares the SAME Postgres cluster (:5433), the SAME db `cumpli`, AND port :8787. Its boot ran `pnpm seed` (which clears+reinserts the 7 mock expedientes) and **wiped a real record I'd inserted into `cumpli`**. Two checkouts, one DB+port = clobber war — exactly the shared-resource hazard. Fix that survives: give the real-data demo its **own db + port**: `createdb -h /tmp -p 5433 -U espiegel -O cumpli cumpli_real`, run API with `DATABASE_URL=…/cumpli_real DEV_API_PORT=8788`, and the web with `VITE_DEV_API_PORT=8788` (I made `vite.config.ts`'s proxy target read `process.env.VITE_DEV_API_PORT ?? 8787` — keep that as a **local uncommitted** dev tweak). Isolated stack = db `cumpli_real` / API :8788 / web :5173; the other session's seed only touches `cumpli`, so it can't clobber it.
