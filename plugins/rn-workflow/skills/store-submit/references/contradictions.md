# The checks with teeth

Every one of these is mechanically detectable from the evidence dump. Ordered by cost.

## 1. ATT key vs tracking answer — HARD BLOCK

`NSUserTrackingUsageDescription` present in Info.plist + App Privacy declaring no
tracking = **App Store Connect refuses "Add for Review"**:

> *"Your app contains NSUserTrackingUsageDescription... update your App Privacy
> response to indicate that data collected will be used for tracking purposes, or
> update your app binary and upload a new build."*

Two exits: mark **Device ID** as used for tracking (dashboard only, adds a "Data Used
to Track You" block to the product page), or strip ATT from the binary — remove the
plist key, drop `AppTrackingTransparency` from `setup_permissions`, set
`$RNFirebaseAnalyticsWithoutAdIdSupport = true`, remove the prompt — and re-upload.

Also check the **purpose string's own text**. A string promising "measure how our
campaigns perform" is evidence against a no-tracking answer even when ASC accepts it.

## 2. ASC version vs MARKETING_VERSION

Must be identical or the uploaded build cannot attach to the version record. Also
check `CURRENT_PROJECT_VERSION` against TestFlight — a re-used build number is refused.

## 3. Device family vs required screenshots

`TARGETED_DEVICE_FAMILY = 1` → iPad and Watch screenshot slots are correctly empty.
`1,2` → iPad screenshots are **mandatory**. One 6.5" iPhone set covers every iPhone;
6.5"→6.9" is a ~4% upscale, so extra sizes are not worth chasing.

## 4. Privacy manifest vs App Privacy answers

`PrivacyInfo.xcprivacy` collected types should match the ASC type list, with the same
purposes and linked flags. Apple does not hard-block a mismatch, but the manifest is
public via the privacy report and the divergence is unexplainable in review.

## 5. Description vs feature flags and inert controls

The one that actually rejects. For every description bullet, find the code that
delivers it. A feature behind a `default: () => false` flag, or whose control only
fires a `comingSoon` toast, **is not in the app** — Guideline 2.3.1. Check whether the
flag hides the control entirely; a hidden feature the copy promises is indefensible.

## 6. Support URL

Must not be the privacy policy, the marketing site, or a 404. Guideline 1.5. `curl` it.

## 7. UGC declared vs moderation present

UGC = Yes in Age Rating pulls in Guideline 1.2: filtering, reporting, blocking,
published contact. Grep for report/flag/block mechanisms. If absent, the position
rests entirely on platform pre-moderation — verify it is actually switched on, and say
which Age Rating answers depend on it.

## 8. WebView guards vs "unrestricted web access"

Answer No only if **every** rendered WebView has `onShouldStartLoadWithRequest` or
`originWhitelist`. An unguarded WebView is a browser, and Yes forces 17+/18+.

## 9. Account deletion claim vs backend reality

An app offering account deletion must actually delete server-side (5.1.1(v)). A local
teardown that reports success is disproved by re-login with the same credential. No
dashboard field fixes this.

## 10. Keywords vs catalogue

Probe each product term against the store's own `/search?q=`. Zero results = irrelevant
metadata (2.3.7) and wasted characters. Don't test `/collections/<slug>` — many stores
404 every such path, which proves nothing.

## 11. Encryption key vs export compliance

`ITSAppUsesNonExemptEncryption = false` means ASC should never prompt. If it prompts,
the key is not being read and the build config is wrong.

## 12. Permission prompts vs declared data types

Every `NS*UsageDescription` implies a collected data type. A camera or microphone
prompt with no corresponding App Privacy type is an under-declaration.
