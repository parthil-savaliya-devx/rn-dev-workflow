# Feature docs

Every feature has one folder: `docs/modules/<module>/<feature>/` with two files —
**`spec.md`** (what & why: questions and answers, decisions, requirements, edge cases, bugs fixed,
changelog) and **`build.md`** (how: design values, files, testIDs, plan, verification).
Managed by the `doc` skill (`/doc:new`, `/doc:update`, `/doc:check`). Status steps:
Draft → Approved → Building → Shipped → Retired.

App-wide decisions live in [`../decisions/`](../decisions/README.md); coding rules in
[`../tech-dna.md`](../tech-dna.md).

| Module | Feature | Status | Owner | Updated |
|--------|---------|--------|-------|---------|
