# Plan — <Feature name>

> Task-by-task build plan produced at **Gate A** of `/feature`. Pairs with the spec at
> `docs/superpowers/specs/YYYY-MM-DD-<feature-kebab>-design.md` (link below). Keep the
> checkboxes and the spec `Status` reconciled to what actually shipped.

**Date:** YYYY-MM-DD
**Spec:** [`../specs/YYYY-MM-DD-<feature-kebab>-design.md`](../specs/YYYY-MM-DD-<feature-kebab>-design.md)
**Goal:** <one line — the user-facing outcome>
**Architecture one-liner:** <how it fits: which screen/data path/store/pattern>
**Tech stack touched:** <libs / modules involved>

## Global Constraints (the tech-DNA rules that bite this feature)

- <e.g. every fetch passes a Zod schema; mapper is the firewall — no transforms in components>
- <e.g. colours from theme tokens only; add a token if none fits>
- <e.g. new persisted store → skipHydration:true + App.tsx rehydrate>
- <list only the rules that actually apply here>

## Tasks

### Task 1 — <name>

- [ ] <step>
- [ ] <step>

**Files:** create `src/...`, modify `src/...`, test `__tests__/...`
**Interfaces:** consumes `<x>`; exposes `<y>`

### Task 2 — <name>

- [ ] <step>

**Files:** …
**Interfaces:** …

<!-- add tasks as needed; each is a committable slice -->
