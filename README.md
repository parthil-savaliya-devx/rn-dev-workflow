<div align="center">

<img src="./assets/banner.svg" alt="rn-dev-workflow — one install, every React Native project" width="840" />

<br/><br/>

**🦾 A drop-in AI development setup for React Native — installed with two commands.**

<p>
  <img src="https://img.shields.io/badge/React_Native-ready-61DAFB?style=for-the-badge&logo=react&logoColor=white&labelColor=0d1117" alt="React Native" />
  <img src="https://img.shields.io/badge/Claude_Code-plugin-D97757?style=for-the-badge&logo=anthropic&logoColor=white&labelColor=0d1117" alt="Claude Code plugin" />
  <img src="https://img.shields.io/badge/setup-2_commands-3fb950?style=for-the-badge&labelColor=0d1117" alt="2-command setup" />
</p>
<p>
  <img src="https://img.shields.io/github/stars/parthil-savaliya-devx/rn-dev-workflow?style=for-the-badge&logo=github&color=8957e5&labelColor=0d1117" alt="Stars" />
  <img src="https://img.shields.io/github/last-commit/parthil-savaliya-devx/rn-dev-workflow?style=for-the-badge&color=1f6feb&labelColor=0d1117" alt="Last commit" />
  <img src="https://img.shields.io/badge/PRs-welcome-a371f7?style=for-the-badge&labelColor=0d1117" alt="PRs welcome" />
</p>

<sub>

[⚡ Quick Start](#-quick-start) · [🤔 Why](#-why-does-this-exist) · [🧩 Mental Model](#-how-its-built-the-mental-model) · [📚 What You Get](#-what-you-actually-get) · [✏️ Customize](#️-making-it-yours) · [❓ FAQ](#-faq--troubleshooting)

</sub>

</div>

---

Ever started a new React Native app and spent the first week re-deciding the same things? Folder structure, how data flows, how state is stored, how styling works, what *"done"* means, how the AI assistant should behave… **rn-dev-workflow makes all of that a one-time install instead of a per-project chore.**

It's a private [Claude Code](https://claude.com/claude-code) **plugin marketplace**. Install it once, run one command inside any RN project, and that project instantly gets:

- 🧬 A **tech-DNA** — the canonical *"how we build things here"* playbook, so every project reads the same way.
- ⚙️ Two guided **workflows** — `/feature` to build something end-to-end, `/fix` to squash a bug — each with checkpoints where **you** stay in control.
- 🛡️ **Guardrails** that run automatically — auto-lint on save, tests must pass before a task is *done*, and a confirm-prompt before touching risky files.
- 🎨 A **Figma → UI** skill and a 🕸️ **codebase knowledge-graph** skill.

> [!TIP]
> **New here?** Skip straight to [🚀 Quick Start](#-quick-start). Everything else is reference for later.

### ⚡ TL;DR — the whole thing in 4 lines

```bash
/plugin marketplace add parthil-savaliya-devx/rn-dev-workflow   # 1. add      (once per machine)
/plugin install rn-workflow@rn-dev-workflow                     # 2. install  (once per machine)
/init-dna                                                       # 3. scaffold (once per project)
/feature "add a wishlist screen"                                # 4. build 🎉
```

---

## 🤔 Why does this exist?

<table>
<tr>
<td width="50%" valign="top">

### 🎯 Consistency
A feature you write today and one a teammate writes in three months should look like the same person wrote them. That only happens if everyone copies the **same documented patterns** instead of improvising. That's the **tech-DNA**.

</td>
<td width="50%" valign="top">

### ⚡ No more setup fatigue
Copy-pasting `.claude/` folders and doc templates between repos is tedious and drifts out of sync. A **plugin** fixes this: install once, and improvements flow to every project when you update.

</td>
</tr>
</table>

---

## 🧩 How it's built (the mental model)

There are **two layers**, delivered two different ways. This is the one concept worth understanding:

```mermaid
flowchart TD
    M["📦 rn-dev-workflow<br/>(marketplace)"] --> P["🔌 rn-workflow<br/>(plugin)"]
    P --> ENGINE["⚙️ THE MACHINERY<br/>commands · hooks · skills"]
    P --> INIT["🪄 /init-dna"]
    INIT --> DOCS["🧬 THE CONTENT<br/>CLAUDE.md · docs/tech-dna.md · templates"]
    ENGINE -.->|installed read-only<br/>identical for everyone| REPO["📱 Your RN Project"]
    DOCS -.->|copied in — you own & edit it| REPO

    style ENGINE fill:#1f6feb,stroke:#58a6ff,color:#fff
    style DOCS fill:#238636,stroke:#3fb950,color:#fff
    style REPO fill:#8957e5,stroke:#a371f7,color:#fff
```

| Layer | What it is | How you get it | Editable? |
| ----- | ---------- | -------------- | --------- |
| ⚙️ **Machinery** | `/feature` & `/fix`, the hooks, the skills | Installed as a **plugin** | ❌ Same for everyone — update centrally |
| 🧬 **Content** | `CLAUDE.md`, `docs/tech-dna.md`, templates | **Copied into your project** by `/init-dna` | ✅ **It's yours** — edit per project |

**In one line:** the plugin gives every project the same *engine*; the scaffold gives each project its own editable *rulebook*. 🏎️📖

---

## 🚀 Quick Start

<div align="center">

**Two commands to install · one to set up a project · then build.**

</div>

### 1️⃣ Add the marketplace *(once per machine)*
```
/plugin marketplace add parthil-savaliya-devx/rn-dev-workflow
```

### 2️⃣ Install the plugin *(once per machine)*
```
/plugin install rn-workflow@rn-dev-workflow
```
✨ `/feature`, `/fix`, the hooks, and the skills are now available everywhere.

### 3️⃣ Scaffold the docs into your project *(once per project)*
```
/init-dna
```
📥 Copies `CLAUDE.md` + a `docs/` folder into your repo. **Never overwrites** existing files.

### 4️⃣ Fill in the blanks
🔍 Search `docs/tech-dna.md` and `CLAUDE.md` for `<FILL IN>` markers — add your backend, env keys, fonts, etc. The best-practice rules are already written.

### 5️⃣ Build things 🎉
```
/feature "add a wishlist screen"
/fix "cart total is wrong when a coupon is applied"
```

---

## 📚 What you actually get

### ⚙️ The two workflows

<details open>
<summary><b>🛠️ <code>/feature "&lt;what you want&gt;"</code> — idea → PR, with 3 checkpoints</b></summary>

<br/>

```mermaid
flowchart LR
    P["1 · 📋 Plan"] -->|"✋ you approve"| B["2 · 🔨 Build"]
    B --> Q["3 · 🧪 QA & Verify"]
    Q -->|"✋ you skim"| S["4 · 🚢 Ship"]
    S -->|"✋ you review PR"| C["5 · 🧠 Compound"]

    style P fill:#1f6feb,stroke:#58a6ff,color:#fff
    style Q fill:#9e6a03,stroke:#e3b341,color:#fff
    style S fill:#238636,stroke:#3fb950,color:#fff
```

1. **📋 Plan** — explores your code, pulls Figma specs, asks *all* its questions at once, writes a plan + spec. → **you approve** ✋
2. **🔨 Build** — tests-first where there's logic, follows the tech-DNA, commits in small slices.
3. **🧪 QA & Verify** — lint + types + tests, drives the real app, screenshots each state. → **you skim** ✋
4. **🚢 Ship** — updates docs, opens the PR. → **you review** ✋
5. **🧠 Compound** — saves what it learned so it's never rediscovered.

</details>

<details>
<summary><b>🐛 <code>/fix "&lt;the bug&gt;"</code> — no ceremony, just discipline</b></summary>

<br/>

1. **🔬 Reproduce** it with a failing test first (no guessing).
2. **🔎 Investigate** and state the root cause (`file:line` + blast radius).
3. **✂️ Fix** with the smallest possible change.
4. **✅ Verify** everything's green.
5. **🚢 Ship** a PR with the root cause and evidence.

</details>

<details>
<summary><b>🪄 <code>/init-dna</code> — scaffolds the docs into your project</b></summary>

<br/>

The setup command from Quick Start step 3. Completely safe — it only **adds** files, asking before it touches anything that already exists.

</details>

> Both `/feature` and `/fix` **stop and ask** whenever something's unclear, and build *exactly* to your answer — they never guess. 🙌

### 🛡️ The guardrails — they run on their own

You never call these; they just happen in the background:

| Guardrail | When | What it does |
| :-------: | ---- | ------------ |
| 🧹 **Auto-lint** | After every file edit | Runs `eslint --fix` on the file you just changed |
| ✅ **Test gate** | When a task finishes | Runs changed-file tests — a red suite blocks *done* |
| 🚧 **Native guard** | Before editing `ios/` / `android/` / generated files | Asks you to confirm — those edits are usually mistakes |
| 💡 **Learn nudge** | After a failed build/test | Suggests saving a non-obvious fix so it's never re-found |

➕ Destructive git (`push --force`, `reset --hard`, `clean -f`) is blocked, and `.env` edits ask first.

> [!NOTE]
> The hooks expect standard scripts — `yarn lint`, `yarn typecheck`, `yarn test`, `yarn check:env`. No `package.json` or different scripts? The hooks **quietly no-op** (they won't error) — but add those scripts for the full experience.

### 🎨 The skills

- **`figma-to-ui`** — turn a Figma node into React Native UI that follows your tech-DNA. Give it a Figma link + a screenshot.
- **`graphify`** — build a searchable knowledge graph of your codebase, so *"how does X work?"* is a fast query, not a grep marathon.

### 🧬 The tech-DNA

The heart of it all — `docs/tech-dna.md`, a genome of copy-me patterns covering the data pipeline, state, styling, navigation, testing, and error handling. Ships as a **uniform baseline** (identical everywhere) with `<FILL IN>` slots for your specifics. Devs extend it as the project grows — that's expected, not cheating. 🌱

---

## ✏️ Making it yours

After `/init-dna`, everything under your project's `docs/` and `CLAUDE.md` belongs to **you**:

- 🖊️ **Fill the `<FILL IN>` slots** — backend, env keys, fonts, currency, integrations.
- 🗑️ **Delete what doesn't apply** — not commerce? Delete the money section. GraphQL-only? Delete the REST section.
- ➕ **Add new rules** as patterns emerge — document them in `tech-dna.md` in the same PR.
- 📜 **Record big changes** as ADRs in `docs/decisions/`.

---

## 🔄 Updating & maintaining

<table>
<tr>
<td width="50%" valign="top">

### 👤 As a user
Get the latest machinery:
```
/plugin marketplace update rn-dev-workflow
```
Your `docs/` are untouched — only commands/hooks/skills refresh.

</td>
<td width="50%" valign="top">

### 🛠️ As the maintainer
- **Command/hook/skill?** Edit here, bump `version` in `plugin.json`, push.
- **Baseline docs?** Edit `scaffold/`. New projects pick it up on next `/init-dna`.

</td>
</tr>
</table>

---

## 🗂️ What's in this repo

<details>
<summary><b>📁 Click to expand the repo layout</b></summary>

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

</details>

---

## ❓ FAQ & troubleshooting

<details>
<summary><b>Do I need to run <code>/init-dna</code> in every project?</b></summary><br/>
Yes — once per project. It's what gives each repo its own editable rulebook.
</details>

<details>
<summary><b>Will <code>/init-dna</code> overwrite my existing <code>CLAUDE.md</code> or docs?</b></summary><br/>
No. It copies only files that don't already exist, and asks before merging into anything that does.
</details>

<details>
<summary><b>The commands don't show up after installing.</b></summary><br/>
Make sure both steps ran: <code>/plugin marketplace add …</code> <em>then</em> <code>/plugin install rn-workflow@rn-dev-workflow</code>. Commands are namespaced — try <code>/rn-workflow:feature</code> if bare <code>/feature</code> clashes with something else.
</details>

<details>
<summary><b>The hooks don't seem to do anything.</b></summary><br/>
They need <code>yarn lint</code> / <code>yarn typecheck</code> / <code>yarn test</code> / <code>yarn check:env</code> scripts in your <code>package.json</code>. No <code>package.json</code>? They safely no-op.
</details>

<details>
<summary><b>Can I use npm/pnpm instead of yarn?</b></summary><br/>
The hooks and command text default to <code>yarn</code>. Adjust the scripts in your project (or the hooks) to match your package manager.
</details>

<details>
<summary><b>I want this private, not public.</b></summary><br/>
Flip the repo to private in GitHub settings — the install commands stay identical; teammates just need repo access and a <code>gh</code> login.
</details>

---

<div align="center">

**Built with [Claude Code](https://claude.com/claude-code) 🤖 · Contributions and rule-tweaks welcome — open a PR!**

<sub>⭐ If this saved you a week of project setup, drop a star.</sub>

</div>
