---
description: 'Review a Play Console submission against the codebase. Android only.'
---

Run the **`store-submit` skill** for **Android only**.

Do not touch App Store Connect. Ignore iOS evidence, `asc-fields.md`, and the iOS-only
checks (1, 2, 3, 4, 11, 12) — if the user brings up App Privacy or ATT, tell them to run
`/store-submit:ios` instead.

Use `references/play-fields.md` as the field map. Follow the skill exactly: collect
evidence with `--platform android`, read the repo for the project-shaped facts, report the
baseline **before** asking for any screenshot, then tell them where to start (App access →
Data safety → Content rating → Store listing → Advertising ID → Countries → Release) and
verify each batch as it arrives.

Pay particular attention to the Play-only traps: the account-deletion URL must
**prominently feature the deletion steps** (a general support page is not sufficient), a
declared `AD_ID` permission implies an advertising purpose, and both the account-deletion
and data-deletion questions need answering.

**Report only — never edit their project unless they ask.**
