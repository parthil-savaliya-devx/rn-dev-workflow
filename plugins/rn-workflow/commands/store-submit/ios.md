---
description: 'Review an App Store Connect submission against the codebase. iOS only.'
---

Run the **`store-submit` skill** for **iOS only**.

Do not touch Play Console. Ignore Android evidence, Android field maps, and the
Android-only checks — if the user brings up Data safety, tell them to run
`/store-submit:android` instead.

Follow the skill exactly: collect evidence with `--platform ios`, read the repo for the
project-shaped facts, report the baseline **before** asking for any screenshot, then tell
them where to start and verify each batch as it arrives.

**Report only — never edit their project unless they ask.**
