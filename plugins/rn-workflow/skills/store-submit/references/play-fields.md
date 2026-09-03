# Play Console Data safety → where the answer comes from

Google's taxonomy differs from Apple's, so a type is never a straight copy. Export the
form (Data safety → Export to CSV) to audit what is currently declared: filter to rows
whose `Response value` is `true`.

## Structure

Per declared type Play asks four things Apple does not ask in the same shape:

| Question | Notes |
|---|---|
| **Collected, shared, or both** | *Shared* means transferred off your servers to a third party. Apple has no equivalent — this is the field most often wrong |
| **Processed ephemerally** | in memory only, never persisted. Location fixes often qualify |
| **Required or optional** | "optional" means the app still works if the user declines |
| **Purposes** | App functionality · Analytics · Developer communications · Advertising or marketing · Fraud prevention & security · Personalisation · Account management |

Two purposes have no Apple counterpart: **Fraud prevention & security** and **Account
management**. Do not drop them to match an Apple answer — declare what is true per store.

## Type mapping (Play ← → Apple)

| Play | Apple |
|---|---|
| Personal info → Name / Email address / Phone number / Address | Name / Email Address / Phone Number / Physical Address |
| Personal info → User IDs | User ID |
| Financial info → Purchase history | Purchase History |
| Financial info → Payment info | Payment Info |
| Location → Approximate location | Coarse Location |
| Location → Precise location | Precise Location |
| Photos and videos → Photos | Photos or Videos |
| Audio files → Voice or sound recordings | Audio Data |
| App activity → App interactions | Product Interaction |
| App activity → In-app search history | Search History |
| App activity → Other user-generated content | Other User Content |
| App info and performance → Crash logs | Crash Data |
| App info and performance → Diagnostics | Performance Data |
| Device or other IDs | Device ID |

A type declared on one store and not the other means one of them is wrong. Diff both.

## Play-only requirements

- **Account deletion URL** must *prominently feature the deletion steps*. A general
  support or contact page is **not** sufficient, and this is a common rejection.
- **Data deletion** is a separate question from account deletion. Both need answering.
- **`AD_ID` permission** in the manifest implies an advertising purpose. Declaring the
  permission while claiming no advertising use is a contradiction.
- **Encrypted in transit** is an explicit declaration; verify no cleartext traffic is
  permitted (`android:usesCleartextTraffic`, network security config).
- **Play App Signing re-signs the bundle**, so the production certificate is not the
  upload keystore's. Every SHA-restricted service needs both fingerprints. A locally
  built release APK will not reproduce the failure.

## Checks that transfer unchanged from iOS

From `contradictions.md`: description vs feature flags and inert controls (5), UGC vs
moderation (7), WebView guards (8), account-deletion claim vs backend reality (9), and
store-listing keywords vs catalogue (10). Those are app-truth questions, not
platform-form questions, so they apply identically.
