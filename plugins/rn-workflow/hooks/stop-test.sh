#!/usr/bin/env bash
# Stop hook: run the tests related to changed files; a red suite blocks completion so a session
# never ends green-looking on top of failing tests. stop_hook_active guards against a re-trigger loop.
#
# Built so broken code can never freeze the machine:
#   • at most 2 jest workers, each heap-capped (RN_WORKFLOW_NODE_MAX_MB, default 2048) and recycled
#     above 512 MB idle — a runaway render loop crashes one worker instead of eating all RAM
#   • --bail stops at the first failing suite; --forceExit stops tests that leave open handles
#   • run-bounded kills jest AND all its workers after 240 s (below the hook's 300 s), on cancel, or
#     if this script is killed — nothing is left running in the background
#   • one run at a time per project; a run already in progress means this one is skipped
#   • skipped when nothing changed since the last green run (work stays uncommitted until approval,
#     so without this it would re-run on every turn)
#   • skipped when the project wires its own copy of this hook, so it never runs twice
# Override the jest flags with RN_WORKFLOW_JEST_ARGS.
INPUT=$(cat)
ACTIVE=$(printf '%s' "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{process.stdout.write(String(JSON.parse(d).stop_hook_active||false))}catch(e){process.stdout.write('false')}})")
[ "$ACTIVE" = "true" ] && exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
project_has_own_hook stop-test.sh && exit 0

# No package.json or no local jest — nothing to gate on.
[ -f package.json ] || exit 0
JEST=node_modules/.bin/jest
[ -x "$JEST" ] || exit 0

# Nothing changed -> nothing to gate on.
git diff --quiet HEAD 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard '*.ts' '*.tsx' '*.js' '*.jsx' 2>/dev/null)" ] && exit 0

# Same changes as the last green run -> nothing new to test.
STATE=$(rnwf_state_dir)
FP=$( { git diff HEAD 2>/dev/null; git ls-files --others --exclude-standard -z -- '*.ts' '*.tsx' '*.js' '*.jsx' 2>/dev/null | xargs -0 shasum 2>/dev/null; } | shasum | cut -d' ' -f1)
[ -f "$STATE/stop-test.green" ] && [ "$(cat "$STATE/stop-test.green")" = "$FP" ] && exit 0

EXTRA_ARGS=${RN_WORKFLOW_JEST_ARGS:---bail --forceExit --maxWorkers=2 --workerIdleMemoryLimit=512MB}
# shellcheck disable=SC2086 # EXTRA_ARGS is a deliberate word-split list of flags
OUT=$(rnwf_run --name jest --timeout 240 --wait 0 --max-mb "$RNWF_MAX_MB" -- "$JEST" --onlyChanged --passWithNoTests $EXTRA_ARGS 2>&1)
CODE=$?

case $CODE in
  0)
    printf '%s' "$FP" > "$STATE/stop-test.green"
    exit 0 ;;
  75) # another jest run for this project is already in progress
    exit 0 ;;
  124)
    printf '{"systemMessage":"rn-workflow: the changed-file tests ran longer than 240s, so they were stopped (all jest processes killed) to keep your machine responsive. Run your test command yourself to see the result."}'
    exit 0 ;;
esac

if printf '%s' "$OUT" | grep -q -i "heap out of memory\|JavaScript heap"; then
  echo "Tests ran out of memory (each jest worker is capped at ${RNWF_MAX_MB} MB so the machine stays usable). That usually means an infinite render loop or runaway recursion in the changed code — look for it before re-running. Last output:" >&2
else
  echo "Test suite related to changed files is RED — fix before finishing:" >&2
fi
echo "$OUT" | tail -60 >&2
exit 2
