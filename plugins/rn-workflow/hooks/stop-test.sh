#!/usr/bin/env bash
# Stop hook: run the tests related to changed files; a red suite blocks
# completion so a session never ends green-looking on top of failing tests.
# --onlyChanged keeps it fast (only tests touching the diff). stop_hook_active
# guards against a re-trigger loop.
INPUT=$(cat)
ACTIVE=$(printf '%s' "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{process.stdout.write(String(JSON.parse(d).stop_hook_active||false))}catch(e){process.stdout.write('false')}})")
[ "$ACTIVE" = "true" ] && exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# No package.json — nothing to gate on (non-JS project or bare dir).
[ -f package.json ] || exit 0

# Nothing changed -> nothing to gate on.
git diff --quiet HEAD 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard '*.ts' '*.tsx' '*.js' '*.jsx' 2>/dev/null)" ] && exit 0

OUT=$(yarn --silent jest --onlyChanged --passWithNoTests 2>&1)
if [ $? -ne 0 ]; then
  echo "Test suite related to changed files is RED — fix before finishing:" >&2
  echo "$OUT" | tail -60 >&2
  exit 2
fi
exit 0
