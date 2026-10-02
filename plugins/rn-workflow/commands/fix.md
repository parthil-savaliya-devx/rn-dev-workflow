---
description: 'Bugfix workflow — repro-first, minimal fix, regression test, PR. No feature ceremony.'
---

You are fixing a bug. Follow these steps strictly — do not skip, do not add planning documents. Project commands: `yarn lint --max-warnings=0`, `yarn typecheck`, `yarn test`, `yarn check:env` (read `package.json` if this project's scripts differ).

## 1. REPRODUCE (mandatory — before touching any product code)

- Write a **failing** unit/component test that captures the wrong behaviour, in `__tests__/` mirroring `src/`. The failing test IS the spec. Mock at the boundary (`@/services` / native), never internal modules.
- If it isn't test-reproducible (purely visual/native): drive the real app with the `verify`/`run` skill (`yarn ios:dev` / `yarn android:dev`) and screenshot the wrong state.
- If you **cannot** reproduce: STOP. Report what you tried and observed. Never "fix" an unproven bug.

## 2. INVESTIGATE

- Check your persistent memory + recalled `<system-reminder>` context for a matching prior fix/gotcha before diagnosing — and the silent-failure index (`CLAUDE.md` → Traps, tech-dna §29): many "it just doesn't work" bugs are a known trap.
- State the root cause in one paragraph: `file:line`, why it happens, and blast radius (what else this code touches). If a `graphify-out/` graph exists, prefer `graphify query`/`graphify path` over broad grep to map the blast radius.
- If the hypothesis is uncertain — or the **expected** behaviour itself is unclear — STOP and ask the user (one batched round). Implement only after they confirm, and exactly per the clarification. Never guess and fix.

## 3. FIX (minimal diff)

- Make the smallest change that turns the repro test green. Do **not** refactor surrounding code.
- Any code you write follows `docs/tech-dna.md` (styling, naming, testIDs, the data pipeline, the Forbidden list). A fix is never an excuse for off-pattern code.
- The repro test stays in the suite permanently.
- **Sibling sweep:** grep/`graphify` for the same defective pattern elsewhere. Fix trivial siblings in this PR; report non-trivial ones.

## 4. VERIFY (scaled to blast radius)

- `yarn lint --max-warnings=0 && yarn typecheck && yarn test` must be green (add `yarn check:env` if `.env.*` changed).
- Visual bug → re-screenshot the fixed state via the `verify` skill (layout/inset bugs: on both gesture and 3-button navigation); compare against the Figma node values (tech-dna — Figma → UI) or the prior look. Save before/after.
- **e2e is NOT part of the mandatory fix check** and never auto-runs. Only if a spec already covers the affected screen, **ASK** the user whether to re-run just that one spec (default **No**, that spec only — never the whole suite). Never block on it.
- If the bug touched a data path, exercise it once against the mock (`USE_MOCK`) to confirm the mapper/schema still validates.

## 5. SHIP

- If a decision/pattern changed as part of the fix, update `docs/` in the same change set (tech-dna — Documentation) — an ADR for a reversed decision, a `docs/tech-dna.md` addition for a new pattern, a `CLAUDE.md` → Traps line for a new silent failure.
- **Present before committing** (tech-dna — Human verification precedes every commit): the root-cause paragraph, the uncommitted diff, the repro test (red → green), evidence (before/after screenshots for visual bugs) and the sibling-sweep result. **Wait for explicit approval**; fold requested changes into the same uncommitted set and present again.
- On approval, commit (conventional commit). Push and open the PR only when asked. PR body: **why** (the user-visible problem) and the root-cause paragraph, repro test name, evidence, sibling-sweep result. End with the repo's required trailer (see `CLAUDE.md`).

## 6. COMPOUND

- Non-obvious root cause → save to persistent memory so it's never rediscovered.
- Recurring or easy-to-repeat mistake → propose a **hookify** rule (`/hookify`) to prevent the class mechanically.

**Hard rules:** no product-code edits before a repro exists · anything unclear (expected behaviour, root cause, scope) → ASK the human first and implement only after — and exactly per — their clarification · no plan/spec files for a fix · the repro test is never deleted · minimal diff, no drive-by refactors · no commit before the human approves the fix · evidence in the PR or it didn't happen.
