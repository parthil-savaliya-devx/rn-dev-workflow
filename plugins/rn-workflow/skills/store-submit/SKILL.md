---
name: store-submit
description: Review an App Store Connect submission against the app's own codebase. Use when the user wants their submission checked, says they will share App Store Connect screenshots for verification, asks where to start with a submission, or hits an "Unable to Add for Review" error. Also for App Privacy, Age Rating, description-accuracy and review-notes questions.
---

# App Store submission review

The user shares App Store Connect screenshots; you verify each answer against what the
code actually does. **Report only — never edit their project unless they ask.**

Never answer a submission question from the app's marketing, a `docs/` note, or a
plausible default. Every answer is derived from the repo, and when a doc disagrees with
the code, the code wins and you say the doc is stale.

## Step 1 — Review the app first, and report the baseline

Do this before asking for a single screenshot. The user's opening ask is usually some
form of *"check the app in core and deep enough"* — take it literally.

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/store-submit/scripts/collect-evidence.sh" .
```

Then read the repo for what a script cannot know (see Step 2). Report back a short
baseline the user can sanity-check:

- **Identity** — bundle id, marketing version, build number, per-scheme display names
- **What the app does** — route inventory, the real feature surface
- **Permissions declared** — every `NS*UsageDescription`, and what each is for
- **Privacy manifest** — how many types, which purposes, tracking flag
- **Risks already visible** — anything the evidence contradicts before you have seen
  any screenshot at all

End Step 1 by naming the one or two things most likely to sink the submission. Those
are usually visible from the code alone.

## Step 2 — Read the repo for the project-shaped facts

The script only collects things with a fixed location. These live wherever this project
puts them, and a hardcoded grep that finds nothing is indistinguishable from nothing to
find — a silent false negative. So explore, don't pattern-match:

**Feature flags / kill switches.** Find how the app reads remote config, then find every
flag's build-time default. A feature behind a default-off flag is not in the shipping
app. Read the consumer too: a flag that *hides* a control is worse for a description
claim than one that disables it.

**Inert controls.** Find this project's own marker for "renders but does nothing" — a
toast constant, a TODO convention, a no-op handler. Grep the marker you actually find.
Map each hit to the screen a reviewer would tap.

**The real auth path.** Trace the login and checkout entry points in code before
writing review notes. Never assume a checkout screen has an auth gate.

**UGC + moderation.** Find what submits user content, and whether users can report
content or block each other. Absence means the Guideline 1.2 position rests on platform
pre-moderation — say which Age Rating answers then depend on it.

**Money / market.** Read the currency formatter to decide territory availability.

**Bullet-to-code mapping.** For every description claim, find the code that delivers it.

## Step 3 — Tell the user where to start

When they ask *"where do I start?"*, give this order — cheapest rejection first — with
the reason attached to each, not a bare list:

1. **App Review Information** — demo credentials and notes. If the reviewer cannot sign
   in, nothing else matters.
2. **App Privacy** — types, purposes, linked, tracking, and the policy URL. Where the
   hard block lives (check 1).
3. **App Information** — name, subtitle, category, content rights, age rating.
4. **Version info** — screenshots, description, keywords, support and marketing URLs.
5. **Pricing and Availability** — territories.
6. **Build** — the attached build and export compliance.

Invite them to send 1 and 2 together; those two carry the real blockers.

## Step 4 — Verify each batch as it arrives

For every screenshot: diff it against the evidence, report **only** mismatches and the
reason, then hand over the **exact value to paste** — not a description of the fix.
Confirm plainly when a section is correct, and say so field by field so they can trust
it. Walk dialogs click by click when they are mid-flow; note where a dialog's default
answer is the wrong one.

Never invent Apple's current UI wording. If you are unsure what a dialog asks, ask for
that screenshot.

## Step 5 — Run every check

`${CLAUDE_PLUGIN_ROOT}/skills/store-submit/references/contradictions.md` — 12 checks.
Check 1 is a hard block; the rest each cost a review cycle. Work through all of them
before calling a section clean.

`${CLAUDE_PLUGIN_ROOT}/skills/store-submit/references/asc-fields.md` — every field
mapped to how its answer is derived. Use it instead of guessing.

## Verify claims against live infrastructure, not just code

- `curl` every URL in a field. A policy behind a store password gate returns 200.
- Probe keyword terms against the store's own search endpoint before accepting them.
- Check MX and SPF on any support email domain. No MX, or `v=spf1 -all`, means the
  address cannot receive mail — regardless of how official it looks.
- When a probe returns the same result for every input, the probe is broken, not the
  answer. Say so and find another method.

## Output

Close with a report: every field checked, its verdict, and the evidence line that
settled it. Then the open items split into blockers, things still changeable, and
decisions only the user can make. That report is the paper trail for *"why did we
answer No to tracking?"* six months later.
