# figma-to-ui: Build Conventions Reference

This file is the build-time reference for the `/figma-to-ui` skill. It contains
token tables, file anatomy, code patterns, and constraints. The skill's process
narrative lives in `SKILL.md`; this file is the lookup reference during the build phase.

---

## 1. Theme-token mapping

### Spacing

Import: `import { spacing } from '@/theme';`

All spacings from `src/theme/spacing.ts` — snap every Figma gap/padding to the nearest value.
Do not hardcode numeric pixels.

| Token             | px  |
| ----------------- | --- |
| `spacing.nano`    | 6   |
| `spacing.xs`      | 4   |
| `spacing.sm`      | 8   |
| `spacing.smPlus`  | 10  |
| `spacing.md`      | 12  |
| `spacing.mdPlus`  | 14  |
| `spacing.lg`      | 16  |
| `spacing.lgPlus`  | 18  |
| `spacing.xl`      | 20  |
| `spacing.xxl`     | 24  |
| `spacing.xxxl`    | 32  |
| `spacing.huge`    | 40  |
| `spacing.massive` | 48  |

If a Figma gap/padding has no close match, raise a token-gap question — do not hardcode.

### Typography

Import: `import { typography } from '@/theme';`

All tokens from `src/theme/typography.ts`. Spread the token into a style:
`{ ...typography.brandBody, color: colors.text }`.

**System tokens** (Roboto/system fallback):

| Token                     | Weight | Size | Line height | Notes |
| ------------------------- | ------ | ---- | ----------- | ----- |
| `typography.h1`           | 700    | 32   | 40          |       |
| `typography.h2`           | 700    | 24   | 32          |       |
| `typography.h3`           | 600    | 20   | 28          |       |
| `typography.h4`           | 600    | 18   | 24          |       |
| `typography.body`         | 400    | 16   | 24          |       |
| `typography.bodySmall`    | 400    | 14   | 20          |       |
| `typography.caption`      | 400    | 12   | 16          |       |
| `typography.label`        | 500    | 14   | 20          |       |
| `typography.button`       | 600    | 16   | 24          |       |
| `typography.display`      | 400    | 36   | 44          | serif |
| `typography.displayLarge` | 400    | 44   | 52          | serif |
| `typography.serifH2`      | 400    | 28   | 36          | serif |

**Brand tokens** (your project's brand sans/serif — example scale below; replace token names, sizes, and font families with your own):

| Token                       | Size | Line height | Use case                                   |
| --------------------------- | ---- | ----------- | ------------------------------------------ |
| `typography.kicker`         | 24   | 32          | Italic serif eyebrow above headings        |
| `typography.bannerHeading`  | 56   | 64          | Hero/banner headline                       |
| `typography.brandH1`        | 32   | 38          | Promo / H1 heading                         |
| `typography.brandH2`        | 28   | 36          | Section heading (e.g. featured products)   |
| `typography.brandH3`        | 24   | 28          | Category-card / sub heading                |
| `typography.brandH4`        | 20   | 24          | Section sub-heading (recommendation grids) |
| `typography.brandH5`        | 18   | 24          | Offer headline (editorial "% OFF" cards)   |
| `typography.brandBody`      | 14   | 20          | Body / product title + price               |
| `typography.brandBodyLarge` | 16   | 22          | Promo body copy                            |
| `typography.brandLabel`     | 16   | 22          | Button / CTA label                         |
| `typography.brandTagline`   | 14   | 20          | Italic serif small eyebrow / tagline       |
| `typography.heroKicker`     | 20   | 28          | Italic serif hero/banner kicker            |

> Note: `brandBody` is the correct name for "body / product title + price". A `brandH5` (18/24)
> exists for offer headlines; there are still no `h5`/`h6` _system_ tokens.
>
> **This table is a snapshot.** `src/theme/typography.ts` and
> `src/theme/resources/LightThemeResources.ts` are the source of truth — read them for the
> current token set before snapping. If you add a token (with the user's OK on a flagged gap),
> add it to these tables too so they don't drift.

### Colors

Import via `useThemeStyles` — access as `colors.<key>` inside the style factory.
All keys from `src/theme/resources/LightThemeResources.ts`:

| Token                         | Hex / value          | Use case                               |
| ----------------------------- | -------------------- | -------------------------------------- |
| `colors.tint`                 | `#111111`            | Icon tint                              |
| `colors.primary`              | `#111111`            | Primary fill / buttons                 |
| `colors.secondary`            | `#FFFFFF`            | Secondary fill                         |
| `colors.text`                 | `#111111`            | Body text                              |
| `colors.textSecondary`        | `#666666`            | Captions, secondary labels             |
| `colors.textDisabled`         | `#AAAAAA`            | Disabled state                         |
| `colors.textInverse`          | `#FFFFFF`            | Text on dark backgrounds               |
| `colors.background`           | `#FFFFFF`            | Screen / card background               |
| `colors.backgroundSecondary`  | `#F5F5F5`            | Off-white container, image placeholder |
| `colors.backgroundInverse`    | `#111111`            | Inverted surface                       |
| `colors.border`               | `#E0E0E0`            | Borders                                |
| `colors.borderFocus`          | `#111111`            | Focused input border                   |
| `colors.divider`              | `#E9EBED`            | Divider lines                          |
| `colors.success`              | `#2E7D32`            | Success state                          |
| `colors.error`                | `#C62828`            | Error state                            |
| `colors.warning`              | `#F57F17`            | Warning state                          |
| `colors.info`                 | `#0277BD`            | Informational state                    |
| `colors.<brandAccent>`        | `#RRGGBB`            | Your brand accent(s) — define per project (e.g. a sale/price accent) |
| `colors.overlay`              | `rgba(0, 0, 0, 0.5)` | Modal/image overlay                    |
| `colors.transparent`          | `transparent`        | Transparent fills                      |
| `colors.skeletonShimmerStart` | `#EEEEEE`            | Skeleton shimmer start                 |
| `colors.skeletonShimmerEnd`   | `#D2D2D2`            | Skeleton shimmer end                   |

**Color rules (binding):**

- Components must use theme tokens — never raw hex values in JSX/StyleSheet.
- If a Figma color matches no token, flag it as a **token gap** and ask the user before
  proceeding. Do not invent a token or hardcode in the component.
- For alpha variants, use the `withAlpha(hexColor, 'AA')` util from `@/utils` — it appends
  the two-hex-digit alpha suffix so you stay in hex format. Example: `withAlpha(colors.textInverse, '80')`.
- `colors.overlay` is an exception: it is already an rgba string (defined in the theme for
  the one intentional use case). Do not use it as a pattern for new color values.

---

## 2. Styling pattern

### `useThemeStyles`

Defined in `src/hooks/useThemeStyles.ts`. Use it for every component stylesheet.

```ts
// src/components/<area>/MyComponent.tsx
import { useThemeStyles } from '@/hooks';
import { spacing, typography } from '@/theme';

const useStyles = () =>
  useThemeStyles(({ colors }) => ({
    // The factory receives UseThemePropsType ({ mode, theme, setMode, colors });
    // ({ colors }) is a partial destructure of the commonly-used field.
    container: {
      padding: spacing.lg,
      backgroundColor: colors.background,
    },
    title: {
      ...typography.brandH2,
      color: colors.text,
    },
    caption: {
      ...typography.caption,
      color: colors.textSecondary,
    },
  }));
```

Call `useStyles()` at the top of the component (not `StyleSheet.create`).
When you need colors outside a style factory (e.g. for a prop value), use `useThemeValues`:

```ts
import { useThemeValues } from '@/hooks';
const { colors } = useThemeValues();
```

### `FlexBoxStyles` helpers

Defined in `src/theme/FlexBox.ts`, exported from `@/theme`.
Spread into a style array rather than re-declaring layout primitives inline.

| Key                                   | Value                                                         |
| ------------------------------------- | ------------------------------------------------------------- |
| `FlexBoxStyles.row`                   | `{ flexDirection: 'row' }`                                    |
| `FlexBoxStyles.rowCenter`             | `{ flexDirection: 'row', alignItems: 'center' }`              |
| `FlexBoxStyles.rowCenterSpaceBetween` | row + `alignItems: center` + `justifyContent: space-between`  |
| `FlexBoxStyles.rowCenterSpaceAround`  | row + `alignItems: center` + `justifyContent: space-around`   |
| `FlexBoxStyles.rowEnd`                | `{ flexDirection: 'row', alignItems: 'flex-end' }`            |
| `FlexBoxStyles.center`                | `{ alignItems: 'center', justifyContent: 'center' }`          |
| `FlexBoxStyles.flex1`                 | `{ flex: 1 }`                                                 |
| `FlexBoxStyles.flex1Center`           | `{ flex: 1, alignItems: 'center', justifyContent: 'center' }` |
| `FlexBoxStyles.alignCenter`           | `{ alignItems: 'center' }`                                    |
| `FlexBoxStyles.justifyCenter`         | `{ justifyContent: 'center' }`                                |
| `FlexBoxStyles.selfCenter`            | `{ alignSelf: 'center' }`                                     |
| `FlexBoxStyles.wrap`                  | `{ flexWrap: 'wrap' }`                                        |

### Sizing conventions

- **Prefer `padding` over fixed `width`/`height`** for content/text containers.
  A button is `paddingVertical + lineHeight`, not a fixed `height`.
- **Reserve explicit dimensions** for media and known-aspect boxes (banners, card tiles,
  images where the contract supplies dimensions).
- **Media dimensions come from the API contract** (or a named fallback constant declared
  in the mapper). Never call `Image.getSize` or drive layout from `onLoad` callbacks.
- Fallback aspect ratios belong in the mapper as named constants
  (e.g. `const BANNER_IMAGE_RATIO = 0.722`), not in components.
- **N-up grids: chunk into rows of `flex: 1` cards**, not one `flexWrap` row of fixed
  _fractional_ widths. Three `(W − gaps) / 3` widths round up at the pixel level and the third
  card wraps to a new line (two columns happen to be integers, so the bug hides until you go to
  3+). Render each row as a `flexDirection: 'row'` with a `gap`, give each card `flex: 1`, and an
  `aspectRatio` for height (the image fills absolutely). Pad a short final row with `flex: 1`
  spacer views so card widths stay uniform.
- **Don't use `StyleSheet.absoluteFillObject`** — it's absent from this RN version's type defs
  (`tsc` errors). Use an explicit `{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0 }`
  (a shared local const is fine). `StyleSheet.absoluteFill` (the registered number) is still OK
  for a single `containerStyle`/`style` value.

---

## 3. Vertical-slice anatomy

Build in this order. Each layer depends only on the layer above it.

### Step 1 — Zod schema: `src/schemas/<area>.ts`

Validates the wire shape from the middleware. Conventions from `src/schemas/home.ts`:

```ts
// PROVISIONAL — reconcile with real contract   ← place at top in mock mode
import { z } from 'zod';

// Known section types use z.literal('type') + z.discriminatedUnion('type', [...])
const myKindSchema = z.object({
  type: z.literal('my-kind'),
  settings: z.object({
    heading: z.string().nullish(),  // .nullish() for every optional wire field
    count: z.number().nullish(),
  }),
  blocks: z.array(z.object({ ... })),
});

// Unknown types pass through so the app no-ops them instead of throwing
const unknownSectionSchema = z
  .looseObject({ type: z.string() })
  .refine(s => !KNOWN_SECTION_TYPES.includes(s.type), {
    message: 'malformed known section, or unsupported type',
  });

export const areaSectionSchema = z.union([
  z.discriminatedUnion('type', [myKindSchema, ...]),
  unknownSectionSchema,
]);

export const areaPageSchema = z.object({
  pages: z.object({
    success: z.boolean(),
    error: z.object({ code: z.string(), message: z.string() }).nullish(),
    data: z.array(areaSectionSchema).nullish(),
  }),
});

// Export inferred wire types
export type MyKindWire = z.infer<typeof myKindSchema>;
export type AreaSectionWire = z.infer<typeof areaSectionSchema>;
export type AreaPageWire = z.infer<typeof areaPageSchema>;
```

Add the schema to `src/schemas/index.ts` barrel.

### Step 2 — Mapper: `src/utils/map<Area>.ts`

Pure function `(wire, index) => ViewModel | null`. Conventions from `src/utils/mapHomepage.ts`:

```ts
// PROVISIONAL — reconcile with real contract   ← place at top in mock mode

// All per-type mapper functions are pure: (wireSection, index) => ViewModelSection | null
// Type → mapperFn map, declared once. Never a switch.
type SectionMapper = (
  section: AreaSectionWire,
  index: number,
) => AreaSection | null;

const SECTION_MAPPERS: Record<string, SectionMapper> = {
  'my-kind': (s, i) => mapMyKind(s as MyKindWire, i),
};

export function mapArea(wire: AreaPageWire): AreaSection[] {
  const sections = wire?.pages?.data ?? [];
  const result: AreaSection[] = [];

  sections.forEach((section, index) => {
    const mapper = SECTION_MAPPERS[section.type];
    if (!mapper) {
      if (__DEV__)
        console.warn(`mapArea: unhandled section type "${section.type}"`);
      return;
    }
    const mapped = mapper(section, index);
    if (mapped) result.push(mapped);
  });

  return result;
}
```

Rules:

- All `.nullish()` fields get a `?? null` fallback (or a named default constant).
- Normalise dimensions, links, and colors here — not in components.
- Mappers never import from `@/components` or `@/hooks`.

Add the mapper to `src/utils/index.ts` barrel.

### Step 3 — View-model types: `src/types/<area>.ts`

Discriminated-union on `kind`; every field already normalised (no nullish, no raw wire shapes):

```ts
export type MyKindSection = {
  kind: 'my-kind';
  id: string;
  heading: string | null;
  // ...
};

export type AreaSection = MyKindSection | OtherKindSection;
```

Add to `src/types/index.ts` barrel.

> **Extending a _shared_ view-model** (e.g. `HomeProduct`, also constructed by PDP/PLP): make new
> fields **optional** (`compareAtPrice?: Money | null`), not required. Other screens build the same
> type and will fail `tsc` if you add a required field they don't supply. Default the optional
> field in the mapper that owns the redesign so its own components still get a clean value.

### Step 4 — Fetch function + hook: `src/hooks/fetch<Area>.ts` + `use<Area>.ts`

Pattern from `src/hooks/fetchPageSections.ts`:

```ts
// src/hooks/fetchAreaSections.ts
import { areaFixtureMock } from '@/mocks';
import { areaPageSchema } from '@/schemas';
import { getConfig, middlewareFetch } from '@/services';
import type { AreaSection } from '@/types';
import { mapArea } from '@/utils';

export async function fetchAreaSections(slug: string): Promise<AreaSection[]> {
  const data = getConfig('USE_MOCK')
    ? areaPageSchema.parse(areaFixtureMock)
    : await middlewareFetch(AREA_QUERY, areaPageSchema, { slug });

  const { success, error } = data.pages;
  if (!success)
    throw new Error(error?.message ?? 'Area request was unsuccessful');

  return mapArea(data);
}
```

```ts
// src/hooks/useArea.ts
import { useQuery } from '@tanstack/react-query';
import { fetchAreaSections } from './fetchAreaSections';

export function useArea(slug: string) {
  return useQuery({
    queryKey: ['area', slug], // namespaced key
    queryFn: () => fetchAreaSections(slug),
  });
}
```

Add both to `src/hooks/index.ts` barrel.

### Step 5 — Section components: `src/components/<area>/<Kind>Section.tsx`

Section components for a screen are co-located in `src/components/<area>/`. Real examples:
`src/components/home/BannerSection.tsx`, `FeaturedProductsSection.tsx`,
`PromoBannerSection.tsx`, `ShopByCategorySection.tsx`.

```ts
import type { MyKindSection } from '@/types';

interface Props {
  section: MyKindSection;
}

export function MyKindSection({ section }: Props) {
  const styles = useStyles(); // useStyles is defined via useThemeStyles — see the Styling pattern section
  // ...presentation only: no fetch, no navigation logic
}
```

- Every component is **presentation-only**: no fetch calls, no navigation calls.
- CTA links go through `useShopLinkHandler` (see Section 5).
- Use `ProductCard`, `Button`, `FastImage` before writing new primitives.
- Export all section components through the area barrel: `src/components/<area>/index.ts`.

### Step 6 — Registry: `src/components/<area>/<area>SectionRegistry.ts`

The registry is co-located with the section components in `src/components/<area>/`.
Real example: `src/components/home/homeSectionRegistry.ts`.

```ts
import type { SectionRegistry } from '@/components/sections';
import type { AreaSection } from '@/types';
import { MyKindSection } from './MyKindSection'; // direct sibling import — no ./sections/ subfolder

export const areaSectionRegistry: SectionRegistry<AreaSection> = {
  'my-kind': MyKindSection,
  // unknown kinds are no-ops — SectionList warns in __DEV__ and renders null
};
```

`SectionRegistry` is defined in `src/components/sections/SectionList.tsx`.
Dispatch is `registry[section.kind]` — an O(1) map lookup. Never add a `switch`.

> **Alternative (screen-local registry):** when a screen's blocks are entirely screen-specific
> and not shared across features, the registry may live in the screen folder instead, e.g.
> `src/screens/ProductDetail/productBlockRegistry.tsx` (the PDP pattern). Lead with the
> co-located `src/components/<area>/` pattern; use the screen-local variant only when sharing
> the components outside the screen makes no sense.

### Step 7 — Fixture: `src/mocks/<area>.ts`

```ts
// PROVISIONAL — reconcile with real contract   ← place at top in mock mode
export const areaFixtureMock = {
  pages: {
    success: true,
    error: null,
    data: [
      {
        type: 'my-kind',
        settings: { heading: 'Example' },
        blocks: [],
      },
    ],
  },
};
```

- Fixtures are typed TypeScript modules, **not JSON**.
- Export via `@/mocks` (add to `src/mocks/index.ts` barrel).
- The fixture must be parseable by the Zod schema without errors.

---

## 4. Reuse & components

### `ProductCard` — `src/components/common/ProductCard.tsx`

```ts
import { ProductCard } from '@/components/common';

<ProductCard
  product={item}          // HomeProduct view-model
  onPress={handlePress}   // named handler, not anonymous
  variant="home"          // 'home' | 'plp'
  showVendor={false}      // optional
  onWishlistPress={...}   // optional
/>
```

- `home` variant: fixed width tile (260px, set inside the component).
- `plp` variant: `flex: 1`, fills its grid cell.
- Callers pass `variant` only — never raw `width`/`height`.

### `Button` — `src/components/core/button/Button.tsx`

```ts
import { Button } from '@/components/core';

<Button
  label="Shop Now"
  onPress={handleCta} // named handler
  variant="filled" // 'filled' | 'outlined' | 'underline'
  color={colors.textInverse} // foreground color (optional)
  backgroundColor={colors.primary} // fill color, filled variant only (optional)
  fullWidth // optional; defaults true for filled/outlined
/>;
```

- `filled`: solid fill + inverse label. Height is padding-driven — no fixed `height`.
- `outlined`: transparent + 50%-alpha border, used over media (banner CTAs).
- `underline`: text label + 1px rule, hugs content width (promo buttons).
- Pass colors from the view-model (API-driven palette) — not hardcoded.
- **Reuse has limits.** `Button` bakes in `textTransform: 'capitalize'` and a fixed label size, so
  it can't render small, _uppercase_ CTAs (e.g. banner "SHOP MEN" / "SHOP WOMEN", 12px). When the
  shared primitive's baked-in styling conflicts with the design, render a small inline element
  instead of fighting it — and leave a comment saying why.

### `FastImage` — `src/components/core/image/FastImage.tsx`

```ts
import { FastImage } from '@/components/core';

<FastImage
  source={{ uri: product.image.url }} // pass raw URL — FastImage handles CDN optimization
  containerStyle={[styles.image, { aspectRatio }]}
  resizeWidth={700} // optional: DPR-scaled for full-bleed surfaces
/>;
```

- `FastImage` wraps Shopify CDN optimization (`optimizeShopifyImageUrl`) internally.
  **Pass raw URLs through from the view-model** — do not call `optimizeShopifyImageUrl`
  in mappers or components.
- Handles: skeleton placeholder (loading state), error placeholder, CDN resize.
- Dimensions come from the view-model (set in the mapper from contract data or a
  named fallback constant). Never drive aspect ratio from `onLoad`.

### Variant-driven component rule

Every shared component owns its per-`variant` sizing and behaviour. Callers pass a
`variant` prop, never raw dimensions or styles. When building a new shared component,
establish variants first and keep all size/color decisions inside the component.

### No anonymous functions in JSX props

```ts
// ✗ Wrong (except per-iteration callbacks)
<Button onPress={() => navigate('Home')} />;

// ✓ Correct
const handleNavHome = useCallback(() => navigate('Home'), [navigate]);
<Button onPress={handleNavHome} />;

// ✓ Allowed exception: per-iteration callbacks closing over loop variable
products.map(p => <ProductCard key={p.id} onPress={() => onSelect(p.id)} />);
```

---

## 5. CTA links

All link targets from the middleware go through a two-layer handler:

```
useShopLinkHandler → parseShopifyLink → useLinkIntentHandler → navigation / Linking
```

### `useShopLinkHandler` — `src/hooks/useShopLinkHandler.ts`

Takes a raw middleware URL string (e.g. `shopify://collections/men`), parses it into a
`CmsLinkIntent`, then delegates to `useLinkIntentHandler`.

```ts
import { useShopLinkHandler } from '@/hooks';

export function MySection({ section }: Props) {
  const handleLink = useShopLinkHandler();

  const handleCta = useCallback(
    () => handleLink(section.cta.url),
    [handleLink, section.cta.url],
  );

  return <Button label={section.cta.label} onPress={handleCta} />;
}
```

### `useLinkIntentHandler` — `src/hooks/useLinkIntentHandler.ts`

Accepts an already-resolved `CmsLinkIntent` and navigates:

| `intent.kind`  | Action                                                                                |
| -------------- | ------------------------------------------------------------------------------------- |
| `'collection'` | `navigation.navigate('ProductListing', { handle })`                                   |
| `'product'`    | `navigation.navigate('ProductDetail', { handle })`                                    |
| `'page'`       | `navigation.navigate('Page', { handle })` (or `CategoryHome` reset for `men`/`women`) |
| `'external'`   | `Linking.openURL` — only `https?://` URLs; non-web schemes are blocked silently       |

Use `useShopLinkHandler` from section components (it handles URL parsing).
Use `useLinkIntentHandler` directly only when the caller already holds a parsed `CmsLinkIntent`
(e.g. drawer menu from a view-model).

> Note: the map-over-switch invariant applies to the section mappers and registries **you
> author**. The pre-existing `useLinkIntentHandler` hook uses an internal `switch` — that is
> fine and out of scope. Consume `useLinkIntentHandler` as-is; do not rewrite it.

---

## 6. Tests

Tests live in `__tests__/` mirroring `src/`. Every hook in `src/hooks/` and every util in
`src/utils/` must have a unit test.

> **Rebuild caveat (Track 2).** The mapper-as-firewall protects against _contract_ changes, not
> deliberate view-model redesigns. If a rebuild changes a view-model shape (e.g. `cta` → `ctas[]`,
> or adds a required field), the existing mapper / hook / screen tests **and** any typed section
> mocks inside screen tests must be updated to the new shape — they won't be "durable" across that
> change. Run `yarn typecheck` early; it surfaces every stale construction site at once.

### Mapper test: `__tests__/utils/map<Area>.test.ts`

```ts
import { mapArea } from '@/utils';
import { areaFixtureMock } from '@/mocks';
import { areaPageSchema } from '@/schemas';

describe('mapArea', () => {
  it('maps a known section kind to the correct view-model', () => {
    const wire = areaPageSchema.parse(areaFixtureMock);
    const sections = mapArea(wire);
    expect(sections[0]).toMatchObject({ kind: 'my-kind', heading: 'Example' });
  });

  it('drops unknown section types without throwing', () => {
    const wire = areaPageSchema.parse({
      pages: { success: true, error: null, data: [{ type: 'future-type' }] },
    });
    expect(mapArea(wire)).toEqual([]);
  });
});
```

### Hook test: `__tests__/hooks/use<Area>.test.ts`

Use React Query's `renderHook` + `QueryClientProvider` wrapper.
The `USE_MOCK` path is the simplest to test: mock `getConfig` to return truthy.
Mock at the boundary (`middlewareFetch`) for the live path.

```ts
jest.mock('@/services', () => ({
  ...jest.requireActual('@/services'),
  getConfig: jest.fn().mockReturnValue(true), // USE_MOCK = true
  middlewareFetch: jest.fn(),
}));
```

### Screen test: `__tests__/screens/<Screen>/index.test.tsx`

Mock the hook barrel path (`@/hooks`), not the implementation:

```ts
const mockUseArea = jest.fn();
jest.mock('@/hooks', () => ({
  ...jest.requireActual('@/hooks'),
  useArea: mockUseArea,
}));
```

Cover at minimum: loading branch, error branch, empty data branch.
Add interaction tests for stateful UI (e.g. variant picker).

### `jest.mock` variable-name rule

Factory functions inside `jest.mock(...)` are hoisted above imports. Any variable
referenced inside a factory must be prefixed with `mock` (e.g. `mockNavigate`,
`mockUseArea`) or defined inside the factory itself.

---

## 7. Invariants (binding across all tracks)

- `@/...` path alias for all `src/` imports. Never use relative `../` across folders.
- Every `src/` folder exports through its `index.ts` barrel.
- No `any`. TypeScript strict mode is on.
- Colors: hex only (`#RRGGBB` or `#RRGGBBAA`). No `rgba()`, no named colors, no raw hex in components.
- `map` over `switch` for kind/type dispatch in the mappers and registries you author.
  Pre-existing hooks (e.g. `useLinkIntentHandler`) that use an internal `switch` are out of
  scope — consume them, do not rewrite them.
- Components are presentation-only: no fetch, no navigation outside of CTA handlers.
- The `PROVISIONAL` banner (`// PROVISIONAL — reconcile with real contract`) goes at the
  **top** of the schema file, the mapper file, and the fixture file — all three, in mock mode only.
- `yarn typecheck` + `yarn lint` + `yarn test` must all be green before the work is considered done.
