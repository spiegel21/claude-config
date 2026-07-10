---
name: cumpli-intake-e2e-specs
description: "Changing cumpli's intake/registration wizard breaks e2e specs that walk registration as setup; run the FULL web e2e suite"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5df92a05-a776-403a-9381-918af9ba4e87
---

In cumpli, several Playwright e2e specs **walk the "register a client" wizard (`/expedientes/nuevo`) as a setup precondition**, not just the registration spec itself. Known walkers: `packages/web/e2e/validations.spec.ts` (its `registerAndOpen(...)` helper) and `packages/web/e2e/intake-scan.spec.ts`. So any redesign of `packages/web/src/pages/ExpedienteNuevo.tsx` (step order, grouped screens, field selectors, auto-advance vs explicit Continuar) can silently break these downstream specs even when the registration spec passes.

**How to apply:** After touching the intake wizard, run the **full** web e2e suite — `corepack pnpm@9.15.0 e2e` from `packages/web` (66 passed / 1 env-gated skip is the current baseline) — never just one spec; CI runs all of them and will catch a missed helper (e.g. a bare `getByRole('textbox')` that goes ambiguous, or a required grouped field left unfilled so `Continuar` stays disabled → 30s timeout). Fix the helpers to unambiguous per-field locators mirroring a spec that already passes on the new flow. See [[cumpli-local-toolchain]] for the pnpm shim.
