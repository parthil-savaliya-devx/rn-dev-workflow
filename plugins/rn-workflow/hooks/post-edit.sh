#!/usr/bin/env bash
# PostToolUse hook (Edit|Write): eslint --fix the single edited source file.
# Fast per-edit lint + autofix; a residual lint error feeds back to Claude.
# Typecheck is deliberately NOT run here (a full `tsc --noEmit` per edit is too
# slow) — it runs on the Stop hook, husky pre-commit, and manual `yarn typecheck`.
#
# $CLAUDE_PROJECT_DIR is the USER's project (not the plugin). The script is
# located by the plugin via ${CLAUDE_PLUGIN_ROOT} in hooks.json.
INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{process.stdout.write(JSON.parse(d).tool_input.file_path||'')}catch(e){}})")
[ -z "$FILE" ] && exit 0

case "$FILE" in
  */node_modules/*|*/ios/*|*/android/*|*/vendor/*|*/graphify-out/*) exit 0 ;;
esac
case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# No package.json / eslint in this project — no-op rather than error.
[ -f package.json ] || exit 0

LINT_OUT=$(yarn --silent eslint --fix "$FILE" 2>&1)
if [ $? -ne 0 ]; then
  echo "eslint failed on $FILE:" >&2
  echo "$LINT_OUT" >&2
  exit 2
fi
exit 0
