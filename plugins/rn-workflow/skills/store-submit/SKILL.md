---
name: store-submit
description: Verify an App Store Connect submission against the actual codebase. Use when preparing or reviewing an iOS App Store submission, checking App Privacy / Age Rating / description accuracy, or when the user shares App Store Connect screenshots and asks whether the answers are right. Also for "Unable to Add for Review" errors.
---

# App Store submission review

Verify what the dashboard *claims* against what the binary *does*. Never answer a
submission question from the app's marketing — derive it from the repo.

## 1. Collect evidence FIRST

```bash
STORE_URLS="<privacy-url> <support-url> <deletion-url>" \
  "${CLAUDE_PLUGIN_ROOT}/skills/store-submit/scripts/collect-evidence.sh" .
```

Read the whole output before looking at any screenshot. It is the ground truth for
every check below. Do not guess at a value the script can print.

## 2. Derive the project-shaped facts by READING the repo

The script deliberately does not scan for these — they live wherever each project puts
them, and a grep that returns nothing looks exactly like nothing to find. Explore the
codebase and answer each question from what is actually there:

**Feature flags / kill switches.** Find how the app reads remote config or feature
flags, then find every flag's *build-time default*. Any feature behind a false default
is not in the shipping app. Also read how the flag is consumed — a flag that hides a
control entirely is worse for a description claim than one that shows a disabled state.

**Inert controls.** Find the project's own marker for "renders but does nothing" — a
toast constant, a TODO convention, a no-op handler. Grep the marker you actually find,
not one you assumed. Then map each hit to the screen a reviewer would tap.

**Auth path.** Trace what actually happens on the login/checkout entry points before
writing review notes. Read the gate hook; do not assume a checkout screen has an auth
check.

**UGC moderation.** Find whether users can report content or block each other, and
what submits user content. Absence means the Guideline 1.2 position rests on platform
pre-moderation — name which Age Rating answers then depend on it.

**Money / market.** Read the currency formatter to decide territory availability.

**Feature-to-bullet mapping.** For every description bullet, find the code that
delivers it. No code, no bullet.

## 3. Then take screenshots, section by section

Ask for them in this order — cheapest rejection first:

1. App Review Information (demo credentials + notes)
2. App Privacy
3. App Information (+ Age Rating)
4. Version info (screenshots, description, keywords, URLs)
5. Pricing and Availability
6. Build / Export Compliance

For each, diff the screenshot against the evidence dump. Report only mismatches and
the reason, then give the **exact value to paste** — not a description of the fix.

## 4. Run every check in ${CLAUDE_PLUGIN_ROOT}/skills/store-submit/references/contradictions.md

That file is the point of this skill. Check 1 is a hard block; the rest cost a review
cycle (~1 week each). Work through all of them before saying a section is clean.

## 5. Field answers

`${CLAUDE_PLUGIN_ROOT}/skills/store-submit/references/asc-fields.md` maps each App Store Connect field to how its answer is
derived from evidence. Use it rather than inventing an answer.

## Rules

- **Repo over docs.** A `docs/` note can be stale. Verify against code, then say so
  if the doc is wrong — that finding is worth more than the answer.
- **A default-off feature flag cannot be advertised.** Grep the flag defaults; any
  feature behind a `false` default must not appear in the description.
- **An inert control is a described feature that does not exist.** Sweep for
  `comingSoon` / TODO call sites and cross-check them against description bullets.
- **Probe live URLs.** Never trust a URL in a field. `curl` it. A privacy policy behind
  a store password gate reads 200 and is still a rejection.
- **Probe keyword claims** against the live catalogue (the store's own `/search?q=`)
  before accepting a keyword list.
- **Never fabricate Apple's UI wording.** ASC changes. Ask for the screenshot of the
  actual dialog rather than guessing at the current question text.
- Report only. Do not edit project files unless asked.

## Output

End with a markdown report: every field checked, its verdict, and the evidence line
that settled it. That is the paper trail for "why did we answer No to tracking".
