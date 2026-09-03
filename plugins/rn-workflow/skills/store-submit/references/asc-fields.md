# App Store Connect fields → where the answer comes from

## App Information
| Field | Derivation |
|---|---|
| Name | ≤30 chars. May differ from the on-device `DISPLAY_NAME`; note it if it does |
| Subtitle | ≤30 chars, **indexed**. Never repeat words already in the Name — duplicates buy no search surface |
| Bundle ID | must equal `PRODUCT_BUNDLE_IDENTIFIER` |
| Primary Language | must match the spelling conventions in the description |
| Category | primary = the app's actual function; secondary optional |
| Content Rights | "No" is standard for own-brand retail. Functional WebViews are not licensed content |
| Age Rating | see below |

## Age Rating
All content categories are **None** for a retail app. The three that need thought:
- **Unrestricted Web Access** — No, if every WebView is guarded (check 8)
- **User-Generated Content** — Yes if the app accepts reviews, comments, or photos. Pulls in Guideline 1.2 (check 7)
- **Made for Kids** — never, for an app with third-party analytics. Instant rejection

## App Privacy
One type per thing the app collects. Per type: purposes, linked-to-identity, tracking.
- The **linked** dialog defaults to **No** — it must be actively changed for every type that is linked
- Crash and Performance data → **Analytics**, not App Functionality
- Add **Developer's Advertising or Marketing** wherever a marketing-automation SDK receives the data
- A type is **Not Linked** only if its fetcher provably carries no session or user id — read the fetcher
- Free-text user content is *Other User Content*; uploaded images are *Photos or Videos*. A review with both needs **both**
- Drop *Other Data Types* unless someone can name what it is
- Tracking: see check 1. It is not a free choice when ATT is in the binary

## Version info
| Field | Derivation |
|---|---|
| Version | must equal `MARKETING_VERSION` |
| Description | every bullet needs code behind it (check 5) |
| Keywords | 100 chars, comma-separated, no spaces. No Name/Subtitle duplicates. Probe each term (check 10) |
| Support URL | a real support page (check 6) |
| Copyright | `<year> <legal entity>` — year included, entity matching the account holder |
| Screenshots | ≥1 iPhone set; only the first 3 show on the install sheet |

## App Review Information
- **Sign-In**: for phone-OTP apps the "password" is a fixed demo OTP. Confirm it works on a **release** build
- **Notes**: trace the sign-in path in code before writing it. A checkout that has no auth gate does **not** open the login screen — send the reviewer down a path that exists
- Say explicitly whether a purchase must be completed. For physical goods it need not be
- Mention any embedded third-party payment surface with its own sign-in

## Pricing and Availability
Restrict territories to where the app actually works — check the money formatter. A
hardcoded currency symbol with an ignored currency code means single-market.

## Build
Export compliance should not prompt (check 11). Bump the build number if the current
one is already in TestFlight.
