---
name: figma-to-ui
description: "Convert a Figma node into React Native UI that follows this repo's conventions (theme tokens, useThemeStyles, SectionRegistry, mapper-as-firewall, mandatory tests). Use when given a Figma node id / Dev Mode link plus a screenshot, for a new screen, a rebuild of an existing screen, a single new section, or a standalone component. Works with or without a ready backend contract."
---

# /figma-to-ui

Turn a Figma node into working React Native UI for this app, following the
project's canonical patterns in **`docs/tech-dna.md`** (data pipeline,
config-driven section rendering, token-only styling, mandatory tests).
Durable work (view-model + components) is derived from the design; the
data-layer wire shape (schema + mapper + fixture) is a clearly-flagged
provisional guess until the real contract lands.

> **Template note:** this skill assumes the tech-DNA patterns (the data
> pipeline, `SectionRegistry`, `useThemeStyles`, theme tokens, and the shared core
> components — `Pressable`, `Button`, the image component) exist in the project. On a
> fresh scaffold some are stubs — build the missing primitive first (in
> `src/components/core/<name>/`, tech-dna §1b), or adapt the names to your project. `src/theme` is always the source of truth
> for token names; the tables in `references/conventions.md` are illustrative
> starting values, not fixed law.

## Inputs & prerequisites

**Required:**

- Figma node id or Dev Mode link (e.g. `https://www.figma.com/design/<fileKey>/…?node-id=…&m=dev`)
- Screenshot of the node (for understanding the layout only — every value comes from the node specs; pasted into the message)
- Written instructions / intent (what screen or section, what changed, any reuse notes)

**Prerequisite — Figma MCP auth:**
The skill requires the Figma MCP server to be authenticated before any node fetch.
Check auth state first. If not yet authenticated, surface the one-time OAuth step
and **stop until the user confirms auth is complete**. Do not proceed without it.

**Optional — API contract:**
Providing a cURL + sample response + types flips the skill from "provisional guess" mode
to "real contract" mode. In real-contract mode the sample response becomes the Jest fixture
and no provisional banners are written for the data-layer files.

## Ask, don't assume

**This is a standing rule that overrides all momentum: correct beats fast.**

The skill never silently assumes anything it is not certain about. On any of the following:

- Unclear section behavior or layout intent
- A theme token that is missing or uncertain for a raw Figma value
- An undefined interaction or animation
- An ambiguous wire-shape or data field
- An unstated track or backend mode

…the skill **pauses and asks the user a focused, specific question** before proceeding.

Token gaps (Figma values with no matching theme token) and provisional-wire uncertainties
are raised as explicit questions during the work — they are not buried in the final summary.

**No silent defaults.** If the track cannot be determined from the request, ask.
If the data mode is not stated, ask. If a section's behavior in an edge state
(empty, error, loading) is not shown in the Figma, ask.

## Step 0 — Intake & classify

Before any file is created or read, classify the request:

**Track** (exactly one):

- `new screen` — a net-new route with its own schema, mapper, hook, sections, registry, and nav entry
- `rebuild existing screen` — diff the new Figma against the existing sections; restyle, add, remove
- `add one section` — a single `kind` added to an existing screen
- `standalone component` — a variant-driven component in `src/components/`, no data layer

**Data mode** (exactly one):

- `mock` — no API contract provided; build on a committed fixture via `USE_MOCK`
- `api` — contract (cURL + sample response + types) provided; use the real contract

**If either is ambiguous or absent from the request, ask — do not default silently.**

After classifying, confirm Figma MCP auth (see Inputs & prerequisites) before any
other action. Do not fetch the node or read any files until auth is confirmed.

## Routing — 4 tracks

### Track 1: New screen

Creates a full vertical slice:

| File                                             | Action                                                          |
| ------------------------------------------------ | --------------------------------------------------------------- |
| `src/schemas/<area>.ts`                          | New Zod schema for wire shape                                   |
| `src/mappers/map<Screen>.ts`                       | New mapper — wire → view-model                                  |
| `src/hooks/use<Screen>.ts`                       | New React Query hook                                            |
| `src/components/<area>/<Kind>Section.tsx`        | New section components (one per kind)                           |
| `src/components/<area>/<area>SectionRegistry.ts` | `SectionRegistry` (kind → component map)                        |
| `src/components/<area>/index.ts`                 | Barrel — export sections + registry                             |
| `src/screens/<Name>/<Name>Screen.tsx` + `index.ts` | Screen entry point — the screen only; its components go in `src/components/<area>/` (tech-dna §1b) |
| `src/navigation/RootNavigator.tsx`               | Add nav entry                                                   |
| `src/navigation/types.ts`                        | Add param type                                                  |
| `src/mocks/<area>.ts`                            | Typed fixture (mock mode) or sample-response fixture (api mode) |
| `__tests__/hooks/use<Screen>.test.ts`            | Hook unit test                                                  |
| `__tests__/mappers/map<Screen>.test.ts`            | Mapper unit test                                                |
| `__tests__/screens/<Name>/<Name>Screen.test.tsx`      | Screen loading / error / empty branch tests                     |

### Track 2: Rebuild existing screen

1. Fetch new Figma node; compare sections against the existing `src/components/<area>/<area>SectionRegistry.ts`.
2. For each section: **keep** (no change), **restyle** (update component only), **replace** (new component + registry swap), **add** (new), **remove** (delete + registry removal).
3. Update `src/schemas/<area>.ts`, `src/mappers/map<Screen>.ts`, and the fixture to match changes.
4. **Report exactly which files changed and why** (per CLAUDE.md "call out which files changed" rule).

### Track 3: Add one section

Touches exactly the minimum set:

| File                                             | Action                                               |
| ------------------------------------------------ | ---------------------------------------------------- |
| `src/schemas/<area>.ts`                          | Add entry for the new `kind`                         |
| `src/mappers/map<Screen>.ts`                       | Add mapper fn for the new `kind`                     |
| `src/components/<area>/<Kind>Section.tsx`        | New section component                                |
| `src/components/<area>/index.ts`                 | Export the new component via the barrel              |
| `src/components/<area>/<area>SectionRegistry.ts` | One new line — `'<kind>': <Kind>Section`             |
| `src/mocks/<area>.ts`                            | Add fixture block for the new section                |
| `__tests__/`                                     | Mapper test + component render test for the new kind |

### Track 4: Standalone component

Creates a variant-driven component with no data layer:

| File                                   | Action                        |
| -------------------------------------- | ----------------------------- |
| `src/components/core/<name>/<Name>.tsx` (app-agnostic) or `src/components/common/<Name>.tsx` (app-level, shared by 2+ screens) — tech-dna §1b | Component with `variant` prop |
| same folder: `styles.ts` (only if styles are split out) | `useThemeStyles` stylesheet   |
| the folder's `index.ts`                | Export via barrel             |
| `__tests__/components/<name>.test.tsx` | Render tests per variant      |

## Shared process

For build conventions (theme-token mapping, vertical-slice anatomy, `useThemeStyles` + variant
pattern, image handling, CTA link handling, test patterns), read
[`references/conventions.md`](references/conventions.md).

### 1. Extract from Figma

Use the Figma MCP to fetch the node. Pull: auto-layout → flexbox, text styles, colors,
spacing, typography, and asset exports. **The node specs are the source of truth** for every
value; the screenshot is only for understanding the layout (tech-dna §9).

### 2. Map to theme tokens — flag gaps

For every raw Figma value, find the token in `src/theme` (`spacing`, `typography`, `colors`)
whose value **exactly** matches. Rules:

- Exact token match → use the token. No hardcoded values.
- No exact match → **ask the user**: add a new token, or use the exact value with a node-id
  comment. Never silently use the nearest token (tech-dna §9).
- Hex-only for any colour (no `rgba()`, no named colours).

Token gaps are surfaced as questions during this step, not listed only at the end.

### 3. Define view-model + decide wire shape

From the design, derive the **view-model** (durable, independent of the API).
Then decide the wire shape:

- **Api mode:** use the provided contract exactly.
- **Mock mode:** write a thin provisional guess, marked with the banner
  `// PROVISIONAL — reconcile with real contract` at the top of the schema, mapper, and fixture files.

### 4. Build presentation-only components

- Components receive view-model props; they contain no fetch logic.
- Style via `useThemeStyles` + variant pattern (see `references/conventions.md`).
- Reuse `src/components/core/` and `src/components/common/` before writing anything new, and never use a React Native primitive where the project has a component (tech-dna §1b). Close but not quite? Add a `variant`.
- CTAs go through the app's one link parser / link-handler hook (tech-dna §10a).
- Media: width from the screen, height from `aspectRatio`; images take `renderWidthDp` (tech-dna §11a). Bottom-pinned UI respects the safe-area inset (tech-dna §7a); tappables have accessibility labels where the text isn't enough (tech-dna §8c).
- Section dispatch uses the `SectionRegistry` map — **never a `switch`**.
- Unknown section kinds no-op with a `__DEV__` warning.

### 5. Wire the data path

**Mock mode (`USE_MOCK`):**

- Commit a typed TypeScript fixture to `src/mocks/<area>.ts` (exported via `@/mocks`).
- The fetch function branches on the `USE_MOCK` config key and loads the fixture lazily inside that branch (tech-dna §1a).
- Mirror the pattern in `fetchPageSections.ts`.

**Api mode:**

- Call the project's boundary fetcher (`boundaryFetch(request, schema, vars)`) with the real contract.
- The sample response from the contract becomes the Jest fixture directly.

### 6. Tests (mandatory)

Tests live under `__tests__/` mirroring `src/`. Required per CLAUDE.md:

- `__tests__/mappers/map<Area>.test.ts` — mapper unit test
- `__tests__/hooks/use<Area>.test.ts` — hook unit test
- `__tests__/screens/<Name>/<Name>Screen.test.tsx` — loading / error / empty branch
- Any util touched by this work must have a test

Mock at the boundary (the boundary fetcher; native modules) — never mock internal modules.
Mock the hook barrel path (`@/hooks`) in screen tests.

## Mapper-as-firewall

The mapper is the firewall between the API's wire shape and the app's view-model.

**Durable (derived from Figma — does not move when the API changes):**

- View-model types
- Section components and their props
- `SectionRegistry` and dispatch
- Component tests

**Provisional (flagged — changes are contained here when the real contract lands):**

- Zod schema (`src/schemas/<area>.ts`)
- Mapper function (`src/mappers/map<Screen>.ts`)
- Fixture (`src/mocks/<area>.ts`)

Every provisional file starts with:

```ts
// PROVISIONAL — reconcile with real contract
```

When the real contract arrives, only these three files change. Components, view-model,
registry, and their tests do not change. That is the firewall.

## Definition of done

1. `yarn typecheck` — green.
2. `yarn lint --max-warnings=0` — green.
3. `yarn test` — green, including all new mapper / hook / screen tests.
4. Self-review of the built UI against the Figma node data (and the screenshot for overall layout) —
   confirm layout, spacing, colors, and typography match, and that nothing breaks `docs/tech-dna.md` §16 (Forbidden).
5. Output a summary listing:
   - **Every file changed** (created / modified / deleted), with a one-line reason.
   - **Token gaps** — any Figma value that had no matching theme token, and what was done.
   - **Provisional-wire flags** — all files carrying the `PROVISIONAL` banner, to be
     reconciled when the real contract lands.
6. Docs updated proportionally:
   - New screen → add or update the relevant section in `docs/architecture/`.
   - New reusable pattern or significant decision → new ADR under `docs/decisions/`.
   - No new screen or decision-level change → no doc update required.
7. **No auto-commit.** The skill stops after the summary. The user bundles and commits.

## Example usage

Template:

```
/figma-to-ui
Task: <new screen | rebuild existing screen | add one section | standalone component>
Target: <name>
Figma node: <Dev Mode link or node id>
Screenshot: <attach>
Backend: <not ready — build on mock | ready — contract below>
Instructions: <intent, what changed, reuse notes, edge cases>
```

Homepage rebuild example:

```
/figma-to-ui
Task: rebuild existing screen
Target: Home screen
Figma node: https://www.figma.com/design/<fileKey>/MyApp?node-id=1234-5678&m=dev
Screenshot: [paste new homepage screenshot]
Backend: not ready — build on mock (USE_MOCK path)
Instructions: Reconcile against existing Home sections; keep matches, restyle/
replace changed, add new. Keep schema+mapper+fixture provisional (flagged);
durable work in view-model + components. Wire real contract tomorrow.
```
