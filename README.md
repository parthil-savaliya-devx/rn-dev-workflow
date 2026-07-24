# rn-dev-workflow

A private **Claude Code plugin marketplace** for React Native projects. It ships one plugin — **`rn-workflow`** — that gives every RN repo the same AI development setup:

- **`/feature`** and **`/fix`** — the end-to-end workflows (Plan → Build → QA → Ship → Compound, and repro-first bugfix), with human gates.
- **Guardrail hooks** — confirm native/generated edits, `eslint --fix` per edit, nudge learnings on failed commands, block finishing on a red changed-file test suite.
- **Skills** — `figma-to-ui` (design → RN UI on the tech-DNA patterns) and `graphify` (codebase knowledge graph).
- **`/init-dna`** — scaffolds the editable **tech-DNA docs** (`CLAUDE.md`, `docs/tech-dna.md`, ADR/architecture/plan/spec templates) into a project.

## Why two layers

| Layer | What | How it's delivered |
| ----- | ---- | ------------------ |
| **Machinery** | commands, hooks, skills | The **plugin** — installs identically everywhere; a fix propagates to every project on update. |
| **Content** | `tech-dna.md`, `CLAUDE.md`, doc templates | **Scaffolded** by `/init-dna` into the repo, then **owned and edited** there. Plugins install read-only, so the docs are written into the project instead. |

The tech-DNA is a **uniform baseline**: identical in every new project so they all read alike. Devs then fill the `<FILL IN>` slots (backend boundary, env keys, fonts, currency, integrations) and extend it per project.

## Setup (per developer, once per machine + once per project)

```bash
# 1. Add this marketplace (once per machine). Use your git host shorthand or URL:
/plugin marketplace add <your-org>/rn-dev-workflow

# 2. Install the plugin (once per machine, or per-project with --scope project):
/plugin install rn-workflow@rn-dev-workflow

# 3. In a project, scaffold the tech-DNA docs (once per project):
/init-dna
```

Then fill the `<FILL IN>` markers in `docs/tech-dna.md` and `CLAUDE.md`, and start building with `/feature` / fixing with `/fix`.

> After `/init-dna`, the workflow commands are namespaced by the plugin: `/rn-workflow:feature`, `/rn-workflow:fix`, `/rn-workflow:init-dna` (bare `/feature` also works when there's no name clash).

## Repo layout

```
.claude-plugin/marketplace.json        # declares this marketplace + the rn-workflow plugin
plugins/rn-workflow/
  .claude-plugin/plugin.json           # plugin manifest
  commands/{feature,fix,init-dna}.md   # slash commands
  hooks/hooks.json + *.sh              # PreToolUse / PostToolUse / Stop guardrails
  skills/{figma-to-ui,graphify}/       # bundled skills
  scaffold/                            # payload /init-dna copies into a project
    CLAUDE.md
    settings.snippet.json              # project-level permissions merged into .claude/settings.json
    docs/{tech-dna.md, decisions/, architecture/, runbooks/, superpowers/, glossary.md, README.md}
```

## Hooks assume a standard RN script set

`post-edit.sh` runs `yarn eslint --fix`; `stop-test.sh` runs `yarn jest --onlyChanged`; `auto-learn.sh` reacts to `yarn typecheck/lint/test/check:env`. A project without a `package.json` or those scripts is handled gracefully (the hooks no-op), but for full value the project should expose `lint`, `typecheck`, `test`, and `check:env` scripts.

## Maintaining this template

- **Improve the machinery** (commands/hooks/skills) here → bump `plugin.json` `version` → teammates `git pull` + `/plugin marketplace update rn-dev-workflow`.
- **Improve the baseline docs** → edit `plugins/rn-workflow/scaffold/`. New projects pick it up on their next `/init-dna`; existing projects already own their copy and merge changes deliberately.
- **Publish:** push this repo to your private git host; share the `/plugin marketplace add <org>/rn-dev-workflow` line.
