# Tech DNA — Canonical Code Patterns

> This is the project's coding genome. Every feature **and every bugfix** is written by **copying these patterns**, never by inventing a new style per requirement. If a task needs a pattern with no precedent here, establish it deliberately and **add it to this file in the same PR** (§17) — the DNA evolves, it is never bypassed. This file is reviewed like code: it is the reason two features written months apart read like they were written by the same hand.
>
> **Read this before writing any code.** It is the "how"; [`../CLAUDE.md`](../CLAUDE.md) is the map, the hard-rules index and the silent-traps list; the [ADRs](decisions/README.md) are the "why"; [`architecture/`](architecture/README.md) is the per-subsystem detail. When this file and a snippet in the codebase disagree, the codebase wins — fix this file in the same PR.
>
> ---
> **📌 Scaffolded from the `rn-workflow` plugin — this is the UNIFORM BASELINE, identical in every new project.** Its purpose is that every app starts from the same genome so they all read alike.
>
> **Baseline stack — rules about these are HARD rules:** React Navigation v7 (native stack) + `react-native-screens`, `@tanstack/react-query`, `zustand` + `react-native-mmkv`, `zod`, `@shopify/flash-list`, `react-native-config`, `react-native-reanimated` + `react-native-worklets`, `react-native-gesture-handler`, `react-native-safe-area-context`, `react-native-keyboard-controller`, `react-native-keychain`; `useThemeStyles` / `BaseText` / the shared `Pressable`; the folder layout and the data pipeline below.
>
> **Device baseline: most users are on 2–4 GB RAM Android phones.** Every screen must run smoothly there — high-end phones then come for free. Performance rules (§11, §11a, §11b) and safe-area rules (§7a) are written for that baseline.
>
> **Optional integrations — a section or bullet marked _"If your app uses X"_ applies only when X is in the app** (video, WebView, remote config, a crash reporter, analytics SDKs, OTA updates). Delete what doesn't apply.
>
> **Devs extend it per project — that is expected, not a violation.** Sections marked **`<FILL IN>`** are the deliberately-blank slots for project specifics (the backend boundary, env keys, fonts/brand tokens, currency, third-party integrations). Fill those before your first feature; add new `§` sections as the project grows (§17); swap a baseline choice only with an ADR recording why. Once filled in, delete this banner.
>
> **Map:** §0–§20 are the everyday build patterns · §21–§28 are cross-cutting (release & native, security, auth, permissions, SDKs, app lifecycle, analytics & privacy, release checklist) · **§29 lists the failures that are silent** — no error, no failing test.

## 0. The data boundary

**`<FILL IN — your single data boundary>`** — describe the one client every read/write goes through, and the rule that the app never calls a third party directly.

_Reference shape (this genome's origin project used middleware-only over GraphQL):_

```
App → <your backend boundary> → downstream services
```

Every read/write goes through one boundary fetcher (§3). Do not add direct third-party data integrations. Rendering is **config-driven, never name-driven**: UI adapts from API config flags (`layout_style`, `mobile_layout`, …), never from section/instance names (§6). Third-party **SDKs** follow the same idea: exactly one service module imports each one (§25).

## 1. File & folder anatomy

Everything lives under `src/`, and **every folder has a barrel `index.ts`** (match its existing re-export style when editing). Imports across `src/` use the `@/` alias — never deep relative paths (`../../..`).

```
src/
  components/
    core/         app-agnostic building blocks, ONE FOLDER PER COMPONENT (§1b) — button/, pressable/, image/, sheet/, icon/ …
    common/       app-level components shared by 2+ screens (BaseText, cards, rails)
    sections/     generic SectionList + SectionRegistry infra (screen-agnostic)
    <area>/       components used by one screen / feature area (cart/, home/, account/ …)
  screens/<Name>/ the screen file + barrel only (§7)
  navigation/     RootNavigator + typed ParamLists + link parser + intent queue
  hooks/          query hooks + screen/behaviour hooks (every hook has a unit test — §14)
  services/       boundary fetcher, queryClient, errors, ONE wrapper per third-party SDK (§25)
  store/          Zustand stores + MMKV storage adapter
  schemas/        Zod wire-shape schemas (one file per area)
  mappers/        wire→view-model mappers (the firewall — §3)
  graphql/        queries/ mutations/ fragments/  (plain tagged template strings) — if GraphQL
  utils/          pure functions (every util has a unit test — §14)
  constants/      static, no-API data + env/brand/config keys (§1a)
  mocks/          wire-shape fixtures for the USE_MOCK offline/test path (§1a)
  theme/          design tokens (colors, spacing, typography, fonts) — §8
  types/          shared view-model + domain types
  assets/         images (WebP — §8a), fonts, svgs
```

- File name matches its main export (`BaseText.tsx` exports `BaseText`; `mapHomepage.ts` exports `mapHomepage`).
- Where each component goes, and when to reuse instead of writing new: §1b.
- Import order (ESLint-enforced, autofixed): external (react/react-native first) → builtin → internal `@/**` → parent/sibling → type; alphabetised, newline between groups.
- **Barrels, with one exception (HARD RULE):** widely-shared infrastructure — the error boundary, the crash-reporter wrapper, the config accessor — **imports leaf files, never barrels**. `export *` binds at require time: if a module imports a barrel that (transitively) re-enters a barrel still mid-evaluation, that export stays **`undefined` forever**, and the crash (`Element type is invalid … Check the render method of <X>`) names a file nowhere near the cause.
- **One mechanism per job** — one image component, one sheet shell, one toast host, one link parser. A second hand-rolled copy is a defect.

### 1a. Static & mock data — where hardcoded data lives (HARD RULE)

Hardcoded data is **never inlined in a screen/component**. It lives in one of two homes by whether the backend will ever own it:

- **Genuinely static, no-API data → `src/constants/`.** Presentational data the backend will _never_ serve — category handles, support links, brand strings, size charts — is a typed constant, exported through the barrel and imported via `@/constants`. A magic string/array/number inline in JSX that represents such data is a defect — extract it. When a value later becomes contract-backed, its single home moves to the mapper/schema, not scattered call sites.
- **Wire-shape fixtures for the offline/test path → `src/mocks/`.** Data that _stands in for a real API response_ (so the app runs with `USE_MOCK` on and tests never hit a live server) mirrors the exact wire shape, is **validated by the same Zod schema** as the live response, and lives in `src/mocks/`. Fetchers select it via `getConfig('USE_MOCK')` (§3). These are temporary stand-ins for a contract — not static constants.
- **Fixtures stay out of the release build.** Metro does not tree-shake, so a top-level `import { xMock } from '@/mocks'` ships every fixture in every build. Load the fixture **inside** the `USE_MOCK` branch (an inline `require`), and have Metro resolve `src/mocks/**` to empty stubs for production builds. A production build never runs with `USE_MOCK` on.
- **Mocks never re-implement server logic** (filtering, sorting, paging maths) — unit-test the request builder instead (§3b).
- **Never show made-up data as if it were real.** If the contract doesn't send a value, render nothing.

Rule of thumb: _"Will this ever come from the backend?"_ — **yes → a `src/mocks/` fixture** (schema-shaped); **no → a `src/constants/` constant** (view-model-shaped).

### 1b. Component structure & reuse (HARD RULE)

**Where a component lives:**

| Kind | Path | Example |
| ---- | ---- | ------- |
| **Core** — app-agnostic building block, no business logic | `src/components/core/<name>/<Name>.tsx` + `index.ts` | `core/button/Button.tsx`, `core/pressable/Pressable.tsx`, `core/sheet/BottomSheet.tsx` |
| **Common** — app-level component used by 2+ screens | `src/components/common/<Name>.tsx` | `common/BaseText.tsx`, `common/ProductCard.tsx` |
| **Area** — used by one screen / feature area | `src/components/<area>/<Name>.tsx` + `index.ts` | `components/cart/CartFooter.tsx`, `components/home/HomeScreenSkeleton.tsx` |
| **Screen** — the route component only | `src/screens/<Name>/<Name>Screen.tsx` + `index.ts` | `screens/Cart/CartScreen.tsx` |

- **Every core component gets its own folder**, even when it is a single file: folder name in camelCase, file name in PascalCase matching its export, plus an `index.ts`. Its private sub-parts and helpers sit in the same folder (`core/button/ButtonBusyContent.tsx`). Icons live together in `core/icon/`.
- **A screen folder holds only the screen and its barrel.** The screen composes hooks and components; it does not define reusable components inside its file. Its sections, rows, footers and skeletons go in `components/<area>/`, where `<area>` is the feature name in camelCase.
- **Moving up:** an area component needed by a second screen moves to `common/`; anything with no app/business knowledge moves to `core/`. **Never import one area's component from another area** — promote it instead.
- Every folder has an `index.ts` barrel; import through it (`@/components/core`, `@/components/cart`), except shared infrastructure (§1).

**Reuse before writing (HARD RULE):** before building any UI, check `components/core/` and `components/common/` for an existing component, and use it. **Never use a React Native primitive when the project already has a component for that job.** Use a React Native primitive only when no project component exists — and if what you're building will be needed again, create it as a project component in the right folder (above) instead of styling the primitive inline.

| Instead of (React Native) | Use the project component |
| ------------------------- | ------------------------- |
| `Text` for themed copy | `BaseText` (§8) |
| `Pressable` / `TouchableOpacity` / `TouchableHighlight` | the shared `Pressable` (§8) — except a full-screen backdrop |
| `Image` | the shared image component with `renderWidthDp` (§11a) |
| a hand-built button | `Button` |
| `Modal` + animation for a sheet | the shared `BottomSheet` (§19) |
| a raw `TextInput` in a form | the shared form field (§18) |
| `ScrollView` + `.map()` for a carousel | the shared rail (§11) |
| an inline SVG/icon | a component from `core/icon/` |

`<FILL IN — update this table as the project adds core components>`. Layout primitives with no project equivalent (`View`, `ScrollView`, `FlatList` where FlashList doesn't fit, `ActivityIndicator`) are used directly.

- **Extend, don't duplicate:** if an existing component is close, add a `variant` (or a prop) to it — never create a near-copy. Callers pass a `variant`, not raw sizes or styles.

## 2. Naming & TypeScript

| Thing | Convention | Example |
| ----- | ---------- | ------- |
| Screen component | PascalCase + `Screen` suffix, **named** export | `HomeScreen`, `ProductListScreen` |
| Component | PascalCase, named export; props type `<Name>Props` exported | `ProductCard`, `ProductCardProps` |
| Query/fetch hook | `use<Domain>` (mounted) + `fetch<Domain>` (fetcher) | `useHomepage` / `fetchPageSections` |
| Behaviour hook | `use` prefix, camelCase file | `useFavouriteActions.ts` |
| Store | `use<Domain>Store` in `<domain>Store.ts` | `useAuthStore`, `useSettingsStore` |
| Mapper | `map<PascalCaseWireType>` | `mapHomepage`, `mapProductContent` |
| Request builder | `build<Area>Request` (pure util, §3b) | `buildSearchRequest` |
| GraphQL operation | `SCREAMING_SNAKE` + `_QUERY` / `_MUTATION` | `PAGE_SECTIONS_QUERY` |
| Section kind / component / mapper | `kind === wire type` (kebab); component `PascalCase(type)+Section`; mapper `map+PascalCase(type)` (§6) | `category-tiles` → `CategoryTilesSection` / `mapCategoryTiles` |
| Query key | tuple array, namespaced, params appended | `['homepageByHandle', slug]` |
| testID | kebab-case `<screen>-<element>` | `home-tab-men`, `list-sort-button` |
| Colour token literal | uppercase hex digits | `'#1A1A1A'` |
| Boolean | `is` / `has` / `should` prefix | `isLoading`, `hasError`, `shouldShowBanner` |

TypeScript: **`strict` is on — no `any`, no `as never`.** Prefer typed declarations over `as` assertions. Use **defensive field access** (optional chaining / nullish defaults) for any API-sourced field that could be absent — even one the schema currently requires — and normalise it in the mapper so components receive clean data.

**TypeScript & code style (HARD RULE):**

1. **`type`, never `interface`** — one way to declare shapes (`type ProductCardProps = { … }`).
2. **No `enum`** — use a union type, or an `as const` object with a derived type:

   ```ts
   export const ORDER_STATUS = { placed: 'placed', shipped: 'shipped' } as const;
   export type OrderStatus = (typeof ORDER_STATUS)[keyof typeof ORDER_STATUS];
   ```

3. **No `@ts-ignore` / `@ts-nocheck`, no non-null `!`, no `object` type.** Data of unknown shape is `unknown` and gets narrowed (Zod or a type guard); a loose map is `Record<string, unknown>`.
4. **Type-only imports use `import type`** (`import type { Product } from '@/types'`).
5. **Never fake a missing id with `''`, `'0'` or `'-1'`** — type it `string | undefined` and return early when it's missing. A fake id hides the bug and sends garbage to the backend.
6. **Booleans are named `is…`, `has…` or `should…`** (`isLoading`, `hasError`, `shouldShowBanner`).
7. **More than 5 parameters → one object parameter** (`createOrder({ cartId, addressId, … })`), so arguments can't be passed in the wrong order.
8. **`async/await`, not `.then` chains.** Independent calls run together with `Promise.all` (or `Promise.allSettled` when one failure shouldn't cancel the others) — never one after another when they don't depend on each other.
9. **Defaults use `??`, not `||`** — `||` also replaces `0`, `''` and `false`. Use `?.` for optional access.
10. **No `defaultProps` or `propTypes`** — give defaults in the props destructuring (`const Badge = ({ size = 'md' }: BadgeProps) => …`). Share logic with custom hooks, not HOCs or render props (the one exception: an error boundary, which must be a class, may wrap a screen).
11. **Components and hooks are arrow functions** — `export const ProductCard = ({ … }: ProductCardProps) => { … }`, `export const useCart = () => { … }`. Plain helpers and services may use `function`.

Enforce with ESLint: `@typescript-eslint/consistent-type-definitions: ['error', 'type']` · `no-restricted-syntax` on `TSEnumDeclaration` · `@typescript-eslint/ban-ts-comment` · `@typescript-eslint/no-non-null-assertion` · `@typescript-eslint/consistent-type-imports` · `@typescript-eslint/prefer-nullish-coalescing` · `max-params: ['error', 5]` · `@typescript-eslint/naming-convention` (boolean prefixes).

Common JS / RN pitfalls:

- **`undefined === undefined` passes a "same value" check** — normalise first (`a ?? null` vs `b ?? null`).
- **Dates:** keep server timestamps as strings and compare with `Date.parse`; never sort dates as strings. `new Date('YYYY-MM-DD')` is **UTC midnight**, not local midnight.
- **Match server enum values exactly, never by substring** (`unfulfilled` contains `fulfilled`).
- **Android `Platform.Version` is the API level** (`34`), not the OS version (`"14"`).

### 2a. React & hooks (HARD RULE)

1. **Calculate derived values during render** — never copy props or state into another state with a `useEffect` (it renders twice and can go out of sync). If the calculation is expensive, wrap it in `useMemo`.

   ```tsx
   // ✗ const [total, setTotal] = useState(0); useEffect(() => setTotal(sum(items)), [items]);
   const total = sum(items); // ✓
   ```

2. **User actions run in the event handler, not in a `useEffect`.** Submitting, calling an API, navigating or showing a toast because the user tapped something happens inside `onPress` / `onSubmit`. Effects are only for syncing with something outside React while the component is on screen (a subscription, a listener).
3. **Every effect that adds a listener, subscription or timer returns a cleanup** that removes it — a missing cleanup is the most common memory leak.

   ```tsx
   useEffect(() => {
     const sub = AppState.addEventListener('change', onChange);
     return () => sub.remove();
   }, [onChange]);
   ```

4. **Reset a component's state by changing its `key`** (`<ProductForm key={productId} />`), not with an effect that clears state when a prop changes.
5. **Never silence `react-hooks/exhaustive-deps`.** Fix the effect first (move the function or value inside it). If you truly must disable it, disable it for the next line only, with a comment saying why.
6. **Keep component types stable:**
   - never define a component inside another component's body — it becomes a new component on every render, so everything inside remounts and loses its state;
   - don't swap the wrapper around the same content (`isX ? <View>…</View> : <ScrollView>…</ScrollView>`) — that remounts the content too. Change props or styles instead.
7. **Subscribe as low in the tree as possible.** A component reads only the values it shows, one selector per value (`useCartStore(s => s.count)`), and the subscription lives in the child that needs it — not in a parent that passes it down. Don't put unrelated values in one Context: every consumer re-renders when any of them changes — split the Context, or use a store with selectors (§5).

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

**The boundary fetcher** — one client for all app data. It times out, checks GraphQL errors before the schema, validates against a Zod schema, never leaks a query string into an error, and throws typed errors:

```ts
// src/services/<boundary>Fetch.ts (shape — GraphQL flavour; REST sibling in §20)
const DEFAULT_TIMEOUT_MS = 15_000;
const redact = (url: string) => url.split('?')[0]; // string split — never `new URL` (§22)

export async function boundaryFetch<S extends z.ZodType, V = Record<string, unknown>>(
  request: string,
  schema: S,
  variables?: V,
  init: { signal?: AbortSignal; skipAuth?: boolean; timeoutMs?: number } = {},
): Promise<z.infer<S>> {
  const url = `${getConfig('API_BASE_URL')}/…`; // read at call time (§12)
  const controller = new AbortController();
  let timedOut = false;
  const timer = setTimeout(() => { timedOut = true; controller.abort(); }, init.timeoutMs ?? DEFAULT_TIMEOUT_MS);
  const forwardAbort = () => controller.abort();
  init.signal?.addEventListener('abort', forwardAbort);
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: await buildHeaders({ skipAuth: init.skipAuth }), // authenticated by default (§23)
      body: JSON.stringify({ query: request, variables }),
      signal: controller.signal,
    });
    if (!response.ok) throw new BoundaryHttpError(response.status, redact(url)); // any 2xx is success
    const json = await response.json();
    if (json.errors?.length) throw new GraphQLResponseError(json.errors, redact(url)); // BEFORE the schema
    const parsed = schema.safeParse(json.data);
    if (!parsed.success) throw new ResponseValidationError(redact(url), parsed.error.issues);
    return parsed.data;
  } catch (e) {
    if (timedOut) throw new BoundaryTimeoutError(redact(url)); // typed + retryable; a caller abort stays AbortError
    throw e;
  } finally {
    clearTimeout(timer);
    init.signal?.removeEventListener('abort', forwardAbort);
  }
}
```

**The fetcher** — mock-aware, returns a view-model. Copy-me shape for every screen fetcher:

```ts
// src/hooks/fetchPageSections.ts
export async function fetchPageSections(slug: string): Promise<HomeSection[]> {
  const data = getConfig('USE_MOCK')
    ? homePageSchema.parse(require('@/mocks/homePage').homePageMock) // lazy — not in release builds (§1a)
    : await boundaryFetch(PAGE_SECTIONS_QUERY, homePageSchema, { slug });
  return mapHomepage(data); // firewall: wire → view-model
}
```

Rules — the boundary:

- **Every fetch MUST pass a Zod schema.** The only visible opt-out is `z.unknown()` — its presence in a diff flags a deliberate skip for review.
- Schemas validate the **wire shape** and live in `src/schemas/<area>.ts`. Wire types are exported from there (`z.infer`).
- **Schemas declare only the fields the app reads.** An unused required field can fail the whole response for no benefit. A field the backend hasn't shipped yet is `.nullish()`.
- **Success is any 2xx** — check `response.ok`, never `status === 200` (POSTs often return 201).
- **If the backend wraps responses** (`{ success, data, error }`), unwrap it once in the boundary (§20) — never in each fetcher — and check `success` **before** reading `data`. A failure response never resolves as success.
- **GraphQL `errors[]` is checked before the schema parse** — otherwise an error response shows up as a confusing validation error.
- **Every request has a timeout.** React Query only retries after a failure, so a request that never finishes keeps the loading state up forever. A timeout throws its own typed error; a caller's abort stays a plain `AbortError`.
- **Errors never carry a query string** — ids in query strings otherwise end up in crash reports.
- **Requests are authenticated by default**; public and login/refresh calls pass `skipAuth` (§23).

Rules — the mapper:

- **Mapping lives in the mapper**, declared once. Normalise dimensions, links, colours, and layout defaults there — never in components. Map over a **`type → mapperFn` map, never a `switch`**; unknown types are dropped in the mapper (§6).
- When the wire has no ids, **derive stable ids from content, never from list position** (position-based ids break when content is re-ordered).
- **Drop an item that is missing something the UI needs** (an image, a link) — a broken tile or a dead tap is worse than no tile.
- `getConfig('USE_MOCK')` gates the offline path. Tests run with `USE_MOCK` on and never hit a live server (§14).

### 3a. GraphQL text organization — `<FILL IN / DELETE if not GraphQL>`

If the boundary is GraphQL: all query/mutation text lives only under `src/graphql/` (`queries/`, `mutations/`, `fragments/`), as plain tagged template strings (`/* GraphQL */` for editor highlighting) — no Apollo, no codegen. Shared selections are **plain string constants** (`IMAGE_FIELDS`, `CARD_FIELDS`) interpolated into queries — **not** `fragment ... on Type` declarations (a wrong type name passes every offline test then 400s the whole live query). Add a real named fragment only for a verified, stable server type.

- **One unknown field or argument rejects the whole operation** — and the mock path never sees it. Check every field against the live schema before selecting it. Declaring an upcoming field `.nullish()` in Zod is safe; **selecting** it in the query is not.

### 3b. Contracts & request building

- **Check the real API before building on it**, and write down what you found (date + environment) in the spec. Docs and examples often differ from the live API.
- **A 2xx doesn't prove a parameter worked** — many APIs silently ignore unknown sort/filter fields. Verify with data that shows the difference.
- **Request-side mapping is a pure, unit-tested builder** (`build<Area>Request`): app filters/sort/paging in → wire body out. Hooks take app-level parameters, so a wire change never reaches the screen.
- **Paging:** never loop on a server cursor without a hard cap; a burst of `onEndReached` calls makes **one** fetch and stops at the last page.
- **Percent-encode every query value** (`encodeURIComponent`) — a raw `+` decodes to a space.
- **`FormData` uploads never set `Content-Type`** — the platform must add the multipart boundary itself.
- **Mock-first work:** mark guessed wire files `PROVISIONAL — reconcile with real contract`, so only those files change when the real contract lands.
- **Read the installed SDK's real API** (its types and exports); never copy integration code written for another version or vendor.

## 4. React Query pattern

`queryClient` is **cache-first**: global `staleTime 3min`, `gcTime 10min`, `refetchOnWindowFocus:false`, `refetchOnMount:false`, and `retry` as a **predicate** (below) — revisiting a screen renders cached data instantly, no skeleton flash. Freshness comes from `staleTime` expiry and explicit pull-to-refresh.

- **Share one query-options factory** between the hook and any prefetch — React Query only joins a prefetch to a mounted query when key, `queryFn` **and** `staleTime` all match:

  ```ts
  function homepageQueryOptions(slug: string) {
    return {
      queryKey: ['homepageByHandle', slug] as const,
      queryFn: () => fetchPageSections(slug),
      staleTime: 60_000, // per-hook override of the 3min default
    };
  }
  export const useHomepage = (slug = 'home') => useQuery(homepageQueryOptions(slug));
  export const prefetchHomepage = (qc: QueryClient, slug = 'home') =>
    qc.prefetchQuery(homepageQueryOptions(slug));
  ```

- **Retry predicate:** don't retry failures that will fail again (schema mismatch, 4xx, business errors, auth rejections). Retry only network, timeout and 5xx failures. Never retry a mutation that isn't idempotent (§20).
- **Query keys are namespaced tuple arrays** — `['product', handle]`, never template-string keys. Sort id lists and round volatile values (like coordinates) before they go into a key, or every call becomes a new cache entry.
- **`placeholderData: (prev) => prev`** on list / filter / pagination / search keys so a key change keeps the previous result on screen. Not on detail screens — it briefly shows the previous item.
- **A disabled query never reports `isSuccess`** — the empty branch must account for it. Keep **"not loaded yet"** separate from **"loaded and empty"**, and never turn `isError` into `data ?? null`.
- **`gcTime` must be ≥ `staleTime`** — a query removed from the cache refetches anyway.
- **After a mutation, invalidate every query that shows the changed data.** After login/logout, fetch user data fresh.
- **Search-as-you-type:** debounce the input, only query after a minimum length, keep previous results on screen.
- Override `staleTime`/`refetchOnMount` per hook **only with an inline comment** citing the reason.
- **Every data screen wires pull-to-refresh:** `<RefreshControl refreshing={isRefetching} onRefresh={refetch} />`.
- **Every hook in `src/hooks/` has a unit test** (§14).

## 5. State — Zustand + MMKV

MMKV is constructed at boot (`bootstrapStorage()`) with an encryption key generated on first launch and held in the Keychain. Stores use the `zustandMMKVStorage` adapter. **Tokens and passwords never live in a persisted store** — see §23.

```ts
// src/store/authStore.ts — the canonical persisted store
export const useAuthStore = create<AuthState>()(
  persist(
    set => ({
      isAuthenticated: false,
      markSignedIn: () => set({ isAuthenticated: true }), // intention-named action
      clearSession: () => set({ isAuthenticated: false }),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => zustandMMKVStorage),
      skipHydration: true, // rule 1
      version: 1, // rule 3 — explicit from day one
      migrate: migrateAuthState, // rule 3 — (persisted, fromVersion) => current shape
      partialize: s => ({ isAuthenticated: s.isAuthenticated }), // rule 4 — allow-list
    },
  ),
);
```

**Adding a persisted store is a footgun — every rule is mandatory:**

1. `skipHydration: true` in the `persist(...)` options (MMKV is `null` until `bootstrapStorage()` resolves; auto-hydration fires at module load and would throw).
2. Add `await useXStore.persist.rehydrate()` to the `Promise.all([...])` in `App.tsx`'s bootstrap effect. The render tree is gated on `storageReady` until all rehydrates resolve.
3. **An explicit `version` from day one; bump it with a `migrate` whenever a saved field is removed, renamed or moved.** Zustand defaults `version` to `0`, so leaving it out still means version 0 — old saved data is merged in without any migration.
4. **`partialize` is an explicit allow-list — never `state => ({ ...state })`.** Zustand merges saved data over current state, so a field you deleted from the code can come back from storage, and a spreading `partialize` saves it again on every change. No type or test catches this.

**Storage encryption (MMKV + Keychain):**

- **The key** is random, generated on first launch, and stored in the Keychain ("after first unlock, this device only") — never written in JS code.
- **Use AES-256 with a base64 key.** MMKV uses the key string's bytes and cuts them to the cipher size: without AES-256 it is AES-128, and a hex key carries only half the strength. Assert the key length in a test.
- **If the device has no hardware keystore**, fall back to software storage only for that specific error — don't fail every launch.
- **iOS Keychain survives an uninstall; Android doesn't.** Detect a reinstall (a stored key next to an empty store) and create a new key.
- **To change the key of an open store, use MMKV's re-key API** — opening it again with a new key is silently ignored, because MMKV caches open stores by id.
- One storage instance; keep saved data small (it is written on every change).

**Other rules:**

- **Intention-named actions** (`markSignedIn`/`clearSession`), never a generic `setState`-style mutator.
- **Narrow selectors** in components — `useStore(s => s.action)`, not the whole store.
- Outside React (services, navigation listeners, helpers): `useXStore.getState()` — never call a hook outside a component.
- **Ask "must this survive a relaunch?" first.** If not, use plain `create()` without `persist`. Ephemeral UI state (toasts) is a non-persisted store.
- Server data that a query owns belongs to React Query, not a store. **Save ids, not copies of server data** — copies go stale.
- **Sensitive short-lived data** (precise location, one-time codes) is never persisted.
- **A hook that adds a global listener (AppState, NetInfo) is mounted once**; other parts read its result from a store.
- **Optimistic updates:** update locally, send to the server, roll back and tell the user if it fails; queue changes to the same item one after another; ignore a response if the data changed since the request was sent.
- **"Clear" (logout/reset) is final:** cancel in-flight requests and ignore any response that arrives afterwards — otherwise a late response writes the previous user's data back.

## 6. Config-driven section rendering (HARD RULE)

Page layouts arrive as an ordered list of **sections**, each with a `type` + config. Zod-validate → map to view-model sections discriminated by `kind` → render with the shared generic renderer.

- **One shared renderer, one registry per screen.** `<SectionList sections registry gap>` owns dispatch, keying, inter-section spacing, and the unknown-kind no-op **once**. Each screen supplies a `SectionRegistry<S>` mapping `kind → component`.
- **Dispatch is an O(1) map lookup — never a `switch`.** Unknown kinds no-op with a `__DEV__` warning so the backend can ship a new type before the app implements it.
- **Validate each section on its own** — one broken section is dropped, never the whole page. A strict union over all sections fails the entire payload the day the backend adds a new type.
- **Config-driven, never name-driven.** Branch layout on config flags (`layoutStyle: 'carousel' | 'grid'`), never on instance/section names.
- **`kind === wire type`**: the wire `type` string is the search entry point — grepping it must lead straight to schema → mapper → component. Never rename wire→purpose.

```ts
export type SectionRegistry<S extends RenderableSection> = Partial<{
  [K in S['kind']]: ComponentType<{ section: Extract<S, { kind: K }> }>;
}>;
// dispatch: registry[section.kind] ?? __DEV__ warn + null
```

## 7. Screen pattern

Screens are **UI + wiring only**; data/business logic lives in `@/hooks`. A screen composes hooks, holds only view-local UI state (a selected segment, a scroll ref), and renders. Logic needed by two screens becomes one hook, never a copy. The screen's own components live in `components/<area>/` (§1b).

```
src/screens/Home/
  HomeScreen.tsx          orchestrates: reads route, holds UI state, calls useHomepage, renders
  index.ts                barrel
src/components/home/
  HomeSectionsView.tsx    the list/scroll body + RefreshControl + SectionList
  HomeScreenSkeleton.tsx  loading state that mirrors the above-the-fold layout (no CLS)
  index.ts                barrel
```

- **Loading / error / empty are explicit branches**, each testable (§14). Loading states mirror the real layout (reserve media boxes by `aspectRatio`) so content doesn't jump.
- **No runtime media measurement** — never drive layout from `Image.getSize` or video `onLoad`. Dimensions come from the contract (or a fallback constant in the mapper). Measuring a container with `onLayout` is fine.
- Route params are typed from the ParamLists (§10) — never `any`, never untyped `route.params`. Set initial state from route params in the `useState` initializer, not in a mount effect.
- **Screens that stay mounted under other screens** (tabs) run their side effects on **focus + foreground** (`useFocusEffect`, `useIsFocused` + AppState), not on mount.
- **Hidden-but-mounted UI** (collapsed sections) is removed from the accessibility tree.
- **A control that does nothing when tapped is a defect** — wire it or hide it.

### 7a. Edge-to-edge & system bars (HARD RULE)

The app draws **edge-to-edge**: content goes under the status bar and the bottom navigation area, and every screen keeps its content and controls out of them. Android keeps `edgeToEdgeEnabled=true` (Android 15+ forces edge-to-edge for apps targeting SDK 35 anyway). The bottom area is either a **gesture bar** (thin) or **3-button navigation** (tall) — layouts must work with both, and nothing tappable may sit under either.

- **Insets come from `react-native-safe-area-context`** (`useSafeAreaInsets()` / `SafeAreaView` with `edges`). **Never hardcode a status-bar, notch or navigation-bar height**, and never assume the bottom inset is 0.
- **Bottom-pinned elements** (CTA bars, footers, sticky buttons, floating buttons, toasts) pad by the bottom inset **with a minimum**, so they clear the 3-button bar and still breathe when the inset is 0:

  ```tsx
  const { bottom } = useSafeAreaInsets();
  const footer = useThemeStyles(() => ({ paddingBottom: Math.max(bottom, spacing.lg) }), [bottom]);
  ```

  Put this in **one shared footer/sticky-bar component** so every screen behaves the same.
- **Scrolling content** pads its **`contentContainerStyle`** (not the scroll view itself) by the bottom inset **plus the pinned bar's measured height** (read it with `onLayout` — never a hardcoded number, because the bar grows with large system text, §8c), so the last item can scroll fully into view above the navigation bar and above a sticky footer.
- **Screens without a navigator header** (`headerShown: false`) handle `insets.top` themselves. If the app supports landscape, handle `left`/`right` insets too (notches and cutouts).
- **Status bar icons must stay readable:** with a transparent status bar, set `barStyle` to contrast with the background behind it (`dark-content` on light screens, `light-content` on dark ones).
- **Inside an RN `Modal`, the app's insets don't apply** — the Modal is a separate window (§19).
- **Keyboard + edge-to-edge** is handled by keyboard-controller (§18a), not `adjustResize`.
- **Test every screen with a bottom element on:** Android gesture navigation, Android **3-button navigation**, an Android ≤ 14 device and an Android 15+ device, and an iPhone with a home indicator. Emulators on new Android versions can hide inset bugs — check on a real device.

## 8. Styling & theme

- **Colours come ONLY from theme tokens — a colour literal in a screen/component is a defect (HARD RULE).** Never write a hex/`rgba()`/named colour in `src/screens/` or `src/components/`. Every colour is `colors.<token>` (via `useThemeStyles`). **Before adding a colour, find the existing token**; **only if none matches, add a new token** (hex-only, uppercase: `#RRGGBB`, or `#RRGGBBAA` for alpha — no `rgba()`, no named colours) with a comment citing its Figma source. Need alpha on an existing token? `withAlpha(colors.<token>, 'AA')` — never inline a literal. This includes scrims/overlays (use `colors.overlay` or add a scrim token). **One exception:** the app-level `ErrorBoundary` uses inline values, because it must render even if the theme fails (§13).
- **Spacing & typography come from token sets**, not a scaling function: `spacing.*` and `typography.*` tokens. **There is no `moderateScale`/`horizontalScale` system — do not introduce one.**
- **Fonts: weight is carried by the family, never `fontWeight`** (§8b). Never hardcode a font-family string — use the typography tokens.
- **Prefer `BaseText` over raw `<Text>`** for themed copy — it takes a `variant` (typography token) + `color` (theme token). Drop to raw `<Text>` only where no theme styling applies.

  ```tsx
  <BaseText variant="brandBodySmall" color="textSecondary">{title}</BaseText>
  ```

- **Themed styles → `useThemeStyles`** (memoised style factory); truly static never-themed styles → module-level `StyleSheet.create`. Never inline `style={{}}` object literals; never anonymous functions in JSX props (except per-iteration list closures — §11).
- **Every tappable uses the shared `Pressable`** (`@/components/core/pressable`) — React Native's own `Pressable` shows no pressed feedback, so the tap feels dead. The shared one is a drop-in with the same props that adds a pressed opacity and sets `accessibilityRole="button"` by default (§8c). **One exception:** a full-screen backdrop (the dimmed layer behind a sheet or dialog) uses React Native's `Pressable`, imported as `RNPressable` with a comment — a pressed opacity there would flash the whole screen.
- **No double submits:** buttons that submit, pay, place an order or add something go through **one shared hook** that ignores repeat taps while the action is running (and the button shows busy). Not for steppers or toggles where repeated taps are intended — those use the per-item queue (§5).
- **A busy button shows its spinner on top of the label**, keeping the label mounted but invisible — swapping the label for a spinner changes the button's size mid-tap.
- **Sizing: prefer padding over fixed `width`/`height`** for content/text containers. Reserve explicit dimensions for media / known-aspect boxes.
- **Dashed or dotted lines are an SVG, never a border** — a one-sided dashed border renders nothing on iOS.
- **`<FILL IN / DELETE — CDN image optimization>`:** _If your images come from a CDN with URL size transforms_, apply the transform **once in the shared image component**, so mappers pass raw URLs. The requested width comes from the image's required `renderWidthDp` (§11a) — there is no default width.
- **`<FILL IN — theme / orientation lock>`:** if the app is light-only and/or portrait-only, lock it natively — iOS `UIUserInterfaceStyle` + the orientation keys (iPhone and iPad); Android a non-DayNight theme + `forceDarkAllowed=false`, and portrait set in `MainActivity` at runtime (Play Console warns about a manifest `screenOrientation` lock). Delete if the app supports dark mode / rotation.

### 8a. Bundled images — WebP

- Bundled raster images are **WebP**, not PNG/JPEG — much smaller at the same quality, and supported natively on Android and iOS 14+. Convert design exports before committing (`cwebp -q 85 in.png -o out.webp`).
- Icons and vector art stay **SVG**.
- **Only add an asset when something uses it.**

### 8b. Fonts

- **The font-family string must equal the font's internal PostScript name, and the font file must be named the same** — iOS finds fonts by PostScript name, Android by file name, so one matching name works on both.
- Bundled fonts have one file per weight: pick the weight through the family token, never `fontWeight` (Android ignores it for bundled fonts; on iOS the named face already _is_ that weight). Only register faces you actually bundle. `<FILL IN — your families and weights>`.
- **Check the font has every character you need** (currency symbols, punctuation) — missing characters silently fall back to the system font.
- **Check the font licence allows bundling in an app**; never ship trial fonts.

### 8c. Accessibility (HARD RULE)

Built into the shared components (`Pressable`, `Button`, `BottomSheet`, the toast host), so most screens get it for free.

- **Every tappable element has a role, a label when needed, and its state:**
  - `accessibilityRole` (`button`, `link`, `checkbox`, `tab`, …) — the shared `Pressable` / `Button` set `button` by default.
  - `accessibilityLabel` is **required when the visible text doesn't say what it does** — icon-only buttons (✕, ♡, cart, + / −) and images that act as buttons. The label describes the action ("Remove from cart", "Close") and comes from `src/constants/` like any other copy. A button with clear visible text needs no extra label.
  - State goes in `accessibilityState` — `disabled`, `selected`, `checked`, `busy`, `expanded`.
  - `accessibilityHint` only when the result isn't obvious from the label.
- **Touch targets are at least 44×44** (pt / dp). When the visual is smaller (a 20px icon), grow the tap area with `hitSlop` — never so far that it overlaps a neighbouring control.
- **Hide what's decorative:** decorative images, icons and background art get `aria-hidden` (or `accessibilityElementsHidden` on iOS + `importantForAccessibility="no-hide-descendants"` on Android), so the screen reader skips them. An image that carries meaning (a product photo) gets a short label.
- **Announce changes the user can't see:** the toast host and important status changes (added to cart, an error, a price change) call `AccessibilityInfo.announceForAccessibility(message)` — or use `accessibilityLiveRegion="polite"` on Android.
- **Sheets and modals keep the screen reader inside:** the panel sets `accessibilityViewIsModal` (iOS) so VoiceOver can't reach the screen behind; the backdrop is a button labelled "Close" (unless the sheet is blocking).
- **Large text (system font size):** many users set a big system font. Every screen must still work at the largest size — nothing cut off, overlapping or unreachable.
  - Never turn font scaling off for the whole app (`allowFontScaling={false}` everywhere is forbidden).
  - Text containers grow with their text — padding, never a fixed height (§8). Long text wraps, or uses `numberOfLines` with an ellipsis where the design truncates.
  - Cap scaling with `maxFontSizeMultiplier` (around 1.3–1.5) **only** on elements with no room to grow — tab-bar labels, badges, small chips — and set it inside that component (e.g. a `BaseText` variant), not ad hoc on screens.
  - Anything whose size depends on its text (a pinned footer, a header) is measured with `onLayout`, never assumed to be a fixed height.
- **Check every new screen on a real device:** with the screen reader on (TalkBack on Android, VoiceOver on iOS), reach and activate every control and hear sensible labels; then look at it at the largest system font size.

## 9. Figma → UI (HARD RULE)

Figma-sourced UI is built from **node specs, never screenshots**. Before implementing or changing any screen/component with a Figma reference:

1. Pull the exact specs for the **specific node** via the Figma MCP — `get_metadata` to find the node, then `get_design_context` — and use its exact values: font size / line-height, paddings, gaps, icon sizes, hex colours. Use the `figma-to-ui` skill.
2. Screenshots are for layout comprehension only. A measurement read off a screenshot ("looks like 14px") is a defect waiting to ship.
3. Never substitute the "nearest" token when the value differs — **add a token** or use the exact raw hex with a comment naming the node.
4. **Cite the node id in a style comment** so the next diff is verifiable.
5. If a plan defers "exact styling to visual QA", that is a planning bug — specs are fetched **during** implementation.
6. **Subtract the border from the padding** (`padding: spacing.md - 1` for a 1px border). Figma draws borders inside the box; React Native adds them outside the padding.
7. **Size image and video slots with `width` + `aspectRatio`**, never a fixed `height` — a fixed height stretches or crops when the screen width changes (§11a). Keep the Figma width/height in a comment as the fallback ratio.

## 10. Navigation (React Navigation v7)

- **Structure:** a root native stack whose first screen is the tab navigator; detail screens are pushed on the root stack, so the tab bar hides automatically. Tab and stack routes need **different names**.
- Route params typed in `src/navigation/types.ts`: `TabParamList`, `RootStackParamList`, and a flattened `AppParamList` (augments `ReactNavigation.RootParamList` so every `navigate(...)` stays typed).
- **To open a tab from a pushed screen use `navigate('Tabs', { screen: 'X' })`.** The short `navigate('X')` type-checks but silently does nothing.
- **Finish a multi-screen flow (login, checkout, onboarding) with `CommonActions.reset`, not `replace`** — `replace` only swaps the top screen, so Back returns into the flow.

  ```ts
  navigation.dispatch(state => {
    const routes = [...state.routes.filter(r => !FLOW_ROUTE_NAMES.has(r.name)), { name: 'Destination' }];
    return CommonActions.reset({ ...state, routes, index: routes.length - 1 });
  });
  ```

- **Route params carry ids, not whole objects** — objects go stale and can't come from a deep link.
- **A screen that draws content behind its header** uses `headerShown: false` and renders its own header, and handles the top safe-area inset itself.
- **Imperative navigation from non-component code** (services, push handlers, deep links) goes through an exported `navigationRef` + a link-intent queue — never smuggle a `navigation` object into a store. Every link goes through the one parser (§10a).
- **Non-reactive `initialRouteName`:** when the initial route depends on persisted state, read it **once** at mount (`useState(() => …getState())`), not via a reactive selector — a reactive read would swap the route mid-session.
- **Upgrade all `@react-navigation/*` packages together.**

### 10a. Links & deep links (HARD RULE)

- **One parser for every link** — cold-start and warm-start deep links, push notifications, and links inside content all go through the same parser → route map → navigator.
- **Only `openExternal` calls `Linking.openURL`**, and it only allows `http`, `https`, `mailto` and `tel`. Never open `javascript:` or `file:` links from remote content.
- **Never `openURL` a link on your own app's domain** — on iOS it opens your app again instead of a browser, in a loop. Send it to a fallback screen instead.
- **Wait for the navigator to be ready** (`onReady`) before navigating from a link; queue it until then.
- **Treat link params as untrusted input** — validate them with a schema before using them. A screen that shows a WebView takes an id, never a URL param (otherwise any link could open any website inside your app).
- **Native setup that fails silently** (cold start still works, so QA misses it):
  - iOS: `AppDelegate` must forward `application(_:open:options:)` and `application(_:continue:restorationHandler:)` to `RCTLinkingManager`, or links tapped while the app is open do nothing.
  - Android: `launchMode="singleTask"` needs `onNewIntent` + `setIntent`, for the same reason.
  - Android App Links: one wrong path makes the whole domain fail verification, and `assetlinks.json` needs the **Play App Signing** SHA-256 fingerprint (§21).
- **Adding a link path is two edits:** the JS route map and the native config (Android manifest / iOS associated domains).
- **Test links:** app closed, in background, and open × logged in and out × both platforms. Never test a universal link by tapping it inside your own app.

## 11. Performance

**Build for low-memory phones first (HARD RULE).** Most users are on **2–4 GB RAM Android phones** with slower CPUs; Android closes background apps and can kill a foreground app that uses too much memory. Design and test for that device — not the developer's flagship — so the app is smooth on every phone from 2 GB upward.

- **Memory is mostly images.** A decoded image costs about `width_px × height_px × 4` bytes — a 1080×1350 photo is ~6 MB in memory whatever its file size. Request every image at the size it is shown (§11a), never larger.
- **Never render all items of a long list** — use FlashList (virtualised), so only on-screen rows exist in memory.
- **Unmount what isn't visible:** video, maps and camera views unmount when off-screen or when the app goes to the background; heavy hidden subtrees unmount instead of hiding.
- **Keep the JS thread free during scrolling and screen transitions** — no heavy work, parsing or `setState` loops while the user scrolls; defer non-urgent work with `InteractionManager.runAfterInteractions`. Animations run on the UI thread (§11b).
- **Avoid effects that are expensive on weak GPUs** on scrolling surfaces (live blur, many large shadows) — measure them on a low-end device first.
- **Don't keep growing:** going back and forth between screens must not raise memory each time. Cap screens that push copies of themselves (below).
- _Optional:_ if a feature is heavy (autoplay video, rich animation), detect low-memory devices (`getTotalMemory()` from `react-native-device-info`) and turn the heavy part off there.

- Repeating/scrollable content uses **`@shopify/flash-list`**, never `items.map()` in a `ScrollView`. Every horizontal carousel uses one shared **rail** component — callers pass `items`/`onPressItem`/`variant`, the rail owns list + card + spacing. A page made of a few **different** sections can stay a `ScrollView`.
- **Lists:**
  - **Never put a vertical list (FlashList / FlatList) inside a vertical `ScrollView`** — it breaks virtualisation, so every row renders at once. Put content above or below the list in `ListHeaderComponent` / `ListFooterComponent`; if a page needs a long list, the page itself becomes the list. (A horizontal rail inside a vertical page is fine — different direction.)
  - **Keep rows light** — few nested views, small thumbnails, no heavy logic per row. If a big component is reused in a long list, make a slimmer row version of it.
  - **Stable keys:** every list has a `keyExtractor` from the item's id — never the index (an index is fine only for a fixed list that never changes, like skeleton placeholders). For mixed row types in FlashList, set `getItemType`. Check the FlashList major version: v1 needs `estimatedItemSize`; v2 doesn't use it.
- **Taps feel instant:** keep the visible response immediate (pressed state, optimistic update, navigation), and start heavy non-visual work after the press has painted (`requestAnimationFrame` or `InteractionManager.runAfterInteractions`).
- **Module loading:** keep `inlineRequires: true` in the Metro config (the React Native CLI default — never turn it off), so modules load when first used. Module top levels have **no side effects** — no subscriptions, listeners, network calls or global changes — except the app entry `index.js` (crash reporter, background handlers). Creating a store, constant or `StyleSheet` at the top level is fine. _Optional:_ load big, rarely used screens lazily with React Navigation's `getComponent`.
- **Long pages mount in stages:** render the first few sections, the rest after `InteractionManager.runAfterInteractions`.
- Add `React.memo` **only for a measured rail/list re-render problem**, with a comment. Do not blanket-memo every component.
- **No anonymous functions or fresh object/array literals in JSX props** — extract to `useCallback`/named handlers/`useMemo`. **Exception:** callbacks closing over a per-iteration variable in a list (`onPress={() => onSelect(v.id)}`). _If a project turns on React Compiler_ (record it in an ADR), follow the compiler's rules instead: it memoizes automatically, so don't add `useMemo` / `useCallback` by hand except for a stable effect dependency.
- Keep `react-hooks/exhaustive-deps` ON.
- **`freezeOnBlur: true` on navigators** — but it only stops re-renders; screens under the top one stay in memory. A screen that keeps pushing copies of itself (detail → related detail → …) needs a limit on how many stay in the stack.
- **Startup:** don't `await` third-party SDK setup before the first screen shows.
- **No polling, no timers or animations running off-screen.**
- **Android quirks:** `scrollEventThrottle` is ignored (throttle in JS), and a view you measure with `measureInWindow` needs `collapsable={false}` or it never reports.
- **Measure on a release build on a real low-end Android device (2–4 GB RAM), with worst-case data** (a huge cart, very long lists, a big account — typical test data hides the problems). Debug builds and emulators give misleading numbers. Check:
  - **smooth scrolling and transitions** (≈60 fps — no visible stutter; `adb shell dumpsys gfxinfo <package>`),
  - **memory** (`adb shell dumpsys meminfo <package>`) — compare before/after the feature, and it must not keep rising when you open and close the same screens; as a starting target keep idle memory under ~250 MB,
  - **cold start** — the first screen's content should appear in about 2 s on that device.

### 11a. Images & media sizing — dynamic, never hardcoded (HARD RULE)

**Media size is calculated from the screen, never hardcoded.** The **width** comes from the available screen width; the **height** comes from the media's **aspect ratio**. This keeps media correct on every phone width (small budget phones to large phones, foldables, split screen) and keeps memory low.

1. **The mapper sets the aspect ratio** — from the contract's image `width / height`, with a named fallback ratio (from Figma) when the contract has no dimensions. Components never guess it.

   ```ts
   const aspectRatioOf = (w?: number | null, h?: number | null) => (w && h ? w / h : null);
   // in the mapper:
   aspectRatio: aspectRatioOf(image.width, image.height) ?? BANNER_FALLBACK_RATIO,
   ```

2. **The component calculates the slot width** from `useWindowDimensions()` (it updates on rotation, split screen and foldables — never a module-level `Dimensions.get`) minus the layout's padding and gaps, using the same spacing constants the layout uses:

   ```tsx
   const { width } = useWindowDimensions();
   const tileWidth = (width - SECTION_INSET * 2 - TILE_GAP * (COLUMNS - 1)) / COLUMNS;
   const source = useMemo(() => ({ uri }), [uri]);
   const mediaStyle = useMemo(() => ({ width: tileWidth, aspectRatio }), [tileWidth, aspectRatio]);
   <Image source={source} renderWidthDp={tileWidth} style={mediaStyle} />
   ```

3. **Height always follows from `aspectRatio`** — never a fixed `height` on a media slot, and never measured at runtime from `Image.getSize` / `onLoad` (§7). Full-width media uses `width: '100%'` + `aspectRatio`.
4. **The same kind of card uses one shared ratio constant** (e.g. a `CARD_IMAGE_RATIO` in a metrics file), so every card of that kind lines up across screens.
5. **Placeholders and skeletons use the same `width` + `aspectRatio`** as the real media, so nothing jumps when it loads.

**One shared image component, and its request width is a required prop in dp** (`renderWidthDp`, no default — pass the slot width from step 2). It converts to pixels once (`PixelRatio.getPixelSizeForLayoutSize`) and asks the CDN for that size, capping the density multiplier (≈2–3×) and never going above the source size. This is the biggest memory saving on low-end phones (§11).

- **The loading placeholder sits on top of the image** — recycled list cells briefly show the previous item's picture otherwise.
- **Load only on-screen images first** — show one slide initially in carousels, load images below the fold after the first paint, and give the hero image high priority.
- **Thumbnails get thumbnail-sized images** — never the full-resolution file scaled down.

### 11b. Animation — Reanimated, never RN `Animated` (HARD RULE)

- **All animation uses `react-native-reanimated`** so it runs on the UI thread. `Animated` from `react-native`, `Animated.Value`, `Animated.timing` and `useNativeDriver` in new code are defects — they run on the JS thread and drop frames when it's busy.

  ```tsx
  const progress = useSharedValue(expanded ? 1 : 0);
  useEffect(() => { progress.value = withTiming(expanded ? 1 : 0, { duration: DURATION }); }, [expanded, progress]);
  const style = useAnimatedStyle(() => ({ opacity: progress.value }));
  ```

- **Call JS from a worklet with `scheduleOnRN`** (from `react-native-worklets`), not the deprecated `runOnJS`.
- **Scroll-driven animation uses a Reanimated scroll handler**, never `setState` in `onScroll`. Animate transforms and opacity, not height.
- **List reorder animation:** use `layout={LinearTransition}`, and the item `key` must be the item's id — with an index key nothing animates.
- **Keep animation cheap for low-end phones:** animate only `transform` and `opacity` (never `width`, `height`, `top`, margins — those re-layout every frame); keep simple durations (~150–300 ms); don't run many animations at once in a list; stop animations when the component unmounts or goes off-screen, and never run an infinite animation on a hidden screen.
- **Limits on low-end phones** (from the Reanimated team): keep **under ~100 animated components on screen at once on low-end Android** (~500 on iOS). Avoid reading `sharedValue.value` on the JS thread (in render or handlers) — it waits for the UI thread; read it inside worklets. An animated number (counter, price ticker) lives in a shared value shown through an animated text, not in React state updated every tick.
- **Respect the system "Reduce motion" setting** — pass `reduceMotion: ReduceMotion.System` (Reanimated) so users who turn motion off get instant changes.
- **Reanimated and worklets are pinned to exact versions as a pair** — upgrading one alone breaks the build.

### 11c. Video — _If your app uses video_

- **Video plays only when it is on screen and the screen is focused** (`useIsFocused()` inside the player) — otherwise it keeps playing behind the next screen.
- **Unmount players when the app goes to the background** — `paused` still holds the decoder and keeps downloading.
- **No video players inside list/grid cells** — many players at once crash Android. Show an image there; play video on the detail screen.

## 12. Environment & runtime config

- `.env.<env>` per environment (gitignored) + `.env.example` (committed). `<FILL IN — your env names, e.g. .env.dev / .env.stage / .env.prod>`.
- **Config is read ONLY via `getConfig(key)` (sync) / `useConfig(key)` (reactive) (HARD RULE).** `ENV` (from `@/constants`) is used only by the file that declares each key's default; `ENV.*` anywhere else is a defect (enforce with ESLint `no-restricted-syntax`). Never `Config.` directly.
- **Read config when you need it, not at module load** — a value saved in a module-level `const` keeps the first value for the whole session.
- **A new env key touches all of:** the key declaration in `src/constants/` + **every** `.env.*` including `.env.example`, then `yarn check:env`, then the environments doc. `check:env` also confirms each file's `APP_ENV` matches its filename.
- **`.env` files are not secret.** `react-native-config` builds every key into the app binary, where anyone can read it. Deploy tokens and admin keys never go in `.env.*` — read them from CI at build time.
- **Values that differ per platform get separate keys** (`X_ANDROID`, `X_IOS`), picked at runtime with `Platform.OS`.
- **`react-native-config` reads values at native build time**, selected by the iOS scheme / Android flavour — always run via the yarn aliases (`yarn ios:dev`, `yarn android:dev`); a bare `run-ios` picks the first scheme alphabetically, which may be prod. Env changes need a native rebuild.
- **Production builds never contain dev/staging endpoints** or an environment switcher.

### 12a. Remote config — _If your app uses remote config_

- Read remote values through the same `getConfig`/`useConfig` accessor; the env value is the default.
- **Never block the first screen waiting for a config fetch** — use the cached/default values and fetch in the background.
- **The default is what users get when config can't be fetched** — choose each default on purpose.
- **Don't reject config keys you don't recognise** — older app versions will always see keys added for newer ones.
- **Check any URL that comes from remote config** before using it (§22).

## 13. Error handling & feedback

- **Typed errors at the boundary:** an HTTP error (non-2xx), a GraphQL `errors[]` error, a `ResponseValidationError` (Zod mismatch), and a timeout error. A `success:false` envelope is thrown so React Query shows the error UI and it reaches crash reporting.
- **Query/mutation errors are handled at the hook level**; screens render error branches, they don't catch.
- **Tell offline from server errors:** a fetch `TypeError` with no response means offline; 5xx means the server failed. Show the right message for each.
- **Error boundaries at three levels:** the whole app (above navigation — only a "Try again" that remounts), risky screens, and each section of a section list (a broken section renders nothing instead of crashing the page). The app-level boundary uses no theme hooks or providers, so it still renders when those are what crashed.
- Error boundaries don't catch errors in event handlers, promises or timers — those are handled where they happen.
- **User feedback: a global toast** (`useToastStore.getState().show({ message, action?, icon? })`) — never `Alert.alert` for routine feedback. It is a FIFO queue, and the toast host announces each message to screen readers (§8c). When a control has its own error state, show the error there.
- **Never swallow errors** — an empty `catch`, a `.catch(() => {})`, or a fallback that hides failure is a defect. Where an abort is intentional, swallow the `AbortError` **explicitly, with a comment**.
- **If the user doesn't see a failure, still log it** (record a non-fatal error + `__DEV__` warning).
- **Third-party SDK calls must never crash or freeze the app:** wrap them, record their errors, and add a timeout to any call that could hang. Never write `new Promise(async (resolve, reject) => …)` — an error inside it is lost.
- **`.then(onOk, onErr)` does not catch an error thrown inside `onOk`** — another reason to use `try/await` (§2).
- **Full-screen error/empty states are one reusable component driven by a preset registry** (icon/title/message/buttons), consumed in a screen's error/empty branch — never a per-screen inline block. Dispatch is a map, never a switch. A preset button whose action has no supplied handler is dropped.
- _If your app uses NetInfo:_ show one app-wide offline banner using `isConnected` (`isInternetReachable` flickers), and connect it to React Query's `onlineManager` so paused queries resume when the connection returns.

### 13a. Money / commerce — `<FILL IN / DELETE if not a commerce app>`

- **No `parseFloat` on money**, no client-side price math, checkout URLs come **only from the API**.
- `formatMoney` currency policy: `<FILL IN — currency symbol, grouping, fraction-digit rule>`.

### 13b. Crash reporting — _If your app uses a crash reporter_

- **All calls go through one wrapper** (`recordJsError`, `recordNonFatal`), set up in `index.js` before the app renders.
- **No personal data in reports:** use an opaque user id, strip query strings from URLs, turn off default PII collection.
- **Upload source maps and native symbols for every release** and check with a test crash on a release build — otherwise stack traces are unreadable.
- The environment tag comes from the build, never from remote config.

## 14. Tests

- **Jest + `@testing-library/react-native`.** Tests live in `__tests__/` mirroring `src/`. `jest.config.js` maps `@/*` → `src/*`.
- **Every hook in `src/hooks/` and every util in `src/utils/` MUST have a unit test** (keep `__tests__/hooks/` and `__tests__/utils/` mirroring `src/` one-to-one).
- **Screens:** at minimum a loading/error/empty branch test; add interaction tests for stateful UI.
- **Mock at the boundary only** — the boundary fetcher / native modules / the SDK wrapper — **never** internal modules. Fetcher tests mock `@/services` and leave the real schema + mapper in place:

  ```ts
  jest.mock('@/services', () => ({ getConfig: jest.fn(), boundaryFetch: jest.fn() }));
  // getConfig('USE_MOCK') => false to take the live branch; assert the mapped view-model
  ```

- **When mocking a hook for a screen test, mock the barrel path (`@/hooks`)** and import from the same path in the screen — Jest module mocking is path-exact.
- Jest hoists `jest.mock(...)` factories above imports — any variable referenced inside a factory must be `mock`-prefixed (`mockNavigate`) or defined inside the factory.
- Test names describe behaviour ("throws when the id is unknown"), not implementation. **Never weaken a test to make it pass.**
- **One behaviour per test**, with no `if` / loops deciding what to assert inside a test. Don't test library or framework code (React Query, Zod, React Native itself) — test what *your* code does.
- **Mocks must behave like the real thing — never better.** A mock that returns something the real platform never can makes tests pass for an app that is broken.
- **Jest can't see everything.** It uses Node's `URL` (not React Native's), never fires `onLayout`/`measureInWindow`, treats `Platform.OS` as iOS, and ignores TypeScript errors. Check those things on a real device.
- **A test must fail when the bug is put back** — otherwise it isn't testing anything.
- **The full test run never uses `--passWithNoTests`**, so it can't pass with zero tests (a changed-files-only run may).
- Raise Testing Library's `asyncUtilTimeout` (~15 s) and keep Jest's `testTimeout` higher (~30 s), so a slow test reports which query it was waiting on.
- **Tab navigation tests assert the nested call** (`navigate('Tabs', { screen })`). Tests that render focus-aware components mock `useIsFocused`.
- **Run date/time tests in more than one time zone.**
- Add untranspiled ESM packages to `transformIgnorePatterns` or mock them; global mocks for reanimated / worklets / gesture-handler live in `__mocks__/`.
- **End-to-end tests (optional, never a CI gate):** find elements by `testID` only and wait for conditions — no coordinates, no fixed sleeps.
- **The green bar is `yarn lint --max-warnings=0 && yarn typecheck && yarn test`** — the flag matches CI, where a lint warning fails the build.

## 15. Documentation is part of the PR

Update `docs/` in the same PR as the code — a reviewer reads the docs diff alongside the code diff.

- **New decision** (library, pattern, trade-off) → new ADR under `docs/decisions/`, linked from `decisions/README.md`. **Check the highest ADR number on the base branch first** — parallel branches pick the same number.
- **New module / screen / subsystem** → add/update `docs/architecture/`. Each architecture doc covers: what it is, how it works, where the code lives, gotchas, related decisions.
- **New env key** → the environments doc + `.env.example`.
- **New domain term** → `docs/glossary.md`. **Operational procedure** → a runbook under `docs/runbooks/`.
- **Reversing a decision** → set the old ADR to `Superseded by NNNN` and write a new one; never edit history.
- **New canonical pattern** → this file, §17.
- **Comments explain only what the code can't** — a `TODO`/`FIXME`, a risk, a platform quirk, an ordering dependency, a Figma node id. Never restate what the code does.
- **Delete code, env keys and config keys that nothing uses any more**, in the same PR that made them unused.
- **Every PR description explains *why*** — the reason for the change (the user or business need, the bug's cause) — not only what changed.
- **Keep `CLAUDE.md` short** — it loads into every session. Detail goes here or in an ADR.

## 16. Forbidden (lint / husky / convention enforce most)

**Types & structure:** `any` / `as never` · deep relative imports instead of `@/` · a barrel import inside shared infrastructure (§1) · business logic in a screen · a second copy of a mechanism that already exists · a component defined inside a screen file · a core component as a loose file without its own folder · importing a component from another area's folder (promote it to `common/`) · **a React Native primitive where a project component exists** (§1b) · a near-copy of an existing component instead of a `variant` · `interface` (use `type`) · `enum` (use a union / `as const`) · `@ts-ignore` / `@ts-nocheck` · a non-null `!` · the `object` type · a fake id (`''` / `'0'` / `'-1'`) for a missing value · `||` for a default (use `??`) · a `.then` chain (use `async/await`) · independent awaits run one after another · `defaultProps` / `propTypes` · more than 5 positional parameters · a component or hook declared with `function` (use an arrow function) · `inlineRequires: false` · side effects at a module's top level (outside `index.js`) · a `useEffect` that copies props/state into state · a `useEffect` that performs a user action · an effect that adds a listener/timer without a cleanup · a component defined inside another component · an `exhaustive-deps` disable without a comment · reading a whole store or a broad Context where one value is needed (§2a).

**Data:** a direct third-party call bypassing the data boundary · a fetch without a Zod schema · a request without a timeout · a query string in an error message · a `switch` for `kind`/type dispatch (use a map) · name-driven layout branching · `status === 200` as the success check · a hand-set `Content-Type` on `FormData` · a pagination loop without a cap · position-based ids · made-up data shown as real · **hardcoded static data inlined in a component instead of `src/constants/`, or an API stand-in outside `src/mocks/` (§1a)** · a top-level fixture import in a fetcher.

**State:** a persisted store missing `skipHydration:true`, its `App.tsx` rehydrate, an explicit `version`, or an allow-list `partialize` · `partialize: s => ({ ...s })` · a token or password in a persisted store.

**Config & security:** `Config.` access, or `ENV.*` outside the key-declaration file (use `getConfig`/`useConfig`) · config read at module load · a secret in `.env.*` · `new URL()` for a security check · `endsWith('domain.com')` host matching · `Linking.openURL` outside `openExternal` · a WebView screen that takes a URL param · `console.log` in release builds.

**UI:** **any colour literal (hex/`rgba()`/named) in a screen or component — colours come only from theme tokens; add a token if none fits (§8)** · `fontWeight` beside a brand family · a hardcoded font-family string · raw `<Text>` for themed copy where `BaseText` fits · a spacing/typography magic number instead of a token · `moderateScale`/metrics-scale helpers · Figma values read off a screenshot · `Image.getSize`/`onLoad`-driven layout · a fixed `height` on an image slot · inline `style={{}}` literals · anonymous functions in JSX props (except per-iteration list closures) · `map()`-in-`ScrollView` for dynamic lists · a vertical list inside a vertical `ScrollView` · an index as the key of a list whose items can change · a submit/pay/add button without the shared double-tap guard · an icon-only button without an `accessibilityLabel` · a touch target under 44×44 without `hitSlop` · `allowFontScaling={false}` across the app · a hardcoded height for anything that contains text · **`Pressable` from `react-native`** (use the shared one; only a full-screen backdrop may use `RNPressable`) · `TouchableOpacity` / `TouchableHighlight` · a one-sided dashed border · a PNG/JPEG for a new bundled image · an image without `renderWidthDp` · a hardcoded media `height` or size (use width + `aspectRatio`) · `Dimensions.get` at module level for layout (use `useWindowDimensions`) · a hardcoded status/navigation-bar height · a bottom-pinned control without the bottom safe-area inset · animating `width`/`height`/`top` (animate `transform`/`opacity`).

**Motion & overlays:** **`Animated` from `react-native`** (`Animated.Value`, `Animated.timing`, `useNativeDriver`) · `runOnJS` (use `scheduleOnRN`) · an index as the `key` of an animated list item · **a hand-built `Modal` + animation for a bottom sheet** (use the shared shell — §19) · a gesture inside a `Modal` without its own `GestureHandlerRootView` · React Native's own `KeyboardAvoidingView` (use keyboard-controller's).

**Navigation & media:** a bare `navigate('<TabRoute>')` from a pushed screen · `replace` to end a multi-screen flow · a video player in a list cell.

**Errors & process:** `Alert.alert` for routine feedback · empty `catch` / `.catch(()=>{})` / failure-hiding fallbacks · `new Promise(async …)` · a new hook/util without a unit test · weakening a test to force green · a dependency added without checking need and size (§25) · a React Native upgrade mixed with feature work · a commit made before human verification (§17a) · shipping code without its docs diff · hand-editing `project.pbxproj` (§21) · a release build that falls back to debug signing.

`<FILL IN — add your commerce/price rules if applicable: parseFloat on money, client-side price math, checkout URLs not from the API>`

## 17. Evolving the DNA

WHEN a feature or fix needs a pattern with no precedent here, THE SYSTEM SHALL: (1) design it consistent with the closest existing pattern, (2) get it approved at plan time (features) or flagged in the fix PR, (3) **add it to this file in the same PR** — with a copy-me snippet and, where a trade-off was made, an ADR it links to. The DNA is never bypassed "just this once".

**When a rule changes, existing code is not rewritten all at once.** Note the old pattern as legacy under the rule here ("Legacy: … — update when touched"), write all new code the new way, and update old code when you next work on that file. A large rewrite needs its own plan and approval.

### 17a. Human verification precedes every commit (HARD RULE)

WHEN code changes are complete, THE SYSTEM SHALL **stop and present them for human verification, and commit only after explicit approval**. Finishing the work is not permission to record it.

The order is: change → run the bar (`yarn lint --max-warnings=0 && yarn typecheck && yarn test`, plus `yarn check:env` if env changed) → drive the real app where there is anything to see → **present, and wait** → commit on approval → push only when the whole change is approved.

Why: **a green bar is not a correct feature** — tests can all pass while the real screen is broken, and only using the app finds it. And **commits are the unit of review** — committing first and asking later means the human reviews history instead of deciding it, and a rejected approach costs a revert instead of an edit.

Practically: keep the work uncommitted, and report what changed, what was verified and how, and what is still open. If the human asks for changes, fold them into the same uncommitted set and present again. **This binds agents especially:** an agent that commits as it goes has taken the approval decision for itself.

## 18. Forms & local validation (zod-backed)

Data-entry forms follow one shape. There is no form library — validation reuses **`zod`** (already the wire firewall, §3) as a **validation-only schema colocated with a behaviour hook**. `src/schemas/` stays wire-only; a form schema lives next to its hook.

- **A `use<Screen>Form` hook owns state + validation** and exposes `{ values, errors, setField, validateAndSave(onValid) }`. `setField` clears that field's error as the user types; `validateAndSave` `safeParse`s and either sets per-field errors or calls `onValid`. Rules that link two fields (a new month invalidates the chosen day) also live in the hook.
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
- **One-time codes use the platform's autofill** (iOS `textContentType="oneTimeCode"`, Android SMS autofill) — never read the clipboard.
- **Save/queue feedback is the global toast** (§13), never `Alert.alert`.
- **The hook gets a unit test** (§14); the screen tests the valid/invalid branches.

### 18a. Keyboard handling

- **Use `react-native-keyboard-controller`, not React Native's `KeyboardAvoidingView`** — RN's version is unreliable on modern Android and inside modals.
- A scrolling form uses the keyboard-aware scroll view; a short screen with a bottom button uses keyboard-controller's `KeyboardAvoidingView`.
- **Every scroll view that contains a text field sets `keyboardShouldPersistTaps="handled"`** — otherwise the first tap while the keyboard is open only closes the keyboard, and the button seems dead.
- **The keyboard's Done/Go key submits the same way as the screen's button** (`onSubmitEditing` → the same handler).

## 19. Overlays — sheets, dialogs, full-screen modals

**A React Native `Modal` is a separate native window**, so:

- **Gestures inside a `Modal` need their own `GestureHandlerRootView`** — without it they silently do nothing.
- **A `Modal` covers everything**, including the app's toast — a modal that needs toasts renders its own toast host.
- **Don't open a `Modal` on top of another `Modal`** — it's unreliable, especially on iOS. Change the content inside one modal instead.

**Bottom sheets — one shared `BottomSheet` shell (HARD RULE).** It provides the backdrop, the sliding panel, a header, a scrolling body and an optional footer. Each sheet only provides its content — never hand-build a `Modal` + animation per sheet.

- The shell animates with Reanimated (§11b); the RN `Modal` only hosts it (`animationType="none"`). It stays mounted until the closing animation finishes.
- Drag-to-close is on the header only, so it doesn't fight the scrolling body.
- **A sheet with a long list** passes the list itself as its body (turn the shell's own scrolling off) — never a list inside the sheet's `ScrollView` (§11).
- **Bottom spacing inside the Modal (edge-to-edge, 3-button navigation):** the app-root safe-area values are for the main window, not the Modal's. So the shell's `Modal` sets **`statusBarTranslucent` and `navigationBarTranslucent`** (the Modal window draws under both bars) and **nests its own `SafeAreaProvider`** inside, then reads `useSafeAreaInsets().bottom` there — the real inset of the Modal's window on every device. Don't calculate it from window/screen height differences — that guess over-pads or under-pads on some phones.

  ```tsx
  <Modal transparent visible={mounted} animationType="none" onRequestClose={onClose} statusBarTranslucent navigationBarTranslucent>
    <SafeAreaProvider initialMetrics={initialWindowMetrics ?? ZERO_METRICS}>
      <SheetBody /> {/* reads useSafeAreaInsets().bottom here */}
    </SafeAreaProvider>
  </Modal>
  ```

  The inset goes on **whatever is last in the panel**: the scroll content's bottom padding, or — when there is a pinned footer — the footer, padded by `inset + a small clearance` so its buttons never sit on the navigation bar. Test with gesture and 3-button navigation.
- The shell sets `keyboardShouldPersistTaps="handled"`. The backdrop colour is a token.
- The panel sets `accessibilityViewIsModal` (iOS); the backdrop is a button labelled "Close" unless the sheet is blocking (§8c).
- Before using a third-party sheet library, test it on a device with your exact Reanimated and gesture-handler versions.

**Full-screen modals** use the RN `Modal` directly with `onRequestClose` (required for the Android back button) and one close handler for ✕, the button and back.

**Centred dialogs** use a transparent `Modal` where the dimmed backdrop is a **sibling** placed under the card — never wrap the card inside the backdrop's `Pressable`, or taps on the card close the dialog.

```tsx
<Modal visible={visible} transparent animationType="fade" onRequestClose={onDismiss}>
  <View style={styles.root}>
    <RNPressable style={styles.backdrop} onPress={onDismiss} accessibilityRole="button" accessibilityLabel={COPY.close} /> {/* full-screen backdrop: RN's Pressable, no pressed flash (§8) */}
    <View style={styles.card}>…</View>                        {/* later sibling ⇒ on top */}
  </View>
</Modal>
```

## 20. REST endpoints — `<FILL IN / DELETE if boundary is GraphQL-only>`

If some backend surfaces are REST, they go through **one** REST sibling of the boundary fetcher — same rules (timeout, auth, redaction, schema), different transport:

```ts
type Method = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';

export async function boundaryRestFetch<S extends z.ZodType>(
  path: string,
  schema: S,
  init: { method: Method; body?: Record<string, unknown> | FormData; skipAuth?: boolean; timeoutMs?: number },
): Promise<z.infer<S>> {
  // same timeout / abort / auth / redact handling as boundaryFetch (§3)
  const url = `${getConfig('API_BASE_URL')}${path}`;
  const response = await timedFetch(url, init); // FormData bodies are passed as-is — no Content-Type (§3b)
  if (!response.ok) {
    const errorBody = await response.json().catch(() => null); // a bad error body is not the error being reported
    throw new BoundaryRestError(response.status, redact(url), errorBody?.code ?? null);
  }
  const parsed = schema.safeParse(await response.json());
  if (!parsed.success) throw new ResponseValidationError(redact(url), parsed.error.issues);
  return parsed.data;
}
```

- **Every call passes an explicit `method`** — don't guess it from whether there's a body (`DELETE` usually has none).
- **If the API wraps responses in `{ success, data, error }`**, one small wrapper checks the envelope and the caller's schema checks only the `data`. Use one shared envelope schema, not a copy per area.
- **Errors are typed and code checks `error.code`, never `error.message`.**
- **Every call still passes a Zod schema** (§3); fetchers keep the `getConfig('USE_MOCK')` branch; mapping still lives in `src/mappers/`. Never write a raw `fetch` in a hook.
- **Mutations that aren't safe to repeat set `retry: 0`** with a comment — a retried create can duplicate the record.
- Do not add another client — extend this one if a new verb/need appears.

## 21. Build, release & native config

**Android:**

- **Keep R8 on for release builds**, and add keep rules for anything loaded by reflection — including `-keep class **.BuildConfig { *; }`, or R8 removes it and every env value becomes empty in release. If a crash happens only in release, it's usually a missing keep rule: add a targeted `-keep`, don't turn R8 off. Test the release build on a device after changing these rules.
- **Upload an AAB to the store**, not a universal APK. Keep Hermes and the New Architecture on.
- **Every native library must support 16 KB memory pages** — Google Play requires it for apps targeting Android 15+. Check before adding a native library or raising `targetSdk` (§25).
- **Release signing never falls back to the debug key.** Signing passwords come from the developer's machine or CI, never from a file in the repo; a release build with no credentials must fail.
- **Check the signing certificate of every build before uploading.** The first AAB you upload sets your upload key permanently — never upload with a test keystore.
- **Back up the keystore and its password together** in a password manager, outside the repo, and never send it over chat or email.
- **Play re-signs your app.** Any service that checks your app's SHA fingerprint (maps keys, Google sign-in, App Links) needs **both** the Play App Signing fingerprint and the upload fingerprint — otherwise it works on your local release build but fails for users who install from Play.
- **`versionCode` must go up on every upload.** Keep Android `versionName` and iOS `MARKETING_VERSION` the same (a test can check this).
- **Edge-to-edge is on** (`edgeToEdgeEnabled=true`) — every screen follows §7a; test with both gesture and 3-button navigation.
- **Give dev/staging builds a different application id** (a suffix) so they can be installed next to the store app.
- **Always test a release build before uploading** — some problems only appear in release.

**iOS:**

- **Choose supported devices on purpose.** The default template includes iPad, and Apple may also list the app on Mac and Vision Pro. If you don't support them, set `TARGETED_DEVICE_FAMILY = 1` and turn off the Mac/Vision options.
- **Every permission description key (`NS…UsageDescription`) that a bundled library needs must be present**, even if your code never asks for that permission — Apple scans the binary and rejects the upload otherwise.
- **Never hand-edit `project.pbxproj`** — use Xcode or a script, and review its diff.
- **Run `pod install` after every `yarn install`** that adds or updates a native package, and commit `Podfile.lock`.
- **Some CLI tools rewrite `Info.plist` / `AndroidManifest.xml` and delete comments** — review those diffs line by line.

## 22. Security

- **Anything inside the app is public** — `.env` values, config files, API keys. Never ship admin tokens. Restrict every API key you do ship (to your package name + fingerprints on Android, your bundle id on iOS).
- **Never use `new URL()` for a security check** (allowed hosts, WebView navigation). On the device, React Native's `URL` is a simple regex that can be tricked — `https://attacker.example/x@yourdomain.com` reads as `yourdomain.com`. Jest uses Node's correct `URL`, so tests won't catch it. Use one small, tested URL parser that rejects anything it can't parse.
- **Allowed-host checks match the exact host or a real subdomain** (`.yourdomain.com`) — `endsWith('yourdomain.com')` also accepts `evilyourdomain.com`. Require `https`.
- **WebViews — _If your app uses WebView_:** allow only your trusted hosts (`originWhitelist` + `onShouldStartLoadWithRequest`), block `http`, file access and pop-up windows. On Android `onShouldStartLoadWithRequest` isn't called for the first page, so check the starting URL yourself. Never add `injectedJavaScript` or `onMessage` to a payment WebView.
- **Network:** iOS `NSAllowsArbitraryLoads = false` (in extensions too); Android blocks cleartext traffic. If you use certificate pinning, ship a backup pin from day one.
- **Never save or log passwords or tokens.** Release builds remove `console.log` / `info` / `debug` (keep `warn` and `error`). Never log full deep-link URLs or push tokens outside `__DEV__`.
- **Re-encode photos users upload** so location data (EXIF/GPS) is removed.
- **Before merging:** run a secret scanner and a dependency vulnerability check that block the PR. Pin CI actions by commit SHA, and install with a frozen lockfile. `<FILL IN — your secret scanner and dependency scanner>`.
- **When you force a sub-dependency version** (`resolutions`), write down why and when it can be removed.

## 23. Auth & session — `<DELETE if the app has no sign-in>`

- **Keep the access token in memory and the refresh token in the Keychain** — never in MMKV or a persisted store.
- **Requests send the token automatically.** Login, refresh and public endpoints pass `skipAuth` — the refresh call must never try to refresh itself (that can freeze every request with no error). Test this.
- **Only one token refresh runs at a time** — other requests wait for it. Treat a token that expires within a minute as expired.
- **On an auth error, refresh and retry once** — only if the refresh actually gave a new token. Never loop.
- **Only the server can end a session.** A timeout, being offline or a 5xx must not log the user out. An empty Keychain doesn't prove the session ended either (it is also empty mid-login).
- **Logout works offline and instantly:** clear all user data synchronously (the whole query cache, user stores, Keychain entries, analytics identity), cancel in-flight requests, and ignore anything that arrives afterwards. Never wait on the network to log out.
- **All login methods go through one `completeLogin` function**, so every login does the same setup. Login starts by clearing any old credentials.
- **Account deletion must be in the app** (both stores require it) and must actually delete on the server before the app says it's done.

## 24. Permissions

- **Never ask at launch.** Ask when the user reaches the feature that needs it, and explain why.
- **Ask one permission at a time** and wait for each answer — iOS shows only one system dialog at a time.
- **Never save the answer; always read the current status** — the user can change it in Settings at any time.
- **Denied but still askable → ask again; permanently denied → open Settings.**
- **On Android 12+, request precise and approximate location together** — asking for precise alone is silently ignored.
- **iOS tracking (ATT):** only if the app reads the advertising id; never ask during launch (it can't show then).
- **Turn off third-party SDKs' automatic permission prompts** so your app decides when to ask. Fetch the push token only after notification permission is granted.
- **Use the system photo picker** — it needs no permission.

## 25. Third-party SDKs & native modules

- **Each third-party SDK is imported in exactly one file** in `src/services/`, which exposes simple functions (`track`, `recordJsError`). Screens, hooks and stores never import the SDK directly — swapping a vendor then changes one file, and tests mock that one file.
- **Set up each SDK once, safely:** repeated calls share the same setup; a failed setup can be retried; setup never blocks the app from starting.
- **Before adding any dependency, check that you really need it** — can the platform, an existing dependency or a few lines of code do it? — **and check its size** (bundlephobia or pkg-size.dev, including the packages it pulls in). For a **native** library also check: New Architecture support, recent maintenance, that it works with your React Native / Reanimated versions, and **Android 16 KB page-size support** (Google Play requires it for apps targeting Android 15+).
- **Measure the JS bundle** when you add a big dependency and before each release, and compare with the previous size:

  ```bash
  npx react-native bundle --platform android --dev false --minify true --entry-file index.js \
    --bundle-output /tmp/main.jsbundle --sourcemap-output /tmp/main.map
  npx source-map-explorer /tmp/main.jsbundle /tmp/main.map
  ```

- **Remove unused dependencies.** Native packages are linked into the app even when no code uses them, adding size and startup time. `npx depcheck` lists candidates — but confirm each one is really unused before removing it (it wrongly flags packages used only by Babel / Metro / Jest config or by native setup).
- **Upgrade React Native on its own** — one version at a time, as its own release, never mixed with feature work or another big change. Use the React Native Upgrade Helper for the native file changes, upgrade matched libraries together (Reanimated + worklets, the React Navigation packages), rebuild native, and test a release build on both platforms. Expect more error reports right after an upgrade — newer versions surface errors older ones hid.
- **Pin native libraries to exact versions.** Patch a dependency with `patch-package`, never by editing `node_modules`.
- **Custom native modules** (only when no library does the job) use a TurboModule spec + codegen, wrapped in one `src/services/` file. Use `TurboModuleRegistry.get` (not `getEnforcing`) when the module might be missing on a platform, so the app doesn't crash on import.

## 26. App lifecycle

- **Start-up order:** storage → restore saved state → (security / update checks) → app. If any start-up step fails, show an error screen — never a blank or frozen screen.
- **Hide the splash screen when start-up has finished on every path** (app, error screen, block screen), not when navigation mounts.
- **React StrictMode runs effects twice in development** — make every effect safe to run twice (it cleans up after itself, §2a). Work that must happen only once per app launch (SDK setup) goes in `index.js` or behind a module-level `didInit` flag inside a function called at start-up — not a ref inside a component.
- **Ship a force-update check in your first release** — it's the only way to make the oldest builds update later. If the check fails, let the user in (fail open).
- _If your app uses OTA updates:_ OTA can only change JavaScript — any native change needs a store release **and** a version bump on both platforms. OTA does nothing in debug builds, so test it on a release build.
- _If your app asks for store reviews:_ use only the OS review dialog — a custom "do you like the app?" prompt first breaks store policy.

## 27. Analytics & privacy — _If your app uses analytics or marketing SDKs_

- **Screens call one `track(event, data)` function**; only the analytics service talks to the SDKs. A failing analytics SDK must never break the app.
- **No personal data in analytics** — send ids and counts, never names, emails or phone numbers. Use an opaque user id.
- **Ask for consent before collecting**, where the law requires it, and don't start tracking SDKs until then.
- **Identify the user on login and reset on logout.**
- **Store privacy forms** (App Privacy, Play Data safety, the iOS privacy manifest) must match what the code actually collects — the `/store-submit` skill checks this.

## 28. Release checklist

Before submitting to a store:

- No `TODO`s or buttons that do nothing; no placeholder or test data.
- Production env files are correct, with mock mode off.
- Test the **exact build you'll upload** on a real device, including signing (§21) and crash-report symbols (§13b).
- Give the reviewer a working demo account.
- The privacy policy opens without logging in; account deletion works (§23).
- Run **`/store-submit`** to check the store listing against the code.

## 29. Silent failures

These show no error and break no test — the app "just doesn't work". Read the linked section before touching the area.

- `new URL()` on device can be tricked — Jest won't show it (§22).
- A barrel import loop makes a component `undefined`; the error points at the wrong file (§1).
- Zustand brings back deleted saved fields; leaving out `version` means version 0 (§5).
- MMKV ignores a new key on a store that's already open; a hex key is half-strength (§5).
- A response arriving after logout writes the previous user's data back (§5, §23).
- A request with no timeout keeps the loading screen forever (§3).
- One unknown GraphQL field fails the whole query, while mock tests pass (§3a).
- A disabled query never becomes "success"; "not loaded" shown as "empty" (§4).
- Config read at module load keeps its first value all session (§12). Every `.env` value ships inside the app (§12).
- R8 strips `BuildConfig` — env values are empty in release only (§21).
- `navigate('<TabRoute>')` from a pushed screen does nothing (§10). `replace` leaves the flow one Back away (§10).
- Deep links tapped while the app is open do nothing without the iOS/Android native setup (§10a). Opening your own domain loops back into the app (§10a).
- Play re-signing breaks fingerprint-restricted services for store installs only (§21).
- Gestures inside a `Modal` are dead without their own root; the app's safe-area insets don't apply inside a `Modal` — buttons end up under the 3-button bar (§19, §7a).
- A bottom-pinned button without the bottom inset sits under the Android 3-button bar — invisible on gesture-nav phones and new emulators (§7a).
- A full-resolution image in a small slot costs megabytes of memory each — low-end phones slow down or close the app (§11, §11a).
- React Native's `Pressable` shows no pressed state (§8). A one-sided dashed border renders nothing on iOS (§8).
- `freezeOnBlur` doesn't free memory — self-pushing screens keep growing (§11).
- `paused` video keeps downloading (§11c). An index `key` stops list animations (§11b).
- Android 12+ ignores a precise-only location request (§24).
- `FormData` with a hand-set `Content-Type` fails (§3b). A raw `+` in a URL becomes a space (§3b).
- `new Date('YYYY-MM-DD')` is UTC midnight (§2).
- OTA does nothing in debug builds (§26).
- A mock that does more than the real platform makes tests pass for a broken app (§14).
