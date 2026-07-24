---
description: 'Feature workflow — Plan → Build → QA & Verify → Ship → Compound, in one session.'
---

You are building a feature end-to-end in this session. Three human gates only: **plan approval (A)**, **QA-report skim (B)**, **PR review (C)**.

**Read first, every time:** `docs/tech-dna.md` (canonical patterns — all code copies these), `CLAUDE.md` (hard rules + subsystem map), and any relevant [ADRs](docs/decisions/README.md). Project commands are `yarn lint`, `yarn typecheck`, `yarn test`, `yarn check:env` — never hardcode others; if this project's scripts differ, read `package.json` and use those.

## PHASE 1 — PLAN (in-session)

1. Explore the codebase read-only: reusable components/hooks/services, navigation types, stores, existing mappers/schemas. If a `graphify-out/` graph exists, prefer `graphify query "<question>"` over raw grep. Identify what to reuse before proposing anything new.
2. **Design source (if the feature has Figma):** use the `figma-to-ui` skill — `get_metadata` to find each node, then `get_design_context` for **every** screen/state involved. Extract exact spacing, colours→theme tokens, typography, icon sizes, and record the **node id per state** now (fail fast, not at QA time). Screenshots are for comprehension only (tech-dna — Figma → UI).
3. **Contract:** if the feature needs backend data, get the per-screen contract (query/endpoint + sample response + types) up front. No data path is designed without it. Never invent a shape.
4. Ask **ALL** clarifying questions in **one batched round** (use a multi-question prompt). Build only per the answers — never guess (hard rule).
5. **Persist the plan** in this repo's established shape — two documents:
   - `docs/superpowers/plans/YYYY-MM-DD-<feature-kebab>.md` — the task-by-task build plan: goal, architecture one-liner, tech stack, **Global Constraints** (the tech-dna rules that bite this feature), then numbered tasks with checkbox (`- [ ]`) steps, each listing **Files** (create/modify/test) and **Interfaces** (what it consumes/exposes). Reference the spec doc. (Template: `docs/superpowers/plans/_template.md`.)
   - `docs/superpowers/specs/YYYY-MM-DD-<feature-kebab>-design.md` — the rebuild document (re-implementable from this file alone): `Date` / `Status` / `Figma` (file + node id per state) / `Scope`; a **Decisions (settled)** table of every clarification; EARS acceptance criteria (`WHEN <event> THE SYSTEM SHALL <behavior>`); extracted design values (exact px, radii, colours→token mapping, typography per element — survives Figma link rot); architecture (each file to create/modify + its responsibility); full behaviour spec (interactions, validation, navigation, edge cases); testID inventory; test list. (Template: `docs/superpowers/specs/_template.md`.)
6. ▸ **GATE A:** present the plan from the two docs (link them). Wait for approval. On approval — and at every later phase transition — update the plan's checkboxes and the spec's `Status`, editing in any deviations discovered while building (never leave the spec stale).

## PHASE 2 — BUILD

0. Pre-read `docs/tech-dna.md` AND your persistent memory (recalled `<system-reminder>` context + relevant `feedback`/`project` memories). All code follows the tech-DNA canonical patterns (data pipeline, sections, stores, styling, naming, testIDs). **A pattern with no tech-DNA precedent is designed at Gate A and added to `docs/tech-dna.md` in the same PR** (Evolving the DNA) — never improvised.
1. **Logic first, TDD** where there's logic (utils, hooks, stores, mappers, schemas): write the failing test in `__tests__/` mirroring `src/` → confirm red → implement → green. Mock at the boundary (`@/services`), leave real schema+mapper in place. Never modify a test to force green.
2. **Data path** (if any): query text in `src/graphql/queries/` → `fetch<X>` using the boundary fetcher with a `getConfig('USE_MOCK')` branch → Zod schema in `src/schemas/` → mapper firewall in `src/mappers/` (`type→fn` map, never `switch`) → view-model type → presentation component. Wire the hook via a shared query-options factory; add pull-to-refresh.
3. **UI:** theme tokens only (hex-only, `spacing.*`/`typography.*`, weight-by-family, `BaseText`). Build each screen/state, then converge visually against the Figma node values — never reverse-engineer measurements after the fact.
4. **Add a `testID`** to every interactive and landmark element **as you build** — QA and any future e2e depend on them.
5. **Persisted store?** `skipHydration:true` + a `rehydrate()` line in `App.tsx`'s `Promise.all` (footgun — tech-dna — State).
6. Checkpoint commit per task/slice (conventional commits; do NOT push). Do not enter Phase 3 with red tests or missing testIDs.

## PHASE 3 — QA & VERIFY (feature-scoped — never a full-app pass)

Scope = exactly what Phase 2 built: its screens, states, components, and the nav paths it added. The mandatory QA is automated tests (Jest + RTL) + a green `lint`/`typecheck`/`check:env` bar + driving the real app for screenshots; any device e2e layer is **ask-first and feature-scoped** (step 4), never part of the mandatory bar.

1. **Automated coverage** — for the new/changed surface, ensure tests exist per capability found:
   | Found | Tests must include |
   | --- | --- |
   | (always) | initial-render test + the loading / error / empty branches |
   | logic (util/hook/store/mapper/schema) | unit tests — **mandatory**, one per hook & util (tech-dna — Tests) |
   | interactions | fire via testID (`fireEvent`), assert observable result |
   | tabs/segments | activate each, assert content switched |
   | forms | valid → success, invalid → validation UI |
   | async states | loading / error / empty via a mocked boundary |
   Edge cases: zero/one/many items, missing optional data (no image, null fields), over-limit input, double-tap submit.
2. **Green bar:** `yarn lint && yarn typecheck && yarn test && yarn check:env` — all must pass.
3. **Drive the real app** with the `verify` (and `run`) skill if available: launch via the correct alias (`yarn ios:dev` / `yarn android:dev`), exercise the feature's happy path + one edge, and **screenshot each designed state**. Compare each shot against its Figma node values from the spec; fix mismatches, re-shoot. Stop when it matches or improvement stalls — don't iterate blindly (after 2 failed attempts at the same fix, step back and re-approach).
4. **Device e2e (Appium/Maestro/etc.) — always ASK, run only on an explicit yes, scoped to THIS feature.** e2e is never part of the mandatory bar (step 2 is) and never runs automatically. The ask is conditional on a spec existing for this feature:
   - **If a spec exists for this feature** (e.g. `e2e/specs/<feature>.spec.js`) → you MUST surface the question at QA: ask the user _"Run the e2e pass for `<feature>`? (default: No)"_. Run **only on an explicit yes**, and **only that spec** — never the whole suite. First-launch flows may need reset disabled.
   - **If no spec exists for this feature** → don't run anything; note it, and offer to scaffold one from the project's spec template. Do not fall back to the full suite.
5. **Fresh-eyes review:** dispatch a code-review agent on the diff **if one is installed** (e.g. `pr-review-toolkit:code-reviewer` or `feature-dev:code-reviewer`); otherwise do a deliberate fresh-eyes self-review pass against `docs/tech-dna.md`. Fix findings in this session.
6. ▸ **GATE B:** present the QA report — tests added + pass status, `lint/typecheck/test/check:env` results, screenshot paths per state, whether the feature's e2e spec was offered/run/skipped, review findings addressed. User skims.

## PHASE 4 — SHIP

- Update `docs/` in the same PR (tech-dna — Documentation): a new decision → an ADR; a new subsystem → `docs/architecture/`; a new env key → the environments doc + `.env.example`; a new pattern → `docs/tech-dna.md`. Reconcile the plan checkboxes + spec `Status` to what shipped.
- Open the PR (use `commit-commands:commit-push-pr` or `gh`) with the evidence bundle: plan + spec links, test results, QA screenshots, review findings addressed. End the PR body with the repo's required trailer (see `CLAUDE.md`).
- ▸ **GATE C:** user reviews the PR. Never merge without it.

## PHASE 5 — COMPOUND (2 minutes)

- Any **non-obvious** discovery this session (a design node quirk, an API/contract gotcha, a test-mock pattern, a strict-mode trap) → save to persistent memory (`project`/`reference`/`feedback` as fits), not the code.
- A mistake that recurred or is easy to repeat → propose a **hookify** rule (`/hookify`) so it's prevented mechanically next time.
- A new canonical pattern used here → confirm it's in `docs/tech-dna.md` with a copy-me snippet (should already be there from Phase 2).

**Hard rules:** ANY ambiguity → STOP and ask the human (batched); implement only after they clarify, and exactly per the clarification — never guess and build · one QA scope = this feature only · every code path tested at the boundary · every designed state screenshotted · docs in the PR or it didn't happen · after 2 failed attempts at the same fix, re-approach rather than iterate blindly · commit per slice, never push without the ship gate.
