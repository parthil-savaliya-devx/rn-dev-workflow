---
description: 'Feature workflow — Plan → Build → QA & Verify → Ship → Compound, in one session.'
---

You are building a feature end-to-end in this session. Three human gates only: **plan approval (A)**, **QA report + change approval (B) — the commit gate: nothing is committed before it**, **PR review (C)**.

**Read first, every time:** `docs/tech-dna.md` (canonical patterns — all code copies these; §29 indexes the silent failures), `CLAUDE.md` (hard rules, silent traps + subsystem map), and any relevant [ADRs](docs/decisions/README.md). Project commands: use the ones in `CLAUDE.md` → **Commands** (defaults: `yarn lint --max-warnings=0`, `yarn typecheck`, `yarn test`, `yarn check:env`, `yarn ios:dev` / `yarn android:dev`). If `CLAUDE.md` doesn't list them, read `package.json` and use the real script names and package manager — never guess a script name.

## PHASE 1 — PLAN (in-session)

1. Explore the codebase read-only: reusable components (`components/core/`, `components/common/` first)/hooks/services, navigation types, stores, existing mappers/schemas. If a `graphify-out/` graph exists, prefer `graphify query "<question>"` over raw grep. Identify what to reuse before proposing anything new.
2. **Design source (if the feature has Figma):** use the `figma-to-ui` skill — `get_metadata` to find each node, then `get_design_context` for **every** screen/state involved. Extract exact spacing, colours→theme tokens, typography, icon sizes, and record the **node id per state** now (fail fast, not at QA time). Screenshots are for comprehension only (tech-dna — Figma → UI).
3. **Contract:** if the feature needs backend data, get the per-screen contract (query/endpoint + sample response + types) up front. No data path is designed without it. Never invent a shape.
4. **Ask the clarifying questions one at a time** — each a single `AskUserQuestion` with 2–4 options, the recommended one first — and wait for each answer before the next. Cover scope, behaviour and every edge case (empty, error, offline, slow network, double tap, permission denied, large text, 3-button navigation). Build only per the answers — never guess (hard rule). Each answer is recorded in the developer's own words; each choice it settles becomes a decision (**Decided by** = `git config user.name`, **Approved by** asked with git names as options).
5. **Persist the plan with the `doc` skill** (its /doc:new flow) — one folder per feature, `docs/modules/<module>/<feature>/`, where `<module>` is the code area (`src/components/<module>/`):
   - `spec.md` — **what & why**: status header, summary (goal / in scope / out of scope), every question and answer, every decision with who decided / approved / when, requirements (`WHEN … THE APP SHALL …`, each with its proof), edge cases, bugs fixed, changelog.
   - `build.md` — **how**: design values per element with the Figma **node id per state** (survives link rot), every file to create/modify and its job, the testID inventory, the task plan as `- [ ]` checkboxes, and the verification table.
   Show both files and write them only after the developer confirms. Status starts as **Draft**.
6. ▸ **GATE A:** present `spec.md` + `build.md` (link them). Wait for approval. On approval, ask who approved it (git names as options) and set the status to **Approved**. At every later phase transition update the `build.md` checkboxes and the spec status (**Building** when code starts); a deviation discovered while building is asked about, then recorded as a new decision row + a Changelog row — never leave the spec stale, never rewrite an earlier answer.

## PHASE 2 — BUILD

0. Pre-read `docs/tech-dna.md` AND your persistent memory (recalled `<system-reminder>` context + relevant `feedback`/`project` memories). All code follows the tech-DNA canonical patterns (data pipeline, sections, stores, styling, naming, testIDs). **A pattern with no tech-DNA precedent is designed at Gate A and added to `docs/tech-dna.md` in the same PR** (Evolving the DNA) — never improvised.
1. **Logic first, TDD** where there's logic (utils, hooks, stores, mappers, schemas): write the failing test in `__tests__/` mirroring `src/` → confirm red → implement → green. Mock at the boundary (`@/services`), leave real schema+mapper in place. Never modify a test to force green.
2. **Data path** (if any): query text in `src/graphql/queries/` → `fetch<X>` using the boundary fetcher (timeout, auth-by-default, redacted errors) with a `getConfig('USE_MOCK')` branch that loads its fixture lazily → Zod schema in `src/schemas/` declaring only the fields the screen reads → mapper firewall in `src/mappers/` (`type→fn` map, never `switch`) → view-model type → presentation component. Request-side shaping is a pure `build<X>Request` util. Wire the hook via a shared query-options factory with the retry predicate; add pull-to-refresh. Probe the live contract before relying on any field (tech-dna — Contracts & request building).
3. **UI:** theme tokens only (hex-only, `spacing.*`/`typography.*`, weight-by-family, `BaseText`); the shared `Pressable`, image component (`renderWidthDp`), `BottomSheet` shell and Reanimated for motion; WebP for bundled rasters. Reuse project components before any React Native primitive, and place new ones per tech-dna — Component structure & reuse (core/ · common/ · <area>/; the screen folder holds only the screen). Media is sized from screen width + `aspectRatio`, never hardcoded; every bottom element respects the safe-area inset (edge-to-edge, 3-button nav); built to stay smooth on 2–4 GB RAM phones (tech-dna — Edge-to-edge & system bars, Performance). Build each screen/state, then converge visually against the Figma node values — never reverse-engineer measurements after the fact.
4. **Add a `testID`** to every interactive and landmark element **as you build** — QA and any future e2e depend on them.
5. **Persisted store?** `skipHydration:true` + a `rehydrate()` line in `App.tsx`'s `Promise.all` + an explicit `version` + an allow-list `partialize`; never a token (footgun — tech-dna — State).
6. **Do not commit.** The whole change stays uncommitted until Gate B approves it (tech-dna — Human verification precedes every commit). Do not enter Phase 3 with red tests or missing testIDs.

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
2. **Green bar:** `yarn lint --max-warnings=0 && yarn typecheck && yarn test && yarn check:env` — all must pass (the flag matches CI: a lint warning fails the build).
3. **Drive the real app** with the `verify` (and `run`) skill if available: launch via the correct alias (`yarn ios:dev` / `yarn android:dev`), exercise the feature's happy path + one edge, and **screenshot each designed state**. Cover **Android 3-button navigation** for any screen with a bottom bar/sheet, do a quick **screen-reader pass (TalkBack / VoiceOver) and a largest-system-font check** on new screens, and check scrolling, transitions and memory on a **low-end Android (2–4 GB RAM) release build** where the feature has lists, media or animation. Compare each shot against its Figma node values from the spec; fix mismatches, re-shoot. Stop when it matches or improvement stalls — don't iterate blindly (after 2 failed attempts at the same fix, step back and re-approach).
4. **Device e2e (Appium/Maestro/etc.) — always ASK, run only on an explicit yes, scoped to THIS feature.** e2e is never part of the mandatory bar (step 2 is) and never runs automatically. The ask is conditional on a spec existing for this feature:
   - **If a spec exists for this feature** (e.g. `e2e/specs/<feature>.spec.js`) → you MUST surface the question at QA: ask the user _"Run the e2e pass for `<feature>`? (default: No)"_. Run **only on an explicit yes**, and **only that spec** — never the whole suite. First-launch flows may need reset disabled.
   - **If no spec exists for this feature** → don't run anything; note it, and offer to scaffold one from the project's spec template. Do not fall back to the full suite.
5. **Fresh-eyes review:** dispatch a code-review agent on the diff **if one is installed** (e.g. `pr-review-toolkit:code-reviewer` or `feature-dev:code-reviewer`); otherwise do a deliberate fresh-eyes self-review pass against `docs/tech-dna.md`. Fix findings in this session.
6. **Docs in the same change set** (tech-dna — Documentation): a new decision → an ADR; a new subsystem → `docs/architecture/`; a new env key → the environments doc + `.env.example`; a new pattern → `docs/tech-dna.md`; a new silent failure → a line in `CLAUDE.md` → Traps. Fill `build.md` → Verification and the spec's **Proof** column with evidence (test names, screenshot paths), reconcile the plan checkboxes, and run `/doc:check`.
7. ▸ **GATE B — the commit gate:** present the QA report — tests added + pass status, `lint/typecheck/test/check:env` results, screenshot paths per state, whether the feature's e2e spec was offered/run/skipped, review findings addressed — **and the uncommitted change set**: files changed, what was verified and how, what is still open. **Wait for explicit approval.** Fold any requested changes into the same uncommitted set and present again. On approval, commit (conventional commits — logical commits are fine, no fixup chains; do NOT push yet).

## PHASE 4 — SHIP

- Only after Gate B approval: push the branch and open the PR (use `commit-commands:commit-push-pr` or `gh`) with a short **Why** (the user/business reason for the feature) and the evidence bundle: `spec.md` + `build.md` links, test results, QA screenshots, review findings addressed. Add the PR to the spec header and a Changelog row. After the PR merges, the developer confirms and the status becomes **Shipped**. End the PR body with the repo's required trailer (see `CLAUDE.md`).
- ▸ **GATE C:** user reviews the PR. Never merge without it.

## PHASE 5 — COMPOUND (2 minutes)

- Any **non-obvious** discovery this session (a design node quirk, an API/contract gotcha, a test-mock pattern, a strict-mode trap) → save to persistent memory (`project`/`reference`/`feedback` as fits), not the code.
- A mistake that recurred or is easy to repeat → propose a **hookify** rule (`/hookify`) so it's prevented mechanically next time.
- A new canonical pattern used here → confirm it's in `docs/tech-dna.md` with a copy-me snippet (should already be there from Phase 2).

**Hard rules:** ANY ambiguity → STOP and ask the human — **one question at a time, with options**; nothing is written to docs or code without the developer's confirmation; implement only after they clarify, and exactly per the clarification — never guess and build · one QA scope = this feature only · every code path tested at the boundary · every designed state screenshotted · docs in the PR or it didn't happen · after 2 failed attempts at the same fix, re-approach rather than iterate blindly · nothing is committed before Gate B approval, and nothing is pushed before it.
