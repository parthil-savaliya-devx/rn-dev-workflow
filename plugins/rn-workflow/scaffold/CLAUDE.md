# `<FILL IN — App name>`

`<FILL IN — one-line description>`. React Native CLI app. `<FILL IN — RN/React versions, and the backend boundary, e.g. "All data is served by a custom middleware (App → Middleware → downstream)".>`

> **Scaffolded from the `rn-workflow` plugin (uniform baseline).** The Hard Rules and Traps below are the generic, non-negotiable index every project shares; the detail lives in [`docs/tech-dna.md`](docs/tech-dna.md). Fill the `<FILL IN>` slots (app name, backend boundary, env keys, subsystem map, dependencies) for this project. Add project-specific rules as you go — record any deviation from a baseline choice as an ADR.

**This file is the index: rules and traps only. [`docs/tech-dna.md`](docs/tech-dna.md) is the detail** — the canonical, copy-me patterns for all generated code. **Read it before writing any code.** Copy those patterns rather than inventing a style; a pattern with no precedent there is added to it in the same PR (tech-dna §17). `dna §N` below points into it.

**Keep this file compact — it is loaded into every session.** New detail belongs in tech-dna, an ADR, or `docs/architecture/`, with at most a one-line pointer here. Add a line here only for a rule that must never be missed or a failure that is silent.

Where to look: **patterns/how-to** → tech-dna · **why a choice was made** → `docs/decisions/` · **how a subsystem fits** → `docs/architecture/` · **a procedure** → `docs/runbooks/` · **what exists / where** → `graphify query "<question>"` (if the graph exists).

## Hard Rules

- **One data boundary.** Every read/write goes through the single boundary fetcher (`<FILL IN — your client>`) → Zod → mapper → view-model. Never call a third party directly. Every request has a timeout, is authenticated by default (`skipAuth` for public/auth calls), and never puts a query string into an error (dna §3, §23).
- **Every fetch passes a Zod schema** (`z.unknown()` is the only, review-visible opt-out) that declares only the fields the app reads. The **mapper is the firewall** — wire→view-model transforms live there, declared as a `type→fn` map, **never a `switch`**.
- **Config-driven, never name-driven** rendering. Branch layout on config flags via the shared `SectionList` + per-screen `SectionRegistry` (O(1) map dispatch); `kind === wire type`.
- **Ask, don't assume.** Anything unclear — requirement, design intent, API behaviour, edge case — STOP and ask the human (batched), and build exactly to the clarification. Never guess and build.
- **Human verification precedes every commit** (dna §17a). Change → green bar → drive the real app → present and wait → commit on approval → push only when the whole change is approved. Never commit as you go.
- **Figma from node specs, never screenshots** (dna §9) — `get_metadata` → `get_design_context`, exact values, cite the node id in a comment (use the `figma-to-ui` skill). Never substitute the "nearest" token when the value differs.
- **Styling** (dna §8): theme tokens first; **hex only** (`#RRGGBB`/`#RRGGBBAA`, `withAlpha`); `spacing.*` + `typography.*` tokens (no scaling helpers); **weight-by-family, never `fontWeight`**; prefer `BaseText`; no inline `style={{}}`; no anonymous fns in JSX props (except per-iteration list closures). A colour literal in a screen/component is a defect — add a token.
- **Tappables use the shared `Pressable`**, never `react-native`'s (it has no pressed state). **Animation is Reanimated, never RN `Animated`** (thread hops via `scheduleOnRN`). **Every bottom sheet renders through the shared `BottomSheet` shell** (dna §8, §11b, §19).
- **Low-memory phones first** (dna §11): most users are on 2–4 GB RAM Android phones — every screen must be smooth there. Virtualised lists (never a vertical list inside a vertical `ScrollView`; stable id keys), light rows, right-sized images, unmount off-screen video/maps, animate only `transform`/`opacity`, one shared double-tap guard on submit/pay buttons, test on a real low-end device with worst-case data.
- **Media is sized dynamically** (dna §11a): width from `useWindowDimensions()` minus layout spacing, height from the contract's `aspectRatio` (fallback ratio constant) — never a hardcoded size or `height`. The shared image component takes the slot width as a required `renderWidthDp`. Bundled rasters are **WebP** (dna §8a).
- **Accessibility** (dna §8c): every tappable has a role, a label when its text isn't enough (icon buttons), and its state; touch targets ≥ 44×44 (`hitSlop`); decorative images hidden; important changes announced; screens work at the largest system font (no app-wide `allowFontScaling={false}`, no fixed heights on text). Check new screens with TalkBack / VoiceOver.
- **Edge-to-edge, gesture and 3-button navigation** (dna §7a): content and controls stay clear of the status bar and the navigation bar — insets from `react-native-safe-area-context`, never hardcoded; bottom-pinned bars pad `Math.max(insets.bottom, spacing.lg)`; inside a `Modal` use its own nested `SafeAreaProvider` (dna §19).
- **Hardcoded data has one home** (dna §1a): static, no-API data → `src/constants/`; wire-shape fixtures for the `USE_MOCK` path → `src/mocks/` (schema-validated, loaded lazily). Never inline either in a component.
- **TypeScript strict — no `any`, no `@ts-ignore`, no non-null `!`.** `type` not `interface`; no `enum` (unions / `as const`); `import type` for types; `??` not `||`; `async/await` with `Promise.all` for independent calls; never a fake id like `''`/`'0'`; components and hooks are arrow functions (dna §2). `@/` alias imports; barrel per folder — **except shared infrastructure, which imports leaf files** (dna §1); defensive access on API fields, normalised in the mapper.
- **React & hooks** (dna §2a): derive values during render (no state-copying effects); user actions in event handlers, not effects; every listener/timer effect cleans up; reset state with `key`; never silence `exhaustive-deps` without a comment; never define a component inside another; subscribe low with one selector per value.
- **Screens = UI only** — business logic belongs in hooks/services. Logic needed by two screens becomes one hook, not a copy.
- **Component structure** (dna §1b): core building blocks in `components/core/<name>/<Name>.tsx` (one folder each); shared by 2+ screens in `components/common/`; used by one screen in `components/<area>/`; the screen itself in `screens/<Name>/<Name>Screen.tsx`. **Reuse first** — never use a React Native primitive (`Text`, `Pressable`/`Touchable*`, `Image`, `Modal` for a sheet, raw `TextInput`) when the project has a component for it; add a `variant` instead of a near-copy.
- **State** (dna §5): a new persisted store MUST set `skipHydration:true`, be rehydrated in `App.tsx`'s `Promise.all`, carry an explicit `version` (+ `migrate` on any shape change), and use an **allow-list `partialize`** (never `...state`). **No token or password in a persisted store** — access token in memory, refresh credential in the Keychain (dna §23).
- **Config is read ONLY via `getConfig(key)` / `useConfig(key)`**, at call time, never at module load. `ENV.*` outside the key-declaration file is a defect; never `Config.` directly. **`.env.*` is not a secret store** — every key compiles into the binary (dna §12).
- **Links:** one parser for every source; `Linking.openURL` only via `openExternal` (scheme allow-list); never open your own domain externally; host checks never use `new URL()` (dna §10a, §22).
- **One service module imports each third-party SDK**; init is idempotent and never blocks boot. Before adding a dependency, check you need it, its size, and (native) New Architecture + Android 16 KB support; remove unused ones; upgrade React Native on its own, one version at a time (dna §25).
- **Every hook and util gets a unit test**; screens get loading/error/empty branch tests; **mock at the boundary** (the fetcher/native/SDK wrapper), never internal modules — and mocks never do more than the real platform can (dna §14).
- **Never swallow errors** (no empty `catch`, no failure-hiding fallback); user-silent failures still record a non-fatal (dna §13).
- **Docs ship in the PR** — ADR / architecture / runbook / glossary as the change requires (dna §15).
- **Lint clean means `yarn lint --max-warnings=0`** — that is what CI runs, so a _warning_ fails the build while plain `yarn lint` looks green.
- **`yarn check:env`** after any `.env.*` change. Full forbidden list: dna §16.
- `<FILL IN — project-specific hard rules, e.g. no parseFloat on money, checkout URLs only from API, light/portrait lock>`

## Traps — these fail silently

No error, no failing test; they surface as "it just doesn't work". The full index is dna §29.

- **`new URL()` on device is a regex polyfill and its `hostname` is exploitable** — `https://attacker.example/x@yourdomain.com` parses as `yourdomain.com`. Jest runs Node's correct `URL`, so tests never see it. Use the safe parser (dna §22).
- **A barrel import can bind a component to `undefined`, permanently** — an `export *` cycle; the error names an unrelated file (dna §1).
- **Zustand does not ignore unknown persisted keys** — a deleted field is shallow-merged back in and a spreading `partialize` re-writes it; an omitted `version` is `0` (dna §5).
- **MMKV ignores a new encryption key on an already-open store** — re-key with the instance API; a hex key is half-strength (dna §5).
- **A read in flight at logout writes the previous user's data back** — cancel and ignore late responses (dna §5, §23).
- **Absence of a credential is not evidence the session died** — end a session only on positive evidence; only a server rejection destroys a credential (dna §23).
- **A request with no timeout holds the skeleton forever** — React Query only retries after a failure (dna §3).
- **A GraphQL field/argument the live schema lacks rejects the whole operation**, and the mock path passes; **a 2xx doesn't prove a parameter was honoured** (dna §3a, §3b).
- **Read config at call time, not module load** — a captured value keeps the first-launch default all session (dna §12).
- **R8 strips `BuildConfig` in release** — every env value becomes `''` while the build succeeds (dna §21).
- **Navigating to a tab from a pushed screen needs `navigate('Tabs', { screen: X })`** — the bare form type-checks and no-ops (dna §10).
- **Warm-start deep links are dead** without the iOS `AppDelegate` URL forwarders and Android `onNewIntent` + `setIntent` — cold start still works, so QA passes (dna §10a).
- **`Linking.openURL` on a URL your own app claims loops back into the app** (iOS 14.2+) (dna §10a).
- **Play App Signing re-signs the AAB** — SHA-restricted services and App Links fail only for store installs; register both fingerprints (dna §21).
- **A gesture inside an RN `Modal` needs its own `GestureHandlerRootView`**, and a `Modal` paints above every in-window gate and the toast host (dna §19).
- **The app's safe-area insets don't apply inside a `Modal`** — without `navigationBarTranslucent` + a nested `SafeAreaProvider`, sheet buttons sit under the Android 3-button bar; gesture-nav phones hide the bug (dna §19, §7a).
- **`freezeOnBlur` does not unmount native views** — a screen pushed repeatedly from itself grows memory without bound (dna §11).
- **Android 12+ silently ignores a FINE-only location request** (dna §24).
- **Jest module mocking is path-exact** — mock the barrel (`@/hooks`) and import from that same path; `jest.mock` factories are hoisted, so variables inside must be `mock`-prefixed.
- **Matched native sets (Reanimated + worklets, …) are pinned to exact versions** — a `^` bump on one alone breaks the build.
- `<FILL IN — add each project-specific silent failure as you hit it: one line, with a pointer to the ADR/dna section>`

## Architecture — the data boundary

`<FILL IN>` — describe the single backend the app talks to and the rule that it never calls third parties directly. Keep the pipeline: **query/endpoint → boundary fetcher → Zod schema → mapper (firewall) → view-model → presentation-only component**. Config-driven rendering, never name-driven. See [`docs/tech-dna.md`](docs/tech-dna.md) §0, §3, §6.

## Commands

Use **Yarn Classic** for everything (adjust if this project uses npm/pnpm).

```bash
yarn install                     # install deps (then `cd ios && bundle exec pod install`)
yarn start                       # start Metro
yarn ios:dev                     # run iOS (dev scheme) — always use the aliases, never bare run-ios
yarn android:dev                 # run Android (dev variant)
yarn lint --max-warnings=0       # eslint — the flag is what CI runs
yarn typecheck                   # tsc --noEmit
yarn test                        # jest
yarn check:env                   # .env.* key parity with .env.example + APP_ENV matches filename
```

`<FILL IN — your full scheme/flavour aliases (ios:stage, android:prod, release variants), signing verification, and any codegen/e2e scripts>`

## Folder Structure

```
src/
  components/   core/<name>/ (one folder per building block) · common/ (shared by 2+ screens)
                sections/ · <area>/ (components for one screen, e.g. cart/, home/)
  screens/      <Name>/<Name>Screen.tsx + index.ts — the screen only
  navigation/   RootNavigator + typed ParamLists + link parser
  hooks/        query + behaviour hooks (every hook has a test)
  services/     boundary fetcher, queryClient, errors, one wrapper per SDK
  store/        Zustand stores + MMKV adapter
  schemas/      Zod wire-shape schemas
  mappers/      wire→view-model mappers (the firewall)
  utils/        pure functions (every util has a test)
  constants/    config keys + static data
  mocks/        USE_MOCK wire-shape fixtures
  theme/        design tokens
  types/        shared view-model + domain types
  assets/       images (WebP), fonts, svgs
```

Every folder has a barrel `index.ts`. Full anatomy: [`docs/tech-dna.md`](docs/tech-dna.md) §1.

## Subsystem map

`<FILL IN — the table of subsystems as they land, linking each to its docs/architecture/NN-*.md file.>`

| Subsystem | Path | Docs |
| --------- | ---- | ---- |
| AI dev workflow | `.claude` / plugin | [architecture/18-ai-dev-workflow.md](docs/architecture/18-ai-dev-workflow.md) |
| `<subsystem>` | `src/...` | `docs/architecture/NN-...md` |

## Conventions

- **TypeScript everywhere** — no `any` (`"strict": true`).
- **Path aliases** — all `src/` imports use `@/...`.
- **Barrels** — every `src/` folder exports through its `index.ts`; shared infrastructure imports leaf files.
- **Screens = UI only** — business logic in hooks/services.
- **Colors: hex only**, theme tokens preferred; `withAlpha` for alpha.
- **Fonts: weight via family**, never `fontWeight`.
- **Prefer `BaseText`** over raw `<Text>` for themed copy.
- **Map over `switch`** for type/`kind` dispatch.
- **Defensive field access** on API-sourced fields; normalize in the mapper.
- **Comments carry signal, not narration** — a `TODO`/`FIXME`, a known risk, a non-obvious constraint, or a traceability note (Figma node id). Never restate what the code does.
- **One mechanism per job** — one rail, one image component, one sheet shell, one toast host, one link parser.
- **Single-importer SDKs** — change each in one place: `<FILL IN — e.g. haptics → utils/haptics.ts · crash reporting → services/errorReporting.ts · analytics → services/analytics/>`.
- Full detail + rationale: [`docs/tech-dna.md`](docs/tech-dna.md).

## Testing

- Jest + `@testing-library/react-native`. Tests in `__tests__/` mirroring `src/`.
- **Every hook and util has a unit test.** Screens: loading/error/empty branch tests minimum.
- **Mock at the boundary** (the fetcher / native modules / SDK wrapper) — never internal modules.
- See [`docs/tech-dna.md`](docs/tech-dna.md) §14 — including the list of what Jest cannot see.

## Documentation

Docs ship in the PR (tech-dna §15): new decision → an ADR (`docs/decisions/` — check the highest number on the base branch first); new subsystem → `docs/architecture/`; new env key → the environments doc + `.env.example`; new term → `docs/glossary.md`; new pattern → `docs/tech-dna.md`; new silent failure → a line in **Traps** above.

## Tooling

`<FILL IN — ESLint config, Prettier, husky hooks, Node pin (.nvmrc), CI gates (lint --max-warnings=0, typecheck, test, secret scan, dependency audit)>`

Baseline stack: `@react-navigation/*` + `react-native-screens` · `zustand` + `react-native-mmkv` · `@tanstack/react-query` · `zod` · `@shopify/flash-list` · `react-native-config` · `react-native-reanimated` + `react-native-worklets` + `react-native-gesture-handler` · `react-native-safe-area-context` · `react-native-keyboard-controller` · `react-native-keychain` · `<FILL IN — your optional integrations>`.

## Knowledge Graph — graphify (optional)

If this repo ships a `graphify` knowledge graph at `graphify-out/`, prefer `graphify query "<question>"` over grepping raw source for codebase questions. Build it once with `graphify update .` on a fresh clone.

## PR trailer

`<FILL IN — the required commit/PR trailer for this repo, if any.>`
