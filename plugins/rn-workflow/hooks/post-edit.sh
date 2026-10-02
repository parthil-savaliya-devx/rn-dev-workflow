#!/usr/bin/env bash
# PostToolUse hook (Edit|Write): eslint --fix the single edited source file.
# Fast per-edit lint + autofix; a residual lint error feeds back to Claude
# (exit 2 shows stderr to Claude). Typecheck is deliberately NOT run here — a
# full `tsc --noEmit` per edit is too slow; it runs in the green bar before
# every commit (`lint --max-warnings=0 && typecheck && test`) and in CI.
#
# Built so it can never pile up: parallel edits fire this hook at the same time, and type-aware
# eslint loads the whole TypeScript project per run. So runs go one at a time per project (each
# waits up to 30 s for the previous one, else skips — the green bar lints before every commit),
# the heap is capped, and run-bounded kills eslint after 60 s. Skipped when the project wires its
# own copy of this hook. Uses the project's own eslint, so any package manager works.
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
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
project_has_own_hook post-edit.sh && exit 0

# No package.json or no local eslint in this project — no-op rather than error.
[ -f package.json ] || exit 0
ESLINT=node_modules/.bin/eslint
[ -x "$ESLINT" ] || exit 0

LINT_OUT=$(rnwf_run --name eslint --timeout 60 --wait 30 --max-mb "$RNWF_MAX_MB" -- "$ESLINT" --fix "$FILE" 2>&1)
case $? in
  0|75|124) exit 0 ;; # clean · busy (skipped) · too slow (stopped) — the green bar lints before commit
esac
printf '%s' "$LINT_OUT" | grep -q -i "heap out of memory\|JavaScript heap" && exit 0
echo "eslint failed on $FILE:" >&2
echo "$LINT_OUT" | tail -60 >&2
exit 2
