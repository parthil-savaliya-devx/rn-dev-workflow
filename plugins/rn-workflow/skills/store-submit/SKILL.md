---
name: store-submit
description: Review an app store submission against the app's own codebase. Use when the user wants their App Store Connect or Play Console submission checked, says they will share store-console screenshots for verification, asks where to start with a submission, or hits an "Unable to Add for Review" error. Also for App Privacy, Data safety, Age Rating, description-accuracy and review-notes questions. Covers both stores by default — iOS first, then Android; scope it with /store-submit:ios or /store-submit:android.
---

# Store submission review

The user shares store-console screenshots; you verify each answer against what the code
actually does. **Report only — never edit their project unless they ask.**

Never answer a submission question from the app's marketing, a `docs/` note, or a
plausible default. Every answer is derived from the repo, and when a doc disagrees with
the code, the code wins and you say the doc is stale.

## Platform — default is BOTH, iOS first

| Invocation | Scope |
| --- | --- |
| `/store-submit:ios` | App Store Connect only |
| `/store-submit:android` | Play Console only |
| `/store-submit:both`, or no scope given | **both, sequenced: iOS to completion, then Android** |

A named store scopes it too: App Store / App Store Connect / TestFlight → iOS. Play /
Play Console / Data safety / AAB → Android. Only one platform folder in the repo? Use that
one.

**When doing both, finish iOS entirely before starting Android.** Complete every App
Store Connect section, say so, list what is still open on it, and ask before moving on.
Then run the Android pass, and close by diffing the two declarations.

Sequenced rather than interleaved for a reason: the two consoles ask different questions
in different words, and answering them side by side is exactly how one fact ends up
declared one way on one store and another way on the other. Finish one, then carry its
**evidence** — never its answers — into the next.

The repo read (Step 2) is done once and reused. The evidence dump and the field maps are
per platform.

## Step 1 — Review the app first, and report the baseline

Do this before asking for a single screenshot. The user's opening ask is usually some
form of *"check the app in core and deep enough"* — take it literally.

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/store-submit/scripts/collect-evidence.sh" . --platform ios
```

Then read the repo for what a script cannot know (Step 2). Report back a short baseline
the user can sanity-check:

- **Identity** — bundle id / applicationId, version, build number, per-variant names
- **What the app does** — route inventory, the real feature surface
- **Permissions declared** — every one, and what each is for
- **Privacy declarations already in the binary** — iOS privacy manifest, Android manifest
- **Risks already visible** — anything the evidence contradicts before you have seen any
  screenshot at all

End Step 1 by naming the one or two things most likely to sink the submission. Those are
usually visible from the code alone.

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

**The real auth path.** Trace the login and checkout entry points in code before writing
review notes. Never assume a checkout screen has an auth gate.

**UGC + moderation.** Find what submits user content, and whether users can report
content or block each other. Absence means the policy position rests on platform
pre-moderation — say which content-rating answers then depend on it.

**Money / market.** Read the currency formatter to decide territory availability.

**Bullet-to-code mapping.** For every store-listing claim, find the code that delivers it.

## Step 3 — Tell the user where to start

When they ask *"where do I start?"*, give the order — cheapest rejection first — with the
reason attached to each, not a bare list.

**iOS:** App Review Information (demo credentials and notes — if the reviewer cannot sign
in, nothing else matters) → App Privacy (where the hard block lives, check 1) → App
Information + Age Rating → Version info (screenshots, description, keywords, URLs) →
Pricing and Availability → Build and export compliance.

**Android:** App access (test credentials) → Data safety (the largest form, and the one
with the deletion-URL trap) → Content rating → Store listing → Advertising ID → Countries
and pricing → the release itself.

Invite them to send the first two together; those carry the real blockers.

## Step 4 — Verify each batch as it arrives

For every screenshot: diff it against the evidence, report **only** mismatches and the
reason, then hand over the **exact value to paste** — not a description of the fix.
Confirm plainly when a section is correct, field by field, so they can trust it. Walk
dialogs click by click when they are mid-flow, and flag where a dialog's default answer
is the wrong one.

Never invent the console's current UI wording — it changes. If you are unsure what a
dialog asks, ask for that screenshot.

## Step 5 — Run every check

`${CLAUDE_PLUGIN_ROOT}/skills/store-submit/references/contradictions.md` — 12 checks.
Check 1 is an iOS hard block; the rest each cost a review cycle. Checks 5, 7, 8, 9 and 10
are app-truth questions and apply to both platforms unchanged.

Field maps — use these instead of guessing:
- `${CLAUDE_PLUGIN_ROOT}/skills/store-submit/references/asc-fields.md` (iOS)
- `${CLAUDE_PLUGIN_ROOT}/skills/store-submit/references/play-fields.md` (Android)

## Both platforms? Diff them

A data type or purpose declared on one store and not the other means one of them is
wrong. Play's *Shared* flag and its Fraud-prevention / Account-management purposes have
no Apple equivalent — do not force them to match; declare what is true per store, and
report any divergence that implies a factual disagreement rather than a taxonomy one.

## Verify claims against live infrastructure, not just code

- `curl` every URL in a field. A policy behind a store password gate returns 200.
- Probe keyword terms against the store's own search endpoint before accepting them.
- Check MX and SPF on any support email domain. No MX, or `v=spf1 -all`, means the
  address cannot receive mail — regardless of how official it looks.
- When a probe returns the same result for every input, the probe is broken, not the
  answer. Say so and find another method.

## Output

Close with a report: every field checked, its verdict, and the evidence line that settled
it. Then the open items split into blockers, things still changeable, and decisions only
the user can make. That report is the paper trail for *"why did we answer No to
tracking?"* six months later.
