#!/usr/bin/env bash
# auto-learn.sh — runs after Bash commands. Surfaces learning opportunities so a
# non-obvious fix becomes a memory entry, a hookify rule or a tech-dna addition
# instead of being rediscovered (docs/tech-dna.md — Evolving the DNA).
#
# Wired to two events (hooks.json):
#   PostToolUseFailure (Bash) — a command exited non-zero ("Exit code N" in `error`)
#   PostToolUse        (Bash) — a command succeeded (used for the commit nudge)
# The nudge reaches Claude as hookSpecificOutput.additionalContext — plain
# stdout from these events only goes to the debug log. Never blocks.
#
# Script names are matched loosely: yarn / npm run / pnpm / bun, and both
# `check:env` and `check-env`.

# Skipped when the project wires its own copy of this hook (never nudge twice).
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
project_has_own_hook auto-learn.sh && exit 0

INPUT=$(cat)
read_field() {
  printf '%s' "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{const o=JSON.parse(d);const v=$1;process.stdout.write(v==null?'':String(v))}catch(e){}})"
}
EVENT=$(read_field "o.hook_event_name")
TOOL=$(read_field "o.tool_name")
COMMAND=$(read_field "o.tool_input&&o.tool_input.command")
[ "$TOOL" != "Bash" ] && exit 0
[ -z "$COMMAND" ] && exit 0

say() {
  node -e 'process.stdout.write(JSON.stringify({hookSpecificOutput:{hookEventName:process.argv[1],additionalContext:process.argv[2]}}))' "$EVENT" "$1"
  exit 0
}
has() { printf '%s' "$COMMAND" | grep -Eq "$1"; }

RUN='(yarn|pnpm|bun|npm run|npm|bun run)'

if [ "$EVENT" = "PostToolUseFailure" ]; then
  ENV=0; TSC=0; LINT=0; TEST=0; NATIVE=0
  has "check[:-]env" && ENV=1
  has "(^|[^a-z])tsc( |$)|$RUN typecheck" && TSC=1
  has "eslint|$RUN lint" && LINT=1
  has "jest|$RUN test" && TEST=1
  has "$RUN (ios|android)|run-(ios|android)|gradlew|xcodebuild|pod install" && NATIVE=1
  COUNT=$((ENV + TSC + LINT + TEST + NATIVE))

  if [ "$COUNT" -gt 1 ]; then
    say "LEARNING OPPORTUNITY — a combined check (lint / typecheck / tests / env) failed. Once fixed: if the root cause was non-obvious, save it to persistent memory; if it reflects a convention, consider a docs/tech-dna.md addition or a hookify rule. Skip routine fixes."
  elif [ "$ENV" = 1 ]; then
    say "LEARNING OPPORTUNITY — env drift. A new key must land in the config-key declaration, ALL .env.* files incl .env.example, and the environments doc (docs/tech-dna.md — Environment & runtime config)."
  elif [ "$TSC" = 1 ]; then
    say "LEARNING OPPORTUNITY — typecheck failed. If the root cause is non-obvious (strict-mode quirk, Zod z.infer inference, a project-specific type pattern), save it to persistent memory. Skip routine fixes."
  elif [ "$LINT" = 1 ]; then
    say "LEARNING OPPORTUNITY — lint failed. If the violation reflects a convention worth codifying, consider a docs/tech-dna.md addition or a hookify rule. Skip routine unused-import/order fixes."
  elif [ "$TEST" = 1 ]; then
    say "LEARNING OPPORTUNITY — tests failed. If the fix needed a non-obvious boundary mock or jest.setup pattern (mock-hoisting, barrel-path mocking, native-module mock), capture it in persistent memory so it is never rediscovered."
  elif [ "$NATIVE" = 1 ]; then
    say "LEARNING OPPORTUNITY — native build failed. Pod/gradle/scheme-flavour/RN-upgrade gotchas are prime memory material if the fix was non-trivial."
  fi
  exit 0
fi

if [ "$EVENT" = "PostToolUse" ] && has "git commit"; then
  say "Committed. If this session produced a non-obvious discovery (design node, API/contract quirk, test/type pattern) or a new canonical pattern, record it (persistent memory / hookify / docs/tech-dna.md / ADR) before finishing."
fi
exit 0
