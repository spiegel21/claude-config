---
name: ""
metadata: 
  node_type: memory
  originSessionId: c2253966-2159-4f14-8e4a-7f604aae7c63
---

Design for letting cumpli users connect their own **Outlook / Microsoft 365** mailbox to send outreach email (customers are Microsoft shops, not Google). **Status: DEFERRED — no code was ever written; nothing is activated.** User flagged it as sensitive and asked to keep the plan on file, not build it yet. Resume only on explicit go-ahead.

**Target repo:** the `cumpli-reachout` **worktree** (`/Users/espiegel/cumpli-reachout`, gitdir → `cumpli/.git/worktrees/cumpli-reachout`) — the intended isolated home for outreach work. Outlook/Graph/OAuth email is **greenfield** (nothing exists). Mirror the existing provider pattern at `packages/api/src/notifications/` (see `whatsapp-cloud`, `factory`, `types`, `stubs`).

**Invariants that constrain it:** I1 (`tenant_id` non-null), I2 (tenant/roles from JWT only — sign `tenant_id` into OAuth `state`, don't trust it back raw), I3 (only `db/` imports pg), I4 (`authorize` mapping or 403), **I7 (no secrets in repo → OAuth client secret + refresh tokens go to Secrets Manager / KMS)**, I8 (exactly one audit event per write). UI strings es-PA only.

**Least-invasive auth decision (settled):** delegated Graph scope **`Mail.Send` + `offline_access` + `User.Read`** only — can send as the user, CANNOT read inbox/contacts/calendar/files. Get the Entra app **Publisher Verified** to kill the "unverified app" warning. Handle **admin-consent** tenants (one-time IT approval → colleagues connect prompt-free). Use **delegated**, never application, permissions. No SMTP/app-passwords (basic auth is dead).

**End-to-end onboarding flow:**
1. Employee opens "Integraciones → Conectar Outlook" (state: No conectado).
2. Web → `GET /api/v1/integrations/outlook/authorize-url`; API builds Microsoft authorize URL (scopes above, PKCE, signed `state` w/ tenant_id); browser redirects to Microsoft.
3. Consent: "cumpli — verified publisher wants to: Send mail as you." (admin-consent link path if tenant requires it).
4. Microsoft → `GET /api/v1/integrations/outlook/callback`; API validates state, exchanges code, stores refresh token encrypted (Secrets Manager/KMS), inserts `outlook_connections` row (tenant_id non-null), one audit event `integration.outlook.connected`.
5. UI: "Conectado como user@org.com · Desconectar".
6. Send (later): `OutlookProvider` in notifications/ mints access token from refresh token (cached/auto-refresh), Graph `POST /me/sendMail`, rate-limited/queued (Exchange ~30/min, ~10k/day), audit per send.
7. Lifecycle: disconnect = revoke+delete+audit; expired/revoked token → "Reconectar" state.

**Implementation fan-out (when resumed):** cumpli-shared (RBAC actions `integration.outlook.connect/.disconnect/.send`, Zod, es-PA, audit keys) · cumpli-infra (Entra secrets, token store) · cumpli-backend (authorize-url + callback handlers, token exchange/refresh, OutlookProvider, `outlook_connections` migration, audit) · cumpli-frontend (Integraciones page) · cumpli-tests/reviewer. Gate with `/verify`, new branch in the worktree.

**Two OPEN decisions the user must make before building:**
1. **Build vs buy** — direct on Graph + Secrets Manager (no subprocessor, best DPA fit for a compliance product) **vs** Nylas/Aurinko/Unipile (faster, but adds a paid subprocessor touching customer mail → DPA disclosure).
2. **First cut** — vertical slice (connect + status + one test send) vs full feature (queued/throttled bulk send).

Related outreach context: WhatsApp Business API path was also discussed (needs FB profile in good standing → Business Portfolio → Dev App → Business Verification → opt-in only). See [[ship-gifs-to-slack]] for the outreach/demo Slack habit.
