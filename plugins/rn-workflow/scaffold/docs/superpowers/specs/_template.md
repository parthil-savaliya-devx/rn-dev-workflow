# Spec — <Feature name>

> The **rebuild document**: this feature must be re-implementable from this file alone, even
> after the Figma link rots. Produced at **Gate A** of `/feature`, alongside the plan. Update
> `Status` and any deviations as you build — never leave it stale.

**Date:** YYYY-MM-DD
**Status:** Draft | Approved | Building | Shipped
**Figma:** <file link> — node id **per state** (idle / loading / error / empty / …)
**Scope:** <what's in; what's explicitly out>

## Decisions (settled)

Every clarification the user answered at Gate A. This is the record of "why it is the way it is".

| # | Question | Decision |
| - | -------- | -------- |
| 1 | <what was ambiguous> | <what the user chose> |

## Acceptance criteria (EARS)

- WHEN <event/condition> THE SYSTEM SHALL <observable behaviour>.
- WHEN <…> THE SYSTEM SHALL <…>.

## Extracted design values

Exact values pulled from the Figma node specs (survives link rot). Never reverse-engineered from a screenshot.

| Element | Font (size/line-height/weight) | Colour → token | Spacing / size | Node id |
| ------- | ------------------------------ | -------------- | -------------- | ------- |
| <title> | <e.g. 12 / 18 / medium> | <#RRGGBB → colors.token> | <padding/gap px> | <node> |

## Architecture

Each file to create/modify and its single responsibility:

| File | Responsibility |
| ---- | -------------- |
| `src/schemas/<area>.ts` | wire-shape Zod schema |
| `src/mappers/map<Area>.ts` | firewall: wire → view-model |
| `src/hooks/use<Area>.ts` | query hook |
| `src/screens/<Screen>/…` | UI + wiring |
| `__tests__/…` | mapper / hook / screen tests |

## Behaviour spec

- **Interactions:** <taps, gestures, what each does>
- **Validation:** <rules + messages, if a form>
- **Navigation:** <where each route/CTA goes>
- **Edge cases:** <zero/one/many, missing optional data, offline, over-limit input, double-tap>

## testID inventory

| Element | testID |
| ------- | ------ |
| <screen root> | `<screen>-root` |
| <primary action> | `<screen>-<action>` |

## Test list

- [ ] mapper: known kind → view-model; unknown kind dropped
- [ ] hook: USE_MOCK path returns mapped data
- [ ] screen: loading / error / empty branches
- [ ] interaction: <per stateful element>
