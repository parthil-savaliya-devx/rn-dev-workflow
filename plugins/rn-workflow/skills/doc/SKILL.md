---
name: doc
description: Feature documentation for this project — one folder per feature in docs/modules/<module>/<feature>/ with spec.md (questions asked and the dev's answers, decisions with who decided / who approved / when, requirements, edge cases, bugs fixed, changelog) and build.md (design values, files, testIDs, plan, verification). Used automatically by /feature and /fix, and directly via /doc:new, /doc:update and /doc:check. Use when creating, updating or checking a feature's docs, recording a question, decision, edge case or bug, or when someone asks what was decided for a feature and who approved it.
---

# Feature docs

Every feature is documented in one place, in one fixed format, so anyone can open a feature and see
**what was asked, what the developer answered, what was decided, by whom, approved by whom, and when** —
nothing is guessed and nothing is "vibe-coded".

## Hard rules (never break these)

1. **Nothing is written or changed without the developer's confirmation.** Before writing, show the
   exact rows or text you will add or change, ask "Write this?", and write only after a yes.
2. **Ask one question at a time, with options.** Use `AskUserQuestion` with a **single** question,
   2–4 options, the recommended option first and marked "(Recommended)". Never send a list of questions
   at once. Wait for the answer before asking the next one.
3. **Never assume.** Anything the developer has not answered is an open question, not a default. If a
   doc, the code or the design doesn't settle it, ask.
4. **Record answers in the developer's own words** (quoted). A paraphrase loses the reason.
5. **Every decision records who and when:**
   - **Decided by** — the developer's git name: `git config user.name`.
   - **Approved by** — ask every time. Offer git names as the options: the current user plus the most
     frequent recent authors (`git log -n 200 --format='%an' | sort | uniq -c | sort -rn | head -3`),
     and "Other" for anyone else.
   - **Date** — today, `YYYY-MM-DD`.
6. **One home per fact.** Update the feature's `spec.md` / `build.md` in place and add a Changelog row.
   Never create a second or dated copy of a spec.
7. **IDs are never reused or renumbered:** `Q1…` questions, `D1…` decisions, `R1…` requirements,
   `E1…` edge cases, `B1…` bugs — per feature, next number = highest + 1. A changed decision gets a
   **new** decision row; the old row keeps its text and gets `(superseded by D7)` added to its Decision cell.
8. **Never delete history** — no removed rows, no rewritten answers. Corrections are new rows plus a
   Changelog entry.

## Where docs live

```
docs/
  modules/
    README.md               ← index of every feature: module · feature · status · owner · updated
    <module>/               ← same name as the code area: src/components/<module>/
      README.md             ← what this area does + its feature list
      <feature>/            ← kebab-case slug, e.g. apply-coupon
        spec.md             ← WHAT & WHY (what gets approved)
        build.md            ← HOW (how it was built and checked)
  decisions/                ← app-wide decisions only (ADRs) — not feature decisions
  tech-dna.md · architecture/ · runbooks/ · glossary.md   ← unchanged
```

- A feature that touches several modules lives in the module that owns its main screen; other modules
  link to it from their README.
- A decision that affects the **whole app** (a library, an architecture rule) is an ADR in
  `docs/decisions/`; the feature's decision row links to it instead of repeating it.
- Templates: `${CLAUDE_PLUGIN_ROOT}/skills/doc/templates/` — `spec.md`, `build.md`,
  `module-README.md`, `modules-README.md`. Copy them; never invent a different layout.

## The two files

**`spec.md` — what & why.** Header table (Status · Owner · Approved by · Created · Updated), Figma and PR
links, then these sections, always in this order:

| Section | Columns |
|---------|---------|
| 1. Summary | Goal · In scope · Out of scope |
| 2. Questions & answers | # · Question · Options given · Answer (dev's words) · By · Date |
| 3. Decisions | # · Decision · Why · Decided by · Approved by · Date · From (the Q it came from) |
| 4. Requirements | # · Requirement (`WHEN … THE APP SHALL …`) · Proof (test name / screenshot) |
| 5. Edge cases | # · Situation · What should happen · Proof · From |
| 6. Bugs fixed | # · What broke · Root cause · Fix · Decided by · Approved by · Date · PR |
| 7. Changelog | Date · Change · By · Ref |

**`build.md` — how.** `Spec: ./spec.md`, then: 1. Design values (from Figma) · 2. Files · 3. testIDs ·
4. Plan (`- [ ] T1 …` checkboxes) · 5. Verification (Check · Result · Evidence).

**Proof is evidence a person can open** — a test name, a file path, a screenshot path — never the word
"verified" or "done".

## Status

| Status | Means | Set when |
|--------|-------|----------|
| Draft | questions are still being asked | the spec is created |
| Approved | the developer approved the spec | the approver confirms (ask for **Approved by** — rule 5) |
| Building | work has started | the first code change for it begins |
| Shipped | merged | the developer confirms the PR is merged |
| Retired | removed or replaced | the developer confirms; link what replaced it |

Every status change updates the spec header, the module README row, the `docs/modules/README.md` row and
the Changelog — and, like every write, only after the developer confirms.

## /doc:new — create a feature's docs

1. Read first: `docs/tech-dna.md`, `docs/modules/README.md`, the module's README, related code and any
   linked ADRs. Don't ask what these already answer — that's reading, not a question.
2. Confirm the module and feature name (one question). If `docs/modules/` or the module folder doesn't
   exist yet, say so and ask before creating it from the templates.
3. **Ask the questions one at a time** (rule 2): the goal, what's in and out of scope, behaviour, every
   edge case (empty, error, offline, slow network, double tap, permission denied, large text, 3-button
   navigation…), and anything the design or contract leaves open. Each answer becomes a Q row, in the
   developer's words. Each choice it settles becomes a D row (Decided by from git; ask Approved by).
4. Draft the requirements (R rows) and edge cases (E rows) from the answers — nothing that wasn't
   answered.
5. Show the full spec content and the `build.md` skeleton, ask "Write this?", and write only on yes.
   Status starts as **Draft**. Add the feature to the module README and the index.
6. When the developer approves the spec, ask who approved it (rule 5), set **Approved**, and add a
   Changelog row.

## /doc:update — change a feature's docs

1. Find the feature (`docs/modules/*/<feature>/`). If the name matches more than one, ask which.
2. Ask what to add or change — one question, options: a question & answer · a decision · a requirement ·
   an edge case · a bug fixed · a status change · something in build.md.
3. Ask any follow-up questions one at a time. For a decision or a bug: Decided by from git, ask
   Approved by.
4. Show the exact rows to add or change, ask "Write this?", write on yes.
5. Always: bump the header's **Updated** date, add a Changelog row, and update the module README and the
   index if status or owner changed.

## /doc:check — keep docs tidy

Run the mechanical check:

```bash
node "${CLAUDE_PLUGIN_ROOT}/skills/doc/scripts/doc-check.mjs" .
```

It checks that every feature folder has both files with every section in order; every row has its ID,
no ID is used twice, and `From` points at an ID that exists; every question has an answer, by and date;
every decision and bug has Decided by, Approved by and a real date; an Approved / Building / Shipped spec
has an approver and at least one requirement; status values are valid; the module READMEs and the index
list exactly the features that exist, with matching status; and local links resolve.

Then review what a script can't: a decision with no real "why", a Shipped requirement whose proof is
missing, answers that contradict each other, or a spec that no longer matches the code. **Report
problems and ask before fixing anything.** The same script runs as a hook at the end of every turn in
which `docs/modules/` changed, so broken docs never pile up.

## How /feature and /fix use this

- **/feature** — Plan creates the feature's docs with the `/doc:new` flow (questions one at a time);
  Gate A is the spec approval (status → Approved, Approved by asked); Build sets Building and fills
  `build.md` (files, testIDs, plan checkboxes); QA fills Verification and the Proof column; Ship adds the
  PR link and a Changelog row; after merge, the developer confirms and the status becomes Shipped.
- **/fix** — the bug goes in the affected feature's `spec.md` → **6. Bugs fixed** (what broke, root
  cause, fix, decided by, approved by, date, PR) plus a Changelog row. If the feature has no docs yet,
  ask whether to create them (via `/doc:new`) or record the fix only in the PR.
