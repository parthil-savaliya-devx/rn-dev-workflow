# `<FILL IN — App name>`

`<FILL IN — one-line description>`. React Native CLI app. `<FILL IN — RN/React versions, and the backend boundary, e.g. "All data is served by a custom middleware (App → Middleware → downstream)".>`

> **Scaffolded from the `rn-workflow` plugin (uniform baseline).** The Hard Rules below are the generic, non-negotiable index every project shares; the detail lives in [`docs/tech-dna.md`](docs/tech-dna.md). Fill the `<FILL IN>` slots (app name, backend boundary, env keys, subsystem map, dependencies) for this project. Add project-specific rules as you go — record any deviation from a baseline choice as an ADR.

## Hard Rules

> The canonical, copy-me patterns for all generated code live in **[`docs/tech-dna.md`](docs/tech-dna.md)** — the project's coding genome. **Read it before writing any code.** Every feature and bugfix is written by copying those patterns, never by inventing a new style; a pattern with no precedent there is added to it in the same PR (tech-dna §17). The rules below are the non-negotiable index.

- **One data boundary.** Every read/write goes through the single boundary fetcher (`<FILL IN — your client>`) → Zod → mapper → view-model. Never call a third party directly.
- **Every fetch passes a Zod schema** (`z.unknown()` is the only, review-visible opt-out). The **mapper is the firewall** — wire→view-model transforms live there, declared as a `type→fn` map, **never a `switch`**.
- **Config-driven, never name-driven** rendering. Branch layout on config flags via the shared `SectionList` + per-screen `SectionRegistry` (O(1) map dispatch); `kind === wire type`.
- **Ask, don't assume.** Anything unclear — requirement, design intent, API behaviour, edge case — STOP and ask the human (batched), and build exactly to the clarification. Never guess and build.
- **Figma from node specs, never screenshots** — `get_metadata` → `get_design_context`, exact values, cite the node id in a comment (use the `figma-to-ui` skill).
- **Styling:** theme tokens first; **hex only** (`#RRGGBB`/`#RRGGBBAA`, `withAlpha`); `spacing.*` + `typography.*` tokens (no scaling helpers); **weight-by-family, never `fontWeight`**; prefer `BaseText`; no inline `style={{}}`; no anonymous fns in JSX props (except per-iteration list closures). A colour literal in a screen/component is a defect — add a token (tech-dna §8).
- **Hardcoded data has one home** (tech-dna §1a): static, no-API data → `src/constants/`; wire-shape fixtures for the `USE_MOCK` path → `src/mocks/` (schema-validated). Never inline either in a component.
- **TypeScript strict — no `any`.** `@/` alias imports; barrel per folder; defensive access on API fields.
- **State:** a new persisted store MUST set `skipHydration:true` AND be rehydrated in `App.tsx`'s `Promise.all`. Config via `ENV`/`getConfig`, never `Config.` directly.
- **Every hook and util gets a unit test**; screens get loading/error/empty branch tests; **mock at the boundary** (the fetcher/native), never internal modules.
- **Never swallow errors** (no empty `catch`, no failure-hiding fallback).
- **Docs ship in the PR** — ADR / architecture / runbook / glossary as the change requires (tech-dna §15).
- **`yarn check:env`** after any `.env.*` change.
- `<FILL IN — project-specific hard rules, e.g. no parseFloat on money, checkout URLs only from API, light/portrait lock>`

## Architecture — the data boundary

`<FILL IN>` — describe the single backend the app talks to and the rule that it never calls third parties directly. Keep the pipeline: **query/endpoint → boundary fetcher → Zod schema → mapper (firewall) → view-model → presentation-only component**. Config-driven rendering, never name-driven. See [`docs/tech-dna.md`](docs/tech-dna.md) §0, §3, §6.

## Commands

Use **Yarn Classic** for everything (adjust if this project uses npm/pnpm).

```bash
yarn install              # install deps
yarn start                # start Metro
yarn ios:dev              # run iOS (dev scheme)
yarn android:dev          # run Android (dev variant)
yarn lint                 # eslint
yarn typecheck            # tsc --noEmit
yarn test                 # jest
yarn check:env            # assert .env.* key parity with .env.example
cd ios && pod install     # after adding native modules
```

`<FILL IN — your full scheme/flavour aliases (ios:stage, android:prod, release variants) and any codegen/e2e scripts>`

## Folder Structure

```
src/
  components/   common/ core/ sections/ + per-area folders
  screens/      one folder per screen (UI + wiring only)
  navigation/   RootNavigator + typed ParamLists
  hooks/        query + behaviour hooks (every hook has a test)
  services/     boundary fetcher, queryClient, errors
  store/        Zustand stores + MMKV adapter
  schemas/      Zod wire-shape schemas
  mappers/      wire→view-model mappers (the firewall)
  utils/        pure functions (every util has a test)
  constants/    env config + static data
  theme/        design tokens
  types/        shared view-model + domain types
  assets/       images, fonts, svgs
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
- **Barrels** — every `src/` folder exports through its `index.ts`.
- **Screens = UI only** — business logic in hooks/services.
- **Colors: hex only**, theme tokens preferred; `withAlpha` for alpha.
- **Fonts: weight via family**, never `fontWeight`.
- **Prefer `BaseText`** over raw `<Text>` for themed copy.
- **Map over `switch`** for type/`kind` dispatch.
- **Defensive field access** on API-sourced fields; normalize in the mapper.
- Full detail + rationale: [`docs/tech-dna.md`](docs/tech-dna.md).

## Testing

- Jest + `@testing-library/react-native`. Tests in `__tests__/` mirroring `src/`.
- **Every hook and util has a unit test.** Screens: loading/error/empty branch tests minimum.
- **Mock at the boundary** (the fetcher / native modules) — never internal modules.
- See [`docs/tech-dna.md`](docs/tech-dna.md) §14.

## Documentation

Docs ship in the PR (tech-dna §15): new decision → an ADR (`docs/decisions/`); new subsystem → `docs/architecture/`; new env key → the environments doc + `.env.example`; new term → `docs/glossary.md`; new pattern → `docs/tech-dna.md`.

## Knowledge Graph — graphify (optional)

If this repo ships a `graphify` knowledge graph at `graphify-out/`, prefer `graphify query "<question>"` over grepping raw source for codebase questions. Build it once with `graphify update .` on a fresh clone.

## PR trailer

`<FILL IN — the required commit/PR trailer for this repo, if any.>`
