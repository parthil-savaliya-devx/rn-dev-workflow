---
description: 'Update a feature''s docs — add a question & answer, decision, requirement, edge case, bug fix or status change; shows the exact change and writes only after you confirm.'
---

Use the **`doc` skill** and follow its **/doc:update** flow exactly.

Arguments: `$ARGUMENTS` — the feature (e.g. `apply-coupon`), optionally with what to change. If the feature is ambiguous, ask which one.

Hard rules (from the skill — never break them):

- **Ask one question at a time**, with options, the recommended one first.
- **Never rewrite or delete history.** A changed decision is a new decision row; the old one is marked `(superseded by Dn)`.
- Decisions and bugs: **Decided by** = `git config user.name`; **Approved by** asked every time.
- **Show the exact rows to add or change and write only after the developer confirms.** Then bump **Updated**, add a Changelog row, and keep the module README and `docs/modules/README.md` in sync.
