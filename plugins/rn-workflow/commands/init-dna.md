---
description: 'Scaffold the tech-DNA docs (CLAUDE.md + docs/) and settings into the current project.'
---

You are scaffolding the **rn-workflow tech-DNA** into the current project. The plugin ships the *machinery* (the `/feature`, `/fix` commands, the guardrail hooks, the `figma-to-ui` + `graphify` skills) — those are already active once the plugin is installed. This command copies in the *editable content* the project must own: `CLAUDE.md`, the `docs/` tree, and the project-level settings snippet.

**Golden rule: never clobber.** This project may already have a `CLAUDE.md`, a `docs/` tree, or a `.claude/settings.json`. Copy-if-absent; for anything that already exists, report it and ask before overwriting or merging. The scaffold is a *starting point*, not a reset.

The scaffold payload lives at `${CLAUDE_PLUGIN_ROOT}/scaffold/`.

## Steps

### 1. Survey what already exists

Run (from the project root):

```bash
echo "PLUGIN_SCAFFOLD=${CLAUDE_PLUGIN_ROOT}/scaffold"
ls -la "${CLAUDE_PLUGIN_ROOT}/scaffold" 2>/dev/null || echo "MISSING scaffold dir"
echo "--- project state ---"
[ -f CLAUDE.md ] && echo "HAS CLAUDE.md" || echo "no CLAUDE.md"
[ -d docs ] && echo "HAS docs/" || echo "no docs/"
[ -f docs/tech-dna.md ] && echo "HAS docs/tech-dna.md (already scaffolded?)" || echo "no docs/tech-dna.md"
[ -f .claude/settings.json ] && echo "HAS .claude/settings.json" || echo "no .claude/settings.json"
```

If `docs/tech-dna.md` already exists, this project was likely scaffolded before — **STOP and ask** the user whether they want to (a) skip, (b) diff against the current template, or (c) overwrite specific files. Do not proceed blindly.

### 2. Copy the docs tree (copy-if-absent)

Copy every file under `${CLAUDE_PLUGIN_ROOT}/scaffold/docs/` to `./docs/`, **skipping any file that already exists**, and copy `scaffold/CLAUDE.md` to `./CLAUDE.md` only if absent:

```bash
SRC="${CLAUDE_PLUGIN_ROOT}/scaffold"
# docs/ — create dirs, copy only missing files, list what was created vs skipped
while IFS= read -r f; do
  rel="${f#"$SRC"/}"
  if [ -e "./$rel" ]; then
    echo "SKIP (exists): $rel"
  else
    mkdir -p "./$(dirname "$rel")"
    cp "$f" "./$rel"
    echo "CREATE: $rel"
  fi
done < <(find "$SRC/docs" -type f)

# CLAUDE.md at project root
if [ -e ./CLAUDE.md ]; then
  echo "SKIP (exists): CLAUDE.md — see step 4 to merge the Hard Rules block"
else
  cp "$SRC/CLAUDE.md" ./CLAUDE.md
  echo "CREATE: CLAUDE.md"
fi
```

### 3. Merge the settings snippet into `.claude/settings.json`

`scaffold/settings.snippet.json` carries **project-level** permissions (deny destructive git; ask before `.env` edits). The workflow *hooks* come from the plugin — do **not** copy them here.

- If `.claude/settings.json` is absent: create `.claude/` and copy the snippet's `permissions` block into a new `settings.json` (drop the `//` comment key).
- If it exists: read it, **union** the snippet's `permissions.deny` and `permissions.ask` arrays into the existing ones (dedupe, don't remove anything already there), write it back. Preserve every other key. Show the user the before/after `permissions` block.

Do this as a careful read-merge-write (you are executing this, so use `node`/`jq` or read+edit) — never overwrite an existing settings file wholesale.

### 4. If `CLAUDE.md` already existed

Don't overwrite it. Instead, open `${CLAUDE_PLUGIN_ROOT}/scaffold/CLAUDE.md`, and propose merging its **Hard Rules** index and the **link to `docs/tech-dna.md`** into the project's existing `CLAUDE.md` — show the diff and let the user approve. The rest of their `CLAUDE.md` (subsystem map, project specifics) stays as-is.

### 5. Report + hand off the placeholders

Print a summary: files created, files skipped, the settings merge result. Then list the `<FILL IN …>` placeholders the user must complete — grep for them so the list is exact:

```bash
grep -rn "FILL IN" ./CLAUDE.md ./docs 2>/dev/null || echo "no FILL IN markers found"
```

Tell the user, in this order:

1. **The machinery is already live** — `/rn-workflow:feature`, `/rn-workflow:fix`, the hooks, and the `figma-to-ui` / `graphify` skills work now (the plugin is installed).
2. **Fill the `<FILL IN>` slots** in `docs/tech-dna.md` and `CLAUDE.md` — the backend boundary, env keys, subsystem map, brand tokens, and any project-specific rules. The RN best-practice rules are already written; you tighten the project-specific parts.
3. **Wire the hook commands** — the hooks assume `yarn lint` / `yarn typecheck` / `yarn test` / `yarn check:env`. If this project's scripts differ, either add matching `package.json` scripts or adjust. (The hooks no-op safely if there's no `package.json`.)
4. **Set up the doc index files** — `docs/decisions/README.md` and `docs/architecture/README.md` are seeded; add rows as you write ADRs / architecture docs.

**Do not commit** — leave the scaffold staged for the user to review and commit themselves.
