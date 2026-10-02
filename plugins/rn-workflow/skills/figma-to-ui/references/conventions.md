# figma-to-ui: Build Conventions Reference

This file is the build-time reference for the `/figma-to-ui` skill. It contains
token tables, file anatomy, code patterns, and constraints. The skill's process
narrative lives in `SKILL.md`; this file is the lookup reference during the build phase.

**`docs/tech-dna.md` in the project is the source of truth.** Everything here follows it; if the
two ever disagree, tech-dna wins and this file should be fixed.

---

## 1. Theme-token mapping

The tables below are an **example scale** — `src/theme` in the project is the truth. Read it
for the current token set before mapping. If you add a token (with the user's OK on a flagged
gap), add it to the project's theme, not here.

### Spacing

Import: `import { spacing } from '@/theme';`

| Token             | px  |
| ----------------- | --- |
| `spacing.xs`      | 4   |
| `spacing.sm`      | 8   |
| `spacing.md`      | 12  |
| `spacing.lg`      | 16  |
| `spacing.xl`      | 20  |
| `spacing.xxl`     | 24  |
| `spacing.xxxl`    | 32  |
| `spacing.huge`    | 40  |
| `spacing.massive` | 48  |

Use the token whose value **exactly** matches the Figma value. If none matches, raise a
token-gap question (add a token, or use the exact value with a node-id comment) — never
silently use the nearest token (tech-dna §9).

### Typography

Import: `import { typography } from '@/theme';`

Spread the token into a style: `{ ...typography.body, color: colors.text }`. Weight comes from
the token's font family — never set `fontWeight` (tech-dna §8b).

| Token                  | Size | Line height | Use case                 |
| ---------------------- | ---- | ----------- | ------------------------ |
| `typography.h1`        | 32   | 40          | Page heading             |
| `typography.h2`        | 24   | 32          | Section heading          |
| `typography.h3`        | 20   | 28          | Sub heading              |
| `typography.h4`        | 18   | 24          | Card heading             |
| `typography.body`      | 16   | 24          | Body copy                |
| `typography.bodySmall` | 14   | 20          | Secondary copy           |
| `typography.caption`   | 12   | 16          | Captions, meta           |
| `typography.label`     | 14   | 20          | Form labels, chips       |
| `typography.button`    | 16   | 24          | Button / CTA label       |

Brand tokens (your project's brand families and sizes) are added alongside these.

### Colors

Import via `useThemeStyles` — access as `colors.<key>` inside the style factory.

| Token                         | Hex         | Use case                               |
| ----------------------------- | ----------- | -------------------------------------- |
| `colors.primary`              | `#111111`   | Primary fill / buttons                 |
| `colors.text`                 | `#111111`   | Body text                              |
| `colors.textSecondary`        | `#666666`   | Captions, secondary labels             |
| `colors.textDisabled`         | `#AAAAAA`   | Disabled state                         |
| `colors.textInverse`          | `#FFFFFF`   | Text on dark backgrounds               |
| `colors.background`           | `#FFFFFF`   | Screen / card background               |
| `colors.backgroundSecondary`  | `#F5F5F5`   | Off-white container, image placeholder |
| `colors.border`               | `#E0E0E0`   | Borders                                |
| `colors.divider`              | `#E9EBED`   | Divider lines                          |
| `colors.success`              | `#2E7D32`   | Success state                          |
| `colors.error`                | `#C62828`   | Error state                            |
| `colors.<brandAccent>`        | `#RRGGBB`   | Your brand accent(s) — define per project |
| `colors.overlay`              | `#00000080` | Modal/sheet backdrop                   |
| `colors.transparent`          | `#00000000` | Transparent fills                      |
| `colors.skeletonShimmerStart` | `#EEEEEE`   | Skeleton shimmer start                 |
| `colors.skeletonShimmerEnd`   | `#D2D2D2`   | Skeleton shimmer end                   |

**Color rules (binding):**

- Components use theme tokens only — never a hex, `rgba()` or named colour in JSX/styles.
- If a Figma color matches no token, flag it as a **token gap** and ask the user before
  proceeding. Do not invent a token or hardcode it in the component.
- Alpha variants use `withAlpha(colors.<token>, 'AA')` from `@/utils`, so everything stays hex.

---

## 2. Styling pattern

### `useThemeStyles`

Themed styles use `useThemeStyles` (memoised style factory). Truly static, never-themed styles
use a module-level `StyleSheet.create`. Never inline `style={{}}` literals.

```ts
// src/components/<area>/MyComponent.tsx
import { useThemeStyles } from '@/hooks';
import { spacing, typography } from '@/theme';

const useStyles = () =>
  useThemeStyles(({ colors }) => ({
    container: {
      padding: spacing.lg,
      backgroundColor: colors.background,
    },
    title: {
      ...typography.h2,
      color: colors.text,
    },
  }));
```

Call `useStyles()` at the top of the component. When you need colours outside a style factory
(e.g. for a prop value), use `useThemeValues`:

```ts
import { useThemeValues } from '@/hooks';
const { colors } = useThemeValues();
```

### Sizing conventions

- **Prefer `padding` over fixed `width`/`height`** for content/text containers — a button is
  `paddingVertical + lineHeight`, not a fixed `height` (it must grow with large system text,
  tech-dna §8c).
- **Media is sized dynamically** (tech-dna §11a): the slot width comes from
  `useWindowDimensions()` minus layout spacing; the height comes from `aspectRatio`, which the
  mapper sets from the contract's width/height (or a named fallback constant). Never a fixed
  `height`, never `Image.getSize` / `onLoad`.
- **N-up grids:** compute the cell width from the screen width and the gap constants, and give
  each card that width + its `aspectRatio`. The same width is the image's `renderWidthDp`.

---

## 3. Vertical-slice anatomy

Build in this order. Each layer depends only on the layer above it.

### Step 1 — Zod schema: `src/schemas/<area>.ts`

Validates the **payload** the boundary fetcher returns (any response envelope is already
unwrapped by the boundary — tech-dna §3, §20). Declare only the fields the app reads.

```ts
// PROVISIONAL — reconcile with real contract   ← place at top in mock mode
import { z } from 'zod';

// Known section types: z.literal('type'), validated strictly
const myKindSchema = z.object({
  type: z.literal('my-kind'),
  settings: z.object({
    heading: z.string().nullish(), // .nullish() for every optional wire field
    count: z.number().nullish(),
  }),
  blocks: z.array(z.object({ /* … */ })),
});

// Unknown types pass through so the mapper drops them instead of failing the whole page
const unknownSectionSchema = z
  .looseObject({ type: z.string() })
  .refine(s => !KNOWN_SECTION_TYPES.includes(s.type), {
    message: 'malformed known section, or unsupported type',
  });

export const areaSectionSchema = z.union([
  z.discriminatedUnion('type', [myKindSchema /* , … */]),
  unknownSectionSchema,
]);

export const areaPageSchema = z.object({
  sections: z.array(areaSectionSchema),
});

export type MyKindWire = z.infer<typeof myKindSchema>;
export type AreaSectionWire = z.infer<typeof areaSectionSchema>;
export type AreaPageWire = z.infer<typeof areaPageSchema>;
```

Add the schema to the `src/schemas/index.ts` barrel.

### Step 2 — Mapper: `src/mappers/map<Area>.ts`

Pure functions. A `type → mapperFn` map, declared once — never a `switch`.

```ts
// PROVISIONAL — reconcile with real contract   ← place at top in mock mode
import type { AreaPageWire, AreaSectionWire, MyKindWire } from '@/schemas';
import type { AreaSection } from '@/types';

type SectionMapper = (section: AreaSectionWire, index: number) => AreaSection | null;

const SECTION_MAPPERS: Record<string, SectionMapper> = {
  'my-kind': (s, i) => mapMyKind(s as MyKindWire, i),
};

export function mapArea(wire: AreaPageWire): AreaSection[] {
  const result: AreaSection[] = [];
  wire.sections.forEach((section, index) => {
    const mapper = SECTION_MAPPERS[section.type];
    if (!mapper) {
      if (__DEV__) console.warn(`mapArea: unhandled section type "${section.type}"`);
      return;
    }
    const mapped = mapper(section, index);
    if (mapped) result.push(mapped);
  });
  return result;
}
```

Rules:

- Every `.nullish()` field gets a `?? null` fallback (or a named default constant).
- Normalise dimensions (set `aspectRatio`), links and colours here — not in components.
- Ids come from content, never from list position.
- Mappers never import from `@/components` or `@/hooks`.

Add the mapper to the `src/mappers/index.ts` barrel.

### Step 3 — View-model types: `src/types/<area>.ts`

A discriminated union on `kind`; every field already normalised:

```ts
export type MyKindSection = {
  kind: 'my-kind';
  id: string;
  heading: string | null;
  // …
};

export type AreaSection = MyKindSection | OtherKindSection;
```

Add to the `src/types/index.ts` barrel.

> **Extending a view-model that other screens also build:** make new fields **optional**
> (`compareAtPrice?: Money | null`), not required — the other screens would fail `tsc`. Default
> the optional field in the mapper that owns the redesign.

### Step 4 — Fetch function + hook: `src/hooks/fetch<Area>.ts` + `use<Area>.ts`

```ts
// src/hooks/fetchAreaSections.ts
import { AREA_QUERY } from '@/graphql';
import { mapArea } from '@/mappers';
import { areaPageSchema } from '@/schemas';
import { boundaryFetch, getConfig } from '@/services';
import type { AreaSection } from '@/types';

export async function fetchAreaSections(slug: string): Promise<AreaSection[]> {
  const data = getConfig('USE_MOCK')
    ? areaPageSchema.parse(require('@/mocks/area').areaFixtureMock) // lazy — not in release builds
    : await boundaryFetch(AREA_QUERY, areaPageSchema, { slug });
  return mapArea(data);
}
```

```ts
// src/hooks/useArea.ts
import { useQuery } from '@tanstack/react-query';
import { fetchAreaSections } from './fetchAreaSections';

export const useArea = (slug: string) =>
  useQuery({
    queryKey: ['area', slug], // namespaced key
    queryFn: () => fetchAreaSections(slug),
  });
```

Add both to the `src/hooks/index.ts` barrel. (For a prefetch, share one query-options factory —
tech-dna §4.)

### Step 5 — Section components: `src/components/<area>/<Kind>Section.tsx`

Section components for a screen live in `src/components/<area>/` (tech-dna §1b).

```tsx
import type { MyKindSection as MyKindSectionData } from '@/types';

export type MyKindSectionProps = {
  section: MyKindSectionData;
};

export const MyKindSection = ({ section }: MyKindSectionProps) => {
  const styles = useStyles(); // defined via useThemeStyles — see §2
  // …presentation only: no fetch, no navigation logic
};
```

- Every component is **presentation-only**: no fetch calls, no navigation calls outside CTA handlers.
- CTA links go through the app's link handler (§5).
- Check `src/components/core/` and `src/components/common/` first and reuse what exists — never a
  React Native primitive where the project has a component (tech-dna §1b).
- Export all section components through the area barrel: `src/components/<area>/index.ts`.

### Step 6 — Registry: `src/components/<area>/<area>SectionRegistry.ts`

```ts
import type { SectionRegistry } from '@/components/sections';
import type { AreaSection } from '@/types';
import { MyKindSection } from './MyKindSection';

export const areaSectionRegistry: SectionRegistry<AreaSection> = {
  'my-kind': MyKindSection,
  // unknown kinds are no-ops — SectionList warns in __DEV__ and renders null
};
```

Dispatch is `registry[section.kind]` — an O(1) map lookup. Never add a `switch`. The registry
always lives in `src/components/<area>/` next to its section components — the screen folder holds
only the screen and its barrel (tech-dna §1b).

### Step 7 — Fixture: `src/mocks/<area>.ts`

```ts
// PROVISIONAL — reconcile with real contract   ← place at top in mock mode
export const areaFixtureMock = {
  sections: [
    {
      type: 'my-kind',
      settings: { heading: 'Example' },
      blocks: [],
    },
  ],
};
```

- Fixtures are typed TypeScript modules, **not JSON**, shaped like the payload the schema parses.
- The fixture must parse with the Zod schema without errors.
- Fetchers load it lazily inside the `USE_MOCK` branch (tech-dna §1a).

---

## 4. Reuse & components

Before building anything, check `src/components/core/` and `src/components/common/` (tech-dna §1b).
If an existing component is close, **add a `variant` to it** — never a near-copy, and never an
inline lookalike.

### A shared card — `src/components/common/<Name>Card.tsx` (example)

```tsx
<ProductCard
  product={item}          // view-model
  onPress={handlePress}   // named handler, not anonymous
  variant="rail"          // 'rail' | 'grid' — the component owns each variant's sizing
/>
```

- Callers pass a `variant` — never raw `width`/`height` or styles.

### `Button` — `src/components/core/button/Button.tsx`

```tsx
<Button
  label={COPY.shopNow}    // copy from src/constants
  onPress={handleCta}     // named handler
  variant="filled"        // e.g. 'filled' | 'outlined' | 'text'
/>
```

- Height is padding-driven — no fixed `height`.
- If the design needs a style the button doesn't have (e.g. a small uppercase CTA), add a
  `variant` to `Button` — don't render an inline element instead.
- Submit / pay / add buttons go through the shared double-tap guard (tech-dna §8).

### The shared image component — `src/components/core/image/<Image>.tsx`

```tsx
const source = useMemo(() => ({ uri: item.imageUrl }), [item.imageUrl]);
const imageStyle = useMemo(() => ({ width: tileWidth, aspectRatio: item.aspectRatio }), [tileWidth, item.aspectRatio]);

<Image source={source} renderWidthDp={tileWidth} style={imageStyle} />
```

- `renderWidthDp` (the slot width in dp) is **required** — the component converts it to pixels
  and requests a right-sized image (tech-dna §11a).
- **Pass raw URLs from the view-model** — any CDN size transform happens inside the image component,
  never in mappers or screens.
- Height comes from `aspectRatio` set in the mapper. Never drive size from `onLoad`.

### Variant-driven component rule

Every shared component owns its per-`variant` sizing and behaviour. Callers pass a `variant`
prop, never raw dimensions or styles. When building a new shared component, establish variants
first and keep all size/colour decisions inside the component.

### No anonymous functions in JSX props

```tsx
// ✗ Wrong (except per-iteration callbacks)
<Button onPress={() => navigate('Home')} />;

// ✓ Correct
const handleNavHome = useCallback(() => navigate('Home'), [navigate]);
<Button onPress={handleNavHome} />;

// ✓ Allowed exception: a per-iteration callback closing over the loop variable
items.map(p => <ProductCard key={p.id} onPress={() => onSelect(p.id)} />);
```

---

## 5. CTA links

Every link target — CTA buttons, banners, rich-text links — goes through the app's **one link
parser and intent navigator** (tech-dna §10a), usually via a hook such as `useLinkHandler()`:

```tsx
export const MySection = ({ section }: MySectionProps) => {
  const handleLink = useLinkHandler();
  const handleCta = useCallback(() => handleLink(section.cta.url), [handleLink, section.cta.url]);
  return <Button label={section.cta.label} onPress={handleCta} />;
};
```

The parser turns a URL into an intent, and the navigator acts on it — for example:

| Intent        | Action                                                                     |
| ------------- | -------------------------------------------------------------------------- |
| in-app route  | `navigation.navigate(<Route>, { id })` — params are ids, not objects       |
| `external`    | `openExternal(url)` — only `http(s)`, `mailto:`, `tel:` are allowed         |
| `unmapped`    | your own domain with no route → a fallback screen + toast, never `openURL`  |

Never call `Linking.openURL` from a component. Use the existing hook; if the project doesn't have
one yet, ask before creating it.

---

## 6. Tests

Tests live in `__tests__/` mirroring `src/`. Every hook in `src/hooks/` and every util in
`src/utils/` must have a unit test; mappers get their own tests.

> **Rebuild caveat (Track 2).** The mapper-as-firewall protects against _contract_ changes, not
> deliberate view-model redesigns. If a rebuild changes a view-model shape (e.g. `cta` → `ctas[]`,
> or adds a required field), the existing mapper / hook / screen tests **and** any typed section
> mocks inside screen tests must be updated to the new shape. Run `yarn typecheck` early; it
> surfaces every stale construction site at once.

### Mapper test: `__tests__/mappers/map<Area>.test.ts`

```ts
import { mapArea } from '@/mappers';
import { areaFixtureMock } from '@/mocks/area';
import { areaPageSchema } from '@/schemas';

describe('mapArea', () => {
  it('maps a known section kind to the correct view-model', () => {
    const sections = mapArea(areaPageSchema.parse(areaFixtureMock));
    expect(sections[0]).toMatchObject({ kind: 'my-kind', heading: 'Example' });
  });

  it('drops unknown section types without throwing', () => {
    const wire = areaPageSchema.parse({ sections: [{ type: 'future-type' }] });
    expect(mapArea(wire)).toEqual([]);
  });
});
```

### Hook test: `__tests__/hooks/use<Area>.test.ts`

Use React Query's `renderHook` + a `QueryClientProvider` wrapper. The `USE_MOCK` path is the
simplest to test: mock `getConfig` to return truthy. Mock at the boundary (the boundary fetcher)
for the live path.

```ts
jest.mock('@/services', () => ({
  ...jest.requireActual('@/services'),
  getConfig: jest.fn().mockReturnValue(true), // USE_MOCK = true
  boundaryFetch: jest.fn(),
}));
```

### Screen test: `__tests__/screens/<Name>/<Name>Screen.test.tsx`

Mock the hook barrel path (`@/hooks`), not the implementation:

```ts
const mockUseArea = jest.fn();
jest.mock('@/hooks', () => ({
  ...jest.requireActual('@/hooks'),
  useArea: mockUseArea,
}));
```

Cover at minimum: loading branch, error branch, empty data branch. Add interaction tests for
stateful UI. One behaviour per test.

### `jest.mock` variable-name rule

Factory functions inside `jest.mock(...)` are hoisted above imports. Any variable referenced
inside a factory must be prefixed with `mock` (e.g. `mockNavigate`, `mockUseArea`) or defined
inside the factory itself.

---

## 7. Invariants (binding across all tracks)

- Follow `docs/tech-dna.md` — this list is a reminder, not a replacement.
- `@/...` path alias for all `src/` imports; every `src/` folder exports through its `index.ts` barrel.
- TypeScript strict: no `any`; `type` not `interface`; no `enum`; components and hooks are arrow functions.
- Colours: theme tokens only — hex (`#RRGGBB` / `#RRGGBBAA`), no `rgba()`, no named colours, no raw hex in components.
- Figma values come from the node specs; exact token match or a flagged token gap — never the nearest token.
- `map` over `switch` for kind/type dispatch.
- Components are presentation-only: no fetch, no navigation outside CTA handlers.
- Reuse `components/core/` and `components/common/` before any React Native primitive (shared `Pressable`, `BaseText`, image component).
- Media: width from the screen, height from `aspectRatio`; images take `renderWidthDp`.
- Bottom-pinned UI respects the safe-area inset (edge-to-edge, 3-button navigation); tappables have accessibility labels where the text isn't enough.
- The `PROVISIONAL` banner (`// PROVISIONAL — reconcile with real contract`) goes at the
  **top** of the schema file, the mapper file, and the fixture file — all three, in mock mode only.
- `yarn lint --max-warnings=0` + `yarn typecheck` + `yarn test` must all be green before the work is considered done.
