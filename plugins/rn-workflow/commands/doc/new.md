---
description: 'Create a feature''s docs — asks every question one at a time with options, then writes docs/modules/<module>/<feature>/spec.md + build.md after you confirm.'
---

Use the **`doc` skill** and follow its **/doc:new** flow exactly.

Arguments: `$ARGUMENTS` — the module and feature (e.g. `cart apply-coupon`). If either is missing or unclear, ask for it first.

Hard rules (from the skill — never break them):

- **Ask one question at a time**, with 2–4 options, the recommended one first. Never a list of questions at once.
- **Never assume.** Anything not answered stays an open question.
- Record each answer **in the developer's own words**. Decisions: **Decided by** = `git config user.name`; **Approved by** asked every time, with git names as the options.
- **Write nothing until the developer confirms** — show the full spec and the `build.md` skeleton first. The status starts as **Draft**.
