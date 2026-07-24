# AI-Assisted Development Workflow

## What this covers

How day-to-day development is done in this repo with an AI coding agent (Claude Code) in a **consistent, reviewable** way: the canonical-patterns "genome", the two workflow commands (`/feature`, `/fix`), the enforcement hooks, and the `figma-to-ui` / `graphify` skills. The goal is that a feature written today and one written in three months read as if the same engineer wrote both — because both were written by copying the same documented patterns rather than improvising.

The machinery (commands, hooks, skills) is installed from the **`rn-workflow` plugin** (private `rn-dev-workflow` marketplace); the editable content (this file, `tech-dna.md`, `CLAUDE.md`, the doc templates) was scaffolded into this repo by `/init-dna` and is owned here. This is the process/tooling map. The patterns themselves live in [`../tech-dna.md`](../tech-dna.md); the non-negotiable rules index lives in [`../../CLAUDE.md`](../../CLAUDE.md) → **Hard Rules**.

## The pieces

| Piece | Source | Role |
| ----- | ------ | ---- |
| **Tech DNA** | `docs/tech-dna.md` (owned here) | The coding genome — canonical, copy-me patterns + a Forbidden list. Read before writing any code. |
| **Hard Rules** | `CLAUDE.md` (owned here) | Scannable non-negotiable rules + the subsystem map; links the DNA. |
| **`/feature`** | `rn-workflow` plugin | End-to-end feature workflow: Plan → Build → QA & Verify → Ship → Compound, with three human gates. |
| **`/fix`** | `rn-workflow` plugin | Bugfix workflow: repro-first → minimal diff → verify → PR. No feature ceremony. |
| **Hooks** | `rn-workflow` plugin | Automatic guardrails the harness runs around tool calls (below). |
| **Skills** | `rn-workflow` plugin | `figma-to-ui` (design → RN UI on the tech-DNA patterns) + `graphify` (codebase knowledge graph). |
| **Settings** | `.claude/settings.json` (owned here) | Denies destructive git + asks before `.env` edits (merged in by `/init-dna`). |
| **Memory + hookify** | Claude memory · `/hookify` | Where non-obvious discoveries and recurring-mistake preventions are captured. |

## How it works

### The genome is the source of truth for "how"

Every feature and every bugfix is written by **copying the patterns in `docs/tech-dna.md`** — the data pipeline (query → boundary fetch → Zod schema → mapper firewall → view-model → presentation), config-driven section rendering, Zustand+MMKV stores, token-only styling, and the rest. A task that needs a pattern with no precedent doesn't get an improvised one: the pattern is designed, approved (at the feature plan gate or flagged in the fix PR), and **added to `docs/tech-dna.md` in the same PR**. The DNA evolves deliberately; it is never bypassed.

### `/feature` — five phases, three gates

Run `/feature "<name>"` to build a feature in one session:

1. **Plan** — explore read-only, pull Figma node specs (via the `figma-to-ui` skill), get the contract, ask all clarifying questions in one batch, and persist two docs: a task plan at `docs/superpowers/plans/YYYY-MM-DD-<feature>.md` and a rebuild-grade spec at `docs/superpowers/specs/YYYY-MM-DD-<feature>-design.md`. **▸ Gate A: plan approval.**
2. **Build** — logic-first TDD; the data path through the pipeline; token-only UI; a `testID` on every interactive/landmark element; commit per slice.
3. **QA & Verify** (feature-scoped) — Jest+RTL branch/interaction tests, a green `yarn lint && yarn typecheck && yarn test && yarn check:env`, driving the real app with a screenshot per designed state, and a fresh-eyes review. Device e2e is ask-first, scoped to the one feature spec, never automatic. **▸ Gate B: QA-report skim.**
4. **Ship** — docs updated in the same PR, PR opened with the evidence bundle. **▸ Gate C: PR review.**
5. **Compound** — non-obvious discoveries → memory; recurring mistakes → a `/hookify` rule; new patterns → the DNA.

### `/fix` — repro-first, minimal diff

Run `/fix "<bug>"`: write a **failing test that captures the bug first** (no product-code edits before a repro exists), state the root cause with `file:line` + blast radius, make the smallest change that turns it green, sweep for sibling occurrences, verify with the green bar (lint + typecheck + jest), and open a PR whose body carries the root-cause paragraph + repro test name. The repro test stays in the suite forever.

**Both commands stop and ask on any ambiguity** and build only to the clarification — never guess-and-build.

### Hooks — the automatic guardrails

Declared in the plugin's `hooks/hooks.json`, run by the harness around tool calls (not by the agent):

| Hook | Event | What it does |
| ---- | ----- | ------------ |
| `protect-native.sh` | PreToolUse (Edit/Write) | Asks for confirmation before editing `ios/`, `android/`, or generated `graphify-out/`. |
| `post-edit.sh` | PostToolUse (Edit/Write) | Runs `eslint --fix` on the edited source file; a residual error feeds back. |
| `stop-test.sh` | Stop | Runs `jest --onlyChanged` when a turn ends; a red suite blocks completion. |
| `auto-learn.sh` | PostToolUse (Bash) | On a failed `yarn typecheck/lint/test/check:env` or native build, nudges: capture a non-obvious fix in memory or a `/hookify` rule. |

`.claude/settings.json` also **denies** destructive git (`push --force`, `reset --hard`, `clean -f`) and **asks** before any `.env*` edit.

### Enforcement layers, in order

A rule is enforced at the earliest layer that can catch it:

1. **The DNA + Hard Rules** — what the agent reads before writing.
2. **ESLint / TypeScript** — most style/type rules; `post-edit.sh` applies eslint per edit.
3. **The Stop hook** — changed-file tests must be green to finish.
4. **husky pre-commit** — `lint-staged` (eslint + prettier) on staged files (if configured).
5. **Human gates** — plan approval, QA skim, PR review.

## For a new developer

1. Read `docs/tech-dna.md` once — it's the shortest path to writing code that fits.
2. Skim `CLAUDE.md` → Hard Rules and the subsystem map.
3. Build features with `/feature`, fix bugs with `/fix` — the commands walk the gates and enforce the patterns.
4. Let the hooks run; if one blocks you, it's pointing at a real lint/test failure — fix it, don't route around it.
5. When you discover something non-obvious, put it in memory; when a mistake could recur, add a `/hookify` rule. The workflow is meant to compound.
