# Tech DNA — Canonical Code Patterns

> This is the project's coding genome. Every feature **and every bugfix** is written by **copying these patterns**, never by inventing a new style per requirement. If a task needs a pattern with no precedent here, establish it deliberately and **add it to this file in the same PR** (§17) — the DNA evolves, it is never bypassed. This file is reviewed like code: it is the reason two features written months apart read like they were written by the same hand.
>
> **Read this before writing any code.** It is the "how"; [`../CLAUDE.md`](../CLAUDE.md) is the map and the hard-rules index; the [ADRs](decisions/README.md) are the "why"; [`architecture/`](architecture/README.md) is the per-subsystem detail. When this file and a snippet in the codebase disagree, the codebase wins — fix this file in the same PR.
>
> ---
> **📌 Scaffolded from the `rn-workflow` plugin — this is the UNIFORM BASELINE, identical in every new project.** Its purpose is that every app starts from the same genome so they all read alike. The concrete choices below (Zustand + MMKV, React Query, Zod, FlashList, `useThemeStyles`/`BaseText`, the folder layout, the data pipeline) are the recommended uniform starting point.
>
> **Devs extend it per project — that is expected, not a violation.** Sections marked **`<FILL IN>`** are the deliberately-blank slots for project specifics (the backend boundary, env keys, fonts/brand tokens, currency, third-party integrations). Fill those before your first feature; add new `§` sections as the project grows (§17); swap a baseline choice only with an ADR recording why. Delete any section that genuinely doesn't apply. Once filled in, delete this banner.

## 0. The data boundary

**`<FILL IN — your single data boundary>`** — describe the one client every read/write goes through, and the rule that the app never calls a third party directly.

_Reference shape (this genome's origin project used middleware-only over GraphQL):_

```
App → <your backend boundary> → downstream services
```

Every read/write goes through one boundary fetcher (§3). Do not add direct third-party integrations. Rendering is **config-driven, never name-driven**: UI adapts from API config flags (`layout_style`, `mobile_layout`, …), never from section/instance names (§6).

## 1. File & folder anatomy

Everything lives under `src/`, and **every folder has a barrel `index.ts`** (match its existing re-export style when editing). Imports across `src/` use the `@/` alias — never deep relative paths (`../../..`).

```
src/
  components/
    common/       shared presentational primitives (BaseText, variant-driven cards, rails)
    core/         generic primitives (FastImage, Button)
    sections/     generic SectionList + SectionRegistry infra (screen-agnostic)
    <area>/       per-screen section renderers + area components
  screens/<Name>/ one folder per screen (§7)
  navigation/     RootNavigator + typed ParamLists + intent queue
  hooks/          query hooks + screen/behaviour hooks (every hook has a unit test — §14)
  services/       boundary fetcher, queryClient, errors, platform inits
  store/          Zustand stores + MMKV storage adapter
  schemas/        Zod wire-shape schemas (one file per area)
  mappers/        wire→view-model mappers (the firewall — §3)
  graphql/        queries/ mutations/ fragments/  (plain tagged template strings) — if GraphQL
  utils/          pure functions (every util has a unit test — §14)
  constants/      static, no-API data + env/brand/rc-keys (§1a)
  mocks/          wire-shape fixtures for the USE_MOCK offline/test path (§1a)
  theme/          design tokens (colors, spacing, typography, fonts) — §8
  types/          shared view-model + domain types
  assets/         images, fonts, svgs
```

- File name matches its main export (`BaseText.tsx` exports `BaseText`; `mapHomepage.ts` exports `mapHomepage`).
- A screen's pieces live **beside the screen** until a second screen consumes them. Generic section infra is the exception — it lives in `components/sections/` because it is screen-agnostic.
- Import order (ESLint-enforced, autofixed): external (react/react-native first) → builtin → internal `@/**` → parent/sibling → type; alphabetised, newline between groups.

### 1a. Static & mock data — where hardcoded data lives (HARD RULE)

Hardcoded data is **never inlined in a screen/component**. It lives in one of two homes by whether the backend will ever own it:

- **Genuinely static, no-API data → `src/constants/`.** Presentational data the backend will _never_ serve — category handles, swatch placeholders, support links, brand strings, size charts — is a typed constant, exported through the barrel and imported via `@/constants`. A magic string/array/number inline in JSX that represents such data is a defect — extract it. When a value later becomes contract-backed, its single home moves to the mapper/schema, not scattered call sites.
- **Wire-shape fixtures for the offline/test path → `src/mocks/`.** Data that _stands in for a real API response_ (so the app runs with `USE_MOCK` on and tests never hit a live server) mirrors the exact wire shape, is **validated by the same Zod schema** as the live response, and lives in `src/mocks/`. Fetchers select it via `getConfig('USE_MOCK')` (§3). These are temporary stand-ins for a contract — not static constants.

Rule of thumb: _"Will this ever come from the backend?"_ — **yes → a `src/mocks/` fixture** (schema-shaped); **no → a `src/constants/` constant** (view-model-shaped).

## 2. Naming & TypeScript

| Thing | Convention | Example |
| ----- | ---------- | ------- |
| Screen component | PascalCase + `Screen` suffix, **named** export | `HomeScreen`, `PLPScreen` |
| Component | PascalCase, named export; props type `<Name>Props` exported | `ProductCard`, `ProductCardProps` |
| Query/fetch hook | `use<Domain>` (mounted) + `fetch<Domain>` (fetcher) | `useHomepage` / `fetchPageSections` |
| Behaviour hook | `use` prefix, camelCase file | `useWishlistActions.ts` |
| Store | `use<Domain>Store` in `<domain>Store.ts` | `useAuthStore`, `useWishlistStore` |
| Mapper | `map<PascalCaseWireType>` | `mapHomepage`, `mapProductContent` |
| Section kind / component / mapper | `kind === wire type` (kebab); component `PascalCase(type)+Section`; mapper `map+PascalCase(type)` (§6) | `category-tiles` → `CategoryTilesSection` / `mapCategoryTiles` |
| Query key | tuple array, namespaced, params appended | `['homepageByHandle', slug]` |
| testID | kebab-case `<screen>-<element>` | `home-tab-men`, `plp-sort-button` |

TypeScript: **`strict` is on — no `any`, no `as never`.** Prefer typed declarations over `as` assertions. Use **defensive field access** (optional chaining / nullish defaults) for any API-sourced field that could be absent — even one the schema currently requires — and normalise it in the mapper so components receive clean data.

## 3. Data layer — the boundary pipeline (HARD RULE)

Every screen's data follows the same one-way pipeline. Each stage has one job; **the mapper is the firewall** — when the wire shape changes, only the schema, mapper, and mock move; view-model types, components, and the registry stay put.

```
<query/endpoint>   →   fetch<X>()                          →   use<X>()
  (request only)        boundaryFetch(request, schema, vars)     useQuery(options)
                        → Zod schema (schemas/<area>.ts)
                        → mapper (mappers/map<X>.ts)
                        → view-model type (types/)
                        → presentation-only component
```

**The boundary fetcher** — one client for all app data, validates the response against a Zod schema, throws typed errors:

```ts
// src/services/<boundary>Fetch.ts (shape)
export async function boundaryFetch<S extends z.ZodType, V = …>(
  request: string, schema: S, variables?: V, signal?: AbortSignal,
): Promise<z.infer<S>> {
  const url = `${getConfig('API_BASE_URL')}/…`;
  const response = await fetch(url, { /* method, headers, body */ signal });
  if (!response.ok) throw new BoundaryHttpError(response.status, url);
  const json = await response.json();
  const parsed = schema.safeParse(json.data ?? json);
  if (!parsed.success) throw new ResponseValidationError(url, parsed.error.issues);
  return parsed.data;
}
```

**The fetcher** — mock-aware, unwraps any success envelope, returns a view-model. Copy-me shape for every screen fetcher:

```ts
// src/hooks/fetchPageSections.ts
export async function fetchPageSections(slug: string): Promise<HomeSection[]> {
  const data = getConfig('USE_MOCK')
    ? homePageSchema.parse(homePageContentMock) // offline/test path
    : await boundaryFetch(PAGE_SECTIONS_QUERY, homePageSchema, { slug });

  const { success, error } = data.pages; // surface a failure envelope
  if (!success) throw new Error(error?.message ?? 'Page request was unsuccessful');

  return mapHomepage(data); // firewall: wire → view-model
}
```

Rules:

- **Every fetch MUST pass a Zod schema.** The only visible opt-out is `z.unknown()` — its presence in a diff flags a deliberate skip for review.
- Schemas validate the **wire shape** and live in `src/schemas/<area>.ts`. Wire types are exported from there (`z.infer`).
- **Mapping lives in the mapper**, declared once. Normalise dimensions, links, colours, and layout defaults there — never in components. Map over a **`type → mapperFn` map, never a `switch`**; unknown types are dropped in the mapper (§6).
- `getConfig('USE_MOCK')` gates the offline path. Tests run with `USE_MOCK` on and never hit a live server (§14).

### 3a. GraphQL text organization — `<FILL IN / DELETE if not GraphQL>`

If the boundary is GraphQL: all query/mutation text lives only under `src/graphql/` (`queries/`, `mutations/`, `fragments/`), as plain tagged template strings (`/* GraphQL */` for editor highlighting) — no Apollo, no codegen. Shared selections are **plain string constants** (`IMAGE_FIELDS`, `PRODUCT_CARD_FIELDS`) interpolated into queries — **not** `fragment ... on Type` declarations (a wrong type name passes every offline test then 400s the whole live query). Add a real named fragment only for a verified, stable server type.

## 4. React Query pattern

`queryClient` is **cache-first**: global `staleTime 3min`, `gcTime 10min`, `retry 2`, `refetchOnWindowFocus:false`, `refetchOnMount:false` — revisiting a screen renders cached data instantly, no skeleton flash. Freshness comes from `staleTime` expiry and explicit pull-to-refresh.

- **Share one query-options factory** between the hook and any prefetch so key + queryFn + staleTime match exactly:

  ```ts
  function homepageQueryOptions(slug: string) {
    return {
      queryKey: ['homepageByHandle', slug] as const,
      queryFn: () => fetchPageSections(slug),
      staleTime: 60_000, // per-hook override of the 3min default
      placeholderData: (prev: HomeSection[] | undefined) => prev, // keep prior data on key change
    };
  }
  export const useHomepage = (slug = 'home') => useQuery(homepageQueryOptions(slug));
  export const prefetchHomepage = (qc: QueryClient, slug = 'home') =>
    qc.prefetchQuery(homepageQueryOptions(slug));
  ```

- **Query keys are namespaced tuple arrays** — `['product', handle]`, never template-string keys.
- Data-screen hooks set `placeholderData: (prev) => prev` so a key change (segment/filter/pagination) keeps previous data on screen instead of flashing a skeleton.
- Override `staleTime`/`refetchOnMount` per hook **only with an inline comment** citing the reason.
- **Every data screen wires pull-to-refresh:** `<RefreshControl refreshing={isRefetching} onRefresh={refetch} />`.
- **Every hook in `src/hooks/` has a unit test** (§14).

## 5. State — Zustand + MMKV

MMKV is constructed at boot with a 32-byte key from Keychain (`bootstrapStorage()`). Stores use the `zustandMMKVStorage` adapter.

```ts
// src/store/authStore.ts — the canonical persisted store
export const useAuthStore = create<AuthState>()(
  persist(
    set => ({
      token: null,
      isAuthenticated: false,
      setAuth: token => set({ token, isAuthenticated: true }), // intention-named action
      clearAuth: () => set({ token: null, isAuthenticated: false }),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => zustandMMKVStorage),
      skipHydration: true, // FOOTGUN rule 1 — see below
    },
  ),
);
```

**Adding a persisted store is a footgun — both rules are mandatory or the adapter throws at boot:**

1. `skipHydration: true` in the `persist(...)` options (MMKV is `null` until `bootstrapStorage()` resolves; auto-hydration fires at module load and would throw).
2. Add `await useXStore.persist.rehydrate()` to the `Promise.all([...])` in `App.tsx`'s bootstrap effect. The render tree is gated on `storageReady` until all rehydrates resolve.

Other rules:

- **Intention-named actions** (`setAuth`/`clearAuth`), never a generic `setState`-style mutator.
- **Narrow selectors** in components — `useStore(s => s.action)`, not the whole store.
- Outside React (services, navigation listeners, helpers): `useXStore.getState()` — never call a hook outside a component.
- Server-truth data that a query owns belongs to React Query, not a store. Ephemeral UI state (toasts) is a non-persisted store.

## 6. Config-driven section rendering (HARD RULE)

Page layouts arrive as an ordered list of **sections**, each with a `type` + config. Zod-validate → map to view-model sections discriminated by `kind` → render with the shared generic renderer.

- **One shared renderer, one registry per screen.** `<SectionList sections registry gap>` owns dispatch, keying, inter-section spacing, and the unknown-kind no-op **once**. Each screen supplies a `SectionRegistry<S>` mapping `kind → component`.
- **Dispatch is an O(1) map lookup — never a `switch`.** Unknown kinds no-op with a `__DEV__` warning so the backend can ship a new type before the app implements it.
- **Config-driven, never name-driven.** Branch layout on config flags (`layoutStyle: 'carousel' | 'grid'`), never on instance/section names.
- **`kind === wire type`**: the wire `type` string is the search entry point — grepping it must lead straight to schema → mapper → component. Never rename wire→purpose.

```ts
export type SectionRegistry<S extends RenderableSection> = Partial<{
  [K in S['kind']]: ComponentType<{ section: Extract<S, { kind: K }> }>;
}>;
// dispatch: registry[section.kind] ?? __DEV__ warn + null
```

## 7. Screen pattern

Screens are **UI + wiring only**; data/business logic lives in `@/hooks`. A screen composes hooks, holds only view-local UI state (a selected segment, a scroll ref), and renders. There is **no mandated N-file split** — group a screen's pieces by role beside it.

```
src/screens/Home/
  HomeScreen.tsx          orchestrates: reads route, holds UI state, calls useHomepage, renders
  HomeSectionsView.tsx    the list/scroll body + RefreshControl + SectionList
  HomeScreenSkeleton.tsx  loading state that mirrors the above-the-fold layout (no CLS)
  index.ts                barrel
```

- **Loading / error / empty are explicit branches**, each testable (§14). Loading states mirror the real layout (reserve media boxes by `aspectRatio`) so content doesn't jump.
- **No runtime media measurement** — never drive layout from `Image.getSize` or video `onLoad`. Dimensions come from the contract (or a hardcoded fallback constant in the mapper) and are set once on the view-model.
- Route params are typed from the ParamLists (§10) — never `any`, never untyped `route.params`.

## 8. Styling & theme (zero exceptions)

- **Colours come ONLY from theme tokens — a colour literal in a screen/component is a defect (HARD RULE).** Never write a hex/`rgba()`/named colour in `src/screens/` or `src/components/`. Every colour is `colors.<token>` (via `useThemeStyles`). **Before adding a colour, find the existing token**; **only if none matches, add a new token** (hex-only: `#RRGGBB`, or `#RRGGBBAA` for alpha — no `rgba()`, no named colours) with a comment citing its Figma source. Need alpha on an existing token? `withAlpha(colors.<token>, 'AA')` — never inline a literal. This includes scrims/overlays (use `colors.overlay` or add a scrim token).
- **Spacing & typography come from token sets**, not a scaling function: `spacing.*` and `typography.*` tokens. **There is no `moderateScale`/`horizontalScale` system — do not introduce one.**
- **Fonts: weight is carried by the family, never `fontWeight`.** Bundled brand fonts are one static face per weight — select weight via `fontFamily.bold` / `fonts.sans.medium`, never `fontWeight` (Android ignores it for bundled fonts; on iOS the named face already _is_ that weight). `<FILL IN — your font families + weights, and any SemiBold gap>`.
- **Prefer `BaseText` over raw `<Text>`** for themed copy — it takes a `variant` (typography token) + `color` (theme token). Drop to raw `<Text>` only where no theme styling applies.

  ```tsx
  <BaseText variant="brandBodySmall" color="textSecondary">{title}</BaseText>
  ```

- **Themed styles → `useThemeStyles`** (memoised style factory); truly static never-themed styles → module-level `StyleSheet.create`. Never inline `style={{}}` object literals; never anonymous functions in JSX props (except per-iteration list closures — §11).
- **Sizing: prefer padding over fixed `width`/`height`** for content/text containers. Reserve explicit dimensions for media / known-aspect boxes.
- **`<FILL IN / DELETE — CDN image optimization>`:** if your images come from a CDN with URL transforms (e.g. Shopify), apply the optimization **once at the shared image-component boundary**, so mappers pass raw URLs. Widths come from the contract or a default, never runtime measurement.
- **`<FILL IN — theme/orientation lock>`:** e.g. light-only + portrait-only. Delete if the app supports dark mode / rotation.

## 9. Figma → UI (HARD RULE)

Figma-sourced UI is built from **node specs, never screenshots**. Before implementing or changing any screen/component with a Figma reference:

1. Pull the exact specs for the **specific node** via the Figma MCP — `get_metadata` to find the node, then `get_design_context` — and use its exact values: font size / line-height, paddings, gaps, icon sizes, hex colours. Use the `figma-to-ui` skill.
2. Screenshots are for layout comprehension only. A measurement read off a screenshot ("looks like 14px") is a defect waiting to ship.
3. Never substitute the "nearest" token when the value differs — **add a token** or use the exact raw hex with a comment naming the node.
4. **Cite the node id in a style comment** so the next diff is verifiable.
5. If a plan defers "exact styling to visual QA", that is a planning bug — specs are fetched **during** implementation.

## 10. Navigation (React Navigation v7)

- Route params typed in `src/navigation/types.ts`: `TabParamList`, `RootStackParamList`, and a flattened `AppParamList` (augments `ReactNavigation.RootParamList` so every `navigate(...)` stays typed).
- **Imperative navigation from non-component code** (services, push handlers, deep links) goes through an exported `navigationRef` + a link-intent queue — never smuggle a `navigation` object into a store. CTA/deep links are parsed by one link parser (product → PDP, collection → PLP, page → Page; external → `Linking.openURL`).
- **Non-reactive `initialRouteName`:** when the initial route depends on persisted state, read it **once** at mount (`useState(() => …getState())`), not via a reactive selector — a reactive read would swap the route mid-session.

## 11. Performance

- Repeating/scrollable content uses **`@shopify/flash-list`**, never `products.map()` in a `ScrollView`. Every horizontal product carousel uses one shared **rail** component — callers pass `products`/`onPressProduct`/`variant`, the rail owns list + card + spacing.
- Add `React.memo` **only for a measured rail/list re-render problem**, with a comment. Do not blanket-memo every component.
- **No anonymous functions or fresh object/array literals in JSX props** — extract to `useCallback`/named handlers/`useMemo`. **Exception:** callbacks closing over a per-iteration variable in a list (`onPress={() => onSelect(v.id)}`).
- Keep `react-hooks/exhaustive-deps` ON.

## 12. Environment & runtime config

- `.env.dev`/`.env.stage`/`.env.prod` (gitignored) + `.env.example` (committed). Read env **only via `ENV`** from `@/constants`, never `Config` directly.
- **A new env key touches all of:** `src/constants/env.ts` + **every** `.env.*` including `.env.example`, then `yarn check:env`, then the environments doc. `react-native-config` reads values at **native build time** — driven by the iOS scheme / Android flavour, so run via the yarn aliases (`yarn ios:dev`, `yarn android:stage`), never bare `run-ios`.
- **`<FILL IN / DELETE — Remote Config>`:** if you use Remote Config, read RC-tunable values via `getConfig(key)` (sync) / `useConfig(key)` (reactive) — the canonical runtime path — not `ENV.*`. `ENV.*` stays the build-time fallback.

## 13. Error handling & feedback

- **Typed errors at the boundary:** an HTTP error (non-2xx), a GraphQL/`errors[]` error, and a `ResponseValidationError` (Zod mismatch). A `success:false` envelope is thrown as an `Error` in the fetcher so React Query shows the error UI and it reaches crash reporting.
- **Query/mutation errors handled at the hook level**; screens render error branches, they don't catch.
- **User feedback: a global toast** (`useToastStore.getState().show({ message, action?, icon? })`) — never `Alert.alert` for routine feedback. It is a FIFO queue.
- **Crash reporting:** `recordJsError(err)` (installed in `index.js` for global JS errors); risky trees are wrapped in an `ErrorBoundary`.
- **Never swallow errors** — an empty `catch`, a `.catch(() => {})`, or a fallback that hides failure is a defect. Where an abort is intentional, swallow the `AbortError` **explicitly, with a comment**.
- **Full-screen error/empty states are one reusable component driven by a preset registry** (icon/title/message/buttons), consumed in a screen's error/empty branch — never a per-screen inline block. Dispatch is a map, never a switch. A preset button whose action has no supplied handler is dropped, so each screen decides which buttons show by which handlers it passes.

### 13a. Money / commerce — `<FILL IN / DELETE if not a commerce app>`

- **No `parseFloat` on money**, no client-side price math, checkout URLs come **only from the API**.
- `formatMoney` currency policy: `<FILL IN — currency symbol, grouping, fraction-digit rule>`.

## 14. Tests

- **Jest + `@testing-library/react-native`.** Tests live in `__tests__/` mirroring `src/`. `jest.config.js` maps `@/*` → `src/*`.
- **Every hook in `src/hooks/` and every util in `src/utils/` MUST have a unit test** (keep `__tests__/hooks/` and `__tests__/utils/` mirroring `src/` one-to-one).
- **Screens:** at minimum a loading/error/empty branch test; add interaction tests for stateful UI.
- **Mock at the boundary only** — the boundary fetcher / native modules — **never** internal modules. Fetcher tests mock `@/services` and leave the real schema + mapper in place:

  ```ts
  jest.mock('@/services', () => ({ getConfig: jest.fn(), boundaryFetch: jest.fn() }));
  // getConfig('USE_MOCK') => false to take the live branch; assert the mapped view-model
  ```

- **When mocking a hook for a screen test, mock the barrel path (`@/hooks`)** and import from the same path in the screen — Jest module mocking is path-exact.
- Jest hoists `jest.mock(...)` factories above imports — any variable referenced inside a factory must be `mock`-prefixed (`mockNavigate`) or defined inside the factory.
- Test names describe behaviour ("throws when the id is unknown"), not implementation. **Never weaken a test to make it pass.**

## 15. Documentation is part of the PR

Update `docs/` in the same PR as the code — a reviewer reads the docs diff alongside the code diff.

- **New decision** (library, pattern, trade-off) → new ADR under `docs/decisions/`, increment the number, link from `decisions/README.md`.
- **New module / screen / subsystem** → add/update `docs/architecture/`.
- **New env key** → the environments doc + `.env.example`.
- **New domain term** → `docs/glossary.md`. **Operational procedure** → a runbook under `docs/runbooks/`.
- **Reversing a decision** → set the old ADR to `Superseded by NNNN` and write a new one; never edit history.
- **New canonical pattern** → this file, §17.

## 16. Forbidden (lint / husky / convention enforce most)

`any` / `as never` · a direct third-party call bypassing the data boundary · a fetch without a Zod schema · a `switch` for `kind`/type dispatch (use a map) · name-driven layout branching · **any colour literal (hex/`rgba()`/named) in a screen or component — colours come only from theme tokens; add a token if none fits (§8)** · `fontWeight` beside a brand family · raw `<Text>` for themed copy where `BaseText` fits · a spacing/typography magic number instead of a token · `moderateScale`/metrics-scale helpers · Figma values read off a screenshot · `Image.getSize`/`onLoad`-driven layout · inline `style={{}}` literals · anonymous functions in JSX props (except per-iteration list closures) · `map()`-in-`ScrollView` for dynamic lists · **hardcoded static data inlined in a component instead of `src/constants/`, or an API stand-in outside `src/mocks/` (§1a)** · a persisted store missing `skipHydration:true` or its `App.tsx` rehydrate · `Config.` access (use `ENV`/`getConfig`) · `Alert.alert` for routine feedback · empty `catch` / `.catch(()=>{})` / failure-hiding fallbacks · deep relative imports instead of `@/` · a new hook/util without a unit test · weakening a test to force green · shipping code without its docs diff. `<FILL IN — add your commerce/price rules if applicable: parseFloat on money, client-side price math, checkout URLs not from the API>`

## 17. Evolving the DNA

WHEN a feature or fix needs a pattern with no precedent here, THE SYSTEM SHALL: (1) design it consistent with the closest existing pattern, (2) get it approved at plan time (features) or flagged in the fix PR, (3) **add it to this file in the same PR** — with a copy-me snippet and, where a trade-off was made, an ADR it links to. The DNA is never bypassed "just this once".

## 18. Forms & local validation (zod-backed)

Data-entry forms follow one shape. There is no form library — validation reuses **`zod`** (already the wire firewall, §3) as a **validation-only schema colocated with a behaviour hook**. `src/schemas/` stays wire-only; a form schema lives next to its hook.

- **A `use<Screen>Form` hook owns state + validation** and exposes `{ values, errors, setField, validateAndSave(onValid) }`. `setField` clears that field's error as the user types; `validateAndSave` `safeParse`s and either sets per-field errors or calls `onValid`.
- **The schema is module-level**, declared once, and carries its messages (from a `src/constants/` content object, never inline strings). Required = `min(1)`; optional-but-validated = a `refine` that passes on empty.

```ts
const personalDetailsFormSchema = z.object({
  firstName: z.string().trim().min(1, ERROR_MESSAGES.firstName),
  email: z.string().refine(
    v => v.trim() === '' || z.email().safeParse(v.trim()).success,
    ERROR_MESSAGES.email,
  ),
});

const validateAndSave = useCallback((onValid: (v: Values) => void) => {
  const r = personalDetailsFormSchema.safeParse(values);
  if (!r.success) { setErrors(mapIssues(r.error.issues)); return; }
  setErrors({});
  onValid(values);
}, [values]);
```

- **Presentation is a variant-driven field** (`readonly | editable | select`) — one primitive, no per-field components.
- **Save/queue feedback is the global toast** (§13), never `Alert.alert`.
- **The hook gets a unit test** (§14); the screen tests the valid/invalid branches.

## 19. Bottom sheets — `<FILL IN / DELETE — verify on your stack>`

_This genome's origin project found `@gorhom/bottom-sheet` does not animate on a Reanimated-4 / New-Arch stack (gorhom v5 couples to Reanimated v3 APIs), so **all bottom sheets hand-roll RN `Modal` + core `Animated`**._ Verify against your own Reanimated/gorhom versions and record the decision here.

```tsx
// Slide-up sheet: keep mounted through the exit animation, then unmount;
// animate a backdrop opacity + a panel translateY.
const [mounted, setMounted] = useState(visible);
const backdrop = useRef(new Animated.Value(0)).current;
const translateY = useRef(new Animated.Value(height)).current;
useEffect(() => {
  if (visible) { setMounted(true); Animated.parallel([/*→1, →0*/]).start(); }
  else Animated.parallel([/*→0, →height*/]).start(({finished}) => finished && setMounted(false));
}, [visible, backdrop, translateY, height]);
if (!mounted) return null;
```

- **Android safe-area:** `react-native-safe-area-context` reports bottom inset `0` **inside an RN `Modal` on Android**. Read the inset in the **screen** (outside the Modal) and pass it as a `bottomInset` prop; fold it into `useThemeStyles` deps — never an inline `style={{}}` (§8).
- Backdrop colour is a token (`colors.overlay`), never a literal.

## 20. REST endpoints — `<FILL IN / DELETE if boundary is GraphQL-only>`

If some backend surfaces are REST, they go through a REST sibling of the boundary fetcher — same contract, different transport:

```ts
export async function boundaryRestFetch<S extends z.ZodType>(
  path: string, schema: S, init?: { method?: 'GET' | 'POST'; body?: Record<string, unknown> },
): Promise<z.infer<S>> {
  const url = `${getConfig('API_BASE_URL')}${path}`;
  const response = await fetch(url, { /* method, headers, body */ });
  if (!response.ok) {
    const errorBody = await response.json().catch(() => null);
    throw new BoundaryRestError(response.status, url, errorBody?.code ?? null, errorBody?.message);
  }
  const parsed = schema.safeParse(await response.json());
  if (!parsed.success) throw new ResponseValidationError(url, parsed.error.issues);
  return parsed.data;
}
```

- **Every call still passes a Zod schema** (§3); fetchers keep the `getConfig('USE_MOCK')` branch; mapping still lives in `src/mappers/`.
- **Errors are typed** and carry the REST error `{ code, message }` so callers can branch on `code`.
- **Mutations with no server idempotency pin `retry: 0`** with an inline comment (a retried POST would duplicate).
- Do not add a third client — extend this one if a new verb/need appears.
