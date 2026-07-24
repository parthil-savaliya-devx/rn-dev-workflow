# 🦾 rn-dev-workflow

**A drop-in AI development setup for React Native projects — installed with two commands.**

Ever started a new React Native app and spent the first week re-deciding the same things? Folder structure, how data flows, how state is stored, how styling works, what "done" means, how the AI assistant should behave… This repo makes all of that a **one-time install** instead of a per-project chore.

It's a private [Claude Code](https://claude.com/claude-code) **plugin marketplace**. Install it once, run one command inside any RN project, and that project instantly gets:

- 🧬 A **tech-DNA** — the canonical "how we build things here" playbook, so every project reads the same way.
- ⚙️ Two guided **workflows** — `/feature` to build something end-to-end, `/fix` to squash a bug — each with sensible checkpoints where *you* stay in control.
- 🛡️ **Guardrails** that run automatically — auto-lint on save, tests must pass before a task is "done", and a nudge to confirm before touching risky files.
- 🎨 A **Figma → UI** skill and a **codebase knowledge-graph** skill.

> **New here? Jump to [Quick Start](#-quick-start).** Everything else is reference you can read later.

---

## 🤔 Why does this exist?

Two problems, one solution:

1. **Consistency.** A feature you write today and one a teammate writes in three months should look like the same person wrote them. That only happens if everyone copies the *same documented patterns* instead of improvising. That's the **tech-DNA**.
2. **Setup fatigue.** Copy-pasting `.claude/` folders and doc templates between repos is tedious and drifts out of sync. A **plugin** fixes this: install once, and improvements flow to every project when you update.

---

## 🧩 How it's built (the mental model)

There are **two layers**, delivered two different ways. This is the one concept worth understanding:

| Layer | What it is | How you get it | Can you edit it? |
| ----- | ---------- | -------------- | ---------------- |
| **The machinery** | The `/feature` & `/fix` commands, the hooks, the skills | Installed as a **plugin** (`/plugin install`) | No — it lives in the plugin, same for everyone. Update it centrally. |
| **The content** | `CLAUDE.md`, `docs/tech-dna.md`, doc templates | **Copied into your project** by `/init-dna` | **Yes — it's yours.** Edit it freely per project. |

Why split them? Because the machinery *should* be identical everywhere (so a fix helps all projects at once), but the rules *must* be editable per project (your backend, your fonts, your currency). Plugins install read-only, so `/init-dna` writes the editable docs into your repo where you own them.

**In one line:** the plugin gives every project the same *engine*; the scaffold gives each project its own editable *rulebook*.

---

## 🚀 Quick Start

### 1. Add this marketplace (once per machine)

In any Claude Code session, run:

```
/plugin marketplace add parthil-savaliya-devx/rn-dev-workflow
```

### 2. Install the plugin (once per machine)

```
/plugin install rn-workflow@rn-dev-workflow
```

That's it — `/feature`, `/fix`, the hooks, and the skills are now available everywhere.

### 3. Scaffold the docs into your project (once per project)

Open your React Native project in Claude Code and run:

```
/init-dna
```

This copies `CLAUDE.md` + a `docs/` folder into your repo (it **never overwrites** files you already have) and merges a few safe permission settings.

### 4. Fill in the blanks

Search your new `docs/tech-dna.md` and `CLAUDE.md` for `<FILL IN>` markers and complete them — your backend, env keys, fonts, etc. The generic best-practice rules are already written; you're just adding project specifics.

### 5. Build things

```
/feature "add a wishlist screen"
/fix "cart total is wrong when a coupon is applied"
```

---

## 📚 What you actually get

### The two workflows

#### `/feature "<what you want>"`
Walks a feature from idea to pull request in five phases, pausing at **three checkpoints** so you're never surprised:

1. **Plan** — explores your code, pulls Figma specs, asks *all* its questions at once, then writes a plan + a spec doc. → *You approve the plan.* ✋
2. **Build** — writes tests first where there's logic, follows the tech-DNA patterns, commits in small slices.
3. **QA & Verify** — runs lint + types + tests, drives the real app, screenshots each screen state. → *You skim the QA report.* ✋
4. **Ship** — updates docs and opens the PR. → *You review the PR.* ✋
5. **Compound** — saves anything non-obvious it learned so it's never rediscovered.

#### `/fix "<the bug>"`
No ceremony — just discipline:
1. **Reproduce** it with a failing test first (no guessing).
2. **Investigate** and state the root cause.
3. **Fix** with the smallest possible change.
4. **Verify** everything's green.
5. **Ship** a PR with the root cause and evidence.

> Both commands **stop and ask** whenever something's unclear, and build *exactly* to your answer — they never guess.

#### `/init-dna`
The setup command from Quick Start step 3. Safe to run — it only *adds* files, asking before it touches anything that already exists.

### The guardrails (hooks) — they run on their own

You don't call these; they just happen in the background:

| Guardrail | When | What it does |
| --------- | ---- | ------------ |
| 🧹 Auto-lint | After every file edit | Runs `eslint --fix` on the file you just changed. |
| ✅ Test gate | When a task finishes | Runs the tests for changed files — a red suite blocks "done" so you never end on broken tests. |
| 🚧 Native guard | Before editing `ios/`, `android/`, or generated files | Asks you to confirm — those edits are usually mistakes. |
| 💡 Learn nudge | After a failed build/test/typecheck | Suggests saving a non-obvious fix so it's never re-discovered. |

Plus: destructive git commands (`push --force`, `reset --hard`, `clean -f`) are blocked, and edits to `.env` files ask first.

> **Heads-up:** the hooks assume standard scripts — `yarn lint`, `yarn typecheck`, `yarn test`, `yarn check:env`. If your project has no `package.json` or uses different scripts, the hooks quietly do nothing (they won't error) — but for full value, add those scripts.

### The skills

- 🎨 **`figma-to-ui`** — turn a Figma node into React Native UI that follows your tech-DNA (theme tokens, the data pipeline, tests). Give it a Figma link + a screenshot.
- 🕸️ **`graphify`** — build a searchable knowledge graph of your codebase, so "how does X work?" is a fast query instead of a grep marathon.

### The tech-DNA (`docs/tech-dna.md`)

The heart of it all — a genome of copy-me patterns covering the data pipeline, state, styling, navigation, testing, error handling, and more. It ships as a **uniform baseline** (identical in every project) with clearly-marked `<FILL IN>` slots for your specifics. Devs extend it as the project grows — that's expected, not cheating.

---

## ✏️ Making it yours

After `/init-dna`, everything under your project's `docs/` and `CLAUDE.md` belongs to **you**:

- **Fill the `<FILL IN>` slots** — backend boundary, env keys, fonts, currency, integrations.
- **Delete what doesn't apply** — not a commerce app? Delete the money section. GraphQL-only? Delete the REST section.
- **Add new rules** as patterns emerge — when you invent a new pattern, document it in `tech-dna.md` in the same PR (the DNA is meant to grow).
- **Record big changes** as ADRs in `docs/decisions/` — especially if you swap out a baseline choice.

---

## 🔄 Updating & maintaining

**As a user** — to get the latest machinery:
```
/plugin marketplace update rn-dev-workflow
```
Your project's `docs/` are untouched (they're yours); only the commands/hooks/skills refresh.

**As the maintainer** — to improve the template for everyone:
- Change a **command / hook / skill?** Edit it here, bump the `version` in `plugins/rn-workflow/.claude-plugin/plugin.json`, push. Teammates get it on their next update.
- Change the **baseline docs?** Edit `plugins/rn-workflow/scaffold/`. New projects pick it up on their next `/init-dna`; existing projects already own their copy.

---

## 🗂️ What's in this repo

```
rn-dev-workflow/
├── .claude-plugin/
│   └── marketplace.json          # declares this marketplace + the plugin
└── plugins/rn-workflow/
    ├── .claude-plugin/plugin.json  # the plugin manifest
    ├── commands/                   # /feature, /fix, /init-dna
    ├── hooks/                      # the 4 guardrails + hooks.json
    ├── skills/                     # figma-to-ui, graphify
    └── scaffold/                   # ← what /init-dna copies into your project
        ├── CLAUDE.md
        ├── settings.snippet.json
        └── docs/
            ├── tech-dna.md
            ├── decisions/          # ADR template + index
            ├── architecture/       # subsystem docs + the AI-workflow guide
            ├── superpowers/        # plan + spec templates
            ├── runbooks/
            └── glossary.md
```

---

## ❓ FAQ & troubleshooting

**Do I need to run `/init-dna` in every project?**
Yes — once per project. It's what gives each repo its own editable rulebook.

**Will `/init-dna` overwrite my existing `CLAUDE.md` or docs?**
No. It copies only files that don't already exist, and asks before merging into anything that does.

**The commands don't show up after installing.**
Make sure both steps ran: `/plugin marketplace add …` *then* `/plugin install rn-workflow@rn-dev-workflow`. Commands are namespaced — try `/rn-workflow:feature` if bare `/feature` clashes with something else.

**The hooks don't seem to do anything.**
They need `yarn lint` / `yarn typecheck` / `yarn test` / `yarn check:env` scripts in your `package.json`. No `package.json`? They safely no-op.

**Can I use npm/pnpm instead of yarn?**
The hooks and command text default to `yarn`. Adjust the scripts in your project (or the hooks) to match your package manager.

**I want this private, not public.**
Flip the repo to private in GitHub settings — the install commands stay identical; teammates just need repo access and a `gh` login.

---

*Built with [Claude Code](https://claude.com/claude-code). Contributions and rule-tweaks welcome — open a PR.*
