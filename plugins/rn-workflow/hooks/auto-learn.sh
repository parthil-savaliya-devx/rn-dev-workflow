#!/usr/bin/env bash
# auto-learn.sh — PostToolUse hook on Bash. Surfaces learning opportunities from
# failed project commands and successful commits. Output is shown to Claude as
# extra context (never blocks). Complements persistent memory + hookify: a
# non-obvious fix should become a memory entry or a hookify rule so the same
# mistake is never rebuilt. See docs/tech-dna.md (Evolving the DNA).

INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{process.stdout.write(JSON.parse(d).tool_name||'')}catch(e){}})")
[ "$TOOL_NAME" != "Bash" ] && exit 0

COMMAND=$(printf '%s' "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{process.stdout.write(JSON.parse(d).tool_input.command||'')}catch(e){}})")
EXIT_CODE=$(printf '%s' "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{const o=JSON.parse(d);process.stdout.write(String((o.tool_response&&o.tool_response.exit_code)!=null?o.tool_response.exit_code:0))}catch(e){process.stdout.write('0')}})")

case "$COMMAND" in
  *"yarn typecheck"*|*"tsc --noEmit"*)
    [ "$EXIT_CODE" != "0" ] && echo "LEARNING OPPORTUNITY — typecheck failed. If the root cause is non-obvious (strict-mode quirk, Zod z.infer inference, a project-specific type pattern), save it to persistent memory. Skip routine fixes." ;;
  *"yarn lint"*|*"eslint"*)
    [ "$EXIT_CODE" != "0" ] && echo "LEARNING OPPORTUNITY — lint failed. If the violation reflects a convention worth codifying, consider a docs/tech-dna.md addition or a hookify rule. Skip routine unused-import/order fixes." ;;
  *"yarn test"*|*"jest"*)
    [ "$EXIT_CODE" != "0" ] && echo "LEARNING OPPORTUNITY — tests failed. If the fix needed a non-obvious boundary mock or jest.setup pattern (mock-hoisting, barrel-path mocking, native-module mock), capture it in persistent memory so it is never rediscovered." ;;
  *"yarn check:env"*)
    [ "$EXIT_CODE" != "0" ] && echo "LEARNING OPPORTUNITY — env drift. A new key must land in the typed env accessor, ALL .env.* incl .env.example, and the environments doc (docs/tech-dna.md — Environment & runtime config)." ;;
  *"yarn ios"*|*"yarn android"*|*"gradlew"*|*"xcodebuild"*|*"pod install"*)
    [ "$EXIT_CODE" != "0" ] && echo "LEARNING OPPORTUNITY — native build failed. Pod/gradle/scheme-flavour/RN-upgrade gotchas are prime memory material if the fix was non-trivial." ;;
  *"git commit"*)
    [ "$EXIT_CODE" = "0" ] && echo "Committed. If this session produced a non-obvious discovery (design node, API/contract quirk, test/type pattern) or a new canonical pattern, record it (persistent memory / hookify / docs/tech-dna.md / ADR) before finishing." ;;
esac
exit 0
