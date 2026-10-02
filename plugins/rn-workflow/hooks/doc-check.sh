#!/usr/bin/env bash
# Stop hook: when feature docs changed this turn, check they still follow the doc skill's format
# (both files, every section in order, IDs unique, who/when on every decision, index in sync).
# A problem blocks finishing (exit 2 — stderr goes to Claude) so messy docs never pile up.
# Only runs when docs/modules has uncommitted changes; projects without docs/modules are skipped.
# stop_hook_active guards against a re-trigger loop.
INPUT=$(cat)
ACTIVE=$(printf '%s' "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{process.stdout.write(String(JSON.parse(d).stop_hook_active||false))}catch(e){process.stdout.write('false')}})")
[ "$ACTIVE" = "true" ] && exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
[ -d docs/modules ] || exit 0
[ -n "$(git status --porcelain -- docs/modules 2>/dev/null)" ] || exit 0

OUT=$(node "${CLAUDE_PLUGIN_ROOT}/skills/doc/scripts/doc-check.mjs" . 2>&1)
if [ $? -ne 0 ]; then
  echo "Feature docs in docs/modules don't follow the doc format — fix them (ask the developer before changing any answer or decision):" >&2
  echo "$OUT" >&2
  exit 2
fi
exit 0
