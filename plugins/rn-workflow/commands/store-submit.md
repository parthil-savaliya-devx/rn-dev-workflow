---
description: 'Review the store submissions against the codebase — iOS first, then Android. Scope with /store-submit:ios or /store-submit:android.'
---

Run the **`store-submit` skill** for **both platforms, strictly in sequence: iOS first,
then Android.**

This is the default entry point. To scope a run to one store, the user runs
`/store-submit:ios` or `/store-submit:android` instead. If only one platform folder
exists in the repo, do that one and say so rather than reporting the other as missing.

## Order is not optional

1. **Do the entire iOS pass** — evidence with `--platform ios`, the repo read, the
   baseline report, then every App Store Connect section verified to completion.
2. **Stop and confirm.** Say iOS is complete, list anything still open on it, and ask
   whether to move on to Android. Do not begin Android while iOS sections are unresolved.
3. **Then the Android pass** — evidence with `--platform android`, and the Play Console
   sections verified the same way.
4. **Finally, diff the two declarations.** A data type or purpose declared on one console
   and not the other means one of them is factually wrong. Report those. Ignore pure
   taxonomy differences: Play's *Shared* flag and its Fraud-prevention /
   Account-management purposes have no Apple equivalent, so they are not divergences.

Why sequenced rather than interleaved: the two consoles ask different questions in
different words, and answering them side by side is how a fact gets declared one way on
one store and the other way on the other. Finish one, then carry its *evidence* — never
its answers — into the next.

The repo read (Step 2 of the skill) is done once and reused; the evidence dump and the
field maps are per platform.

**Report only — never edit their project unless they ask.**
