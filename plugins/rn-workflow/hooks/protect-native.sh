#!/usr/bin/env bash
# PreToolUse hook (Edit|Write): edits under ios/ or android/ require explicit
# user confirmation. Native code is out of the normal RN-app change surface;
# a stray edit there is almost always a mistake. graphify-out/ is regenerated
# (AST rebuild via husky) and must never be hand-edited either.
INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{process.stdout.write(JSON.parse(d).tool_input.file_path||'')}catch(e){}})")
[ -z "$FILE" ] && exit 0

case "$FILE" in
  */node_modules/*) exit 0 ;;
  */ios/*|ios/*|*/android/*|android/*)
    cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Native directory edit (ios/ or android/). Confirm this task explicitly involves native code before allowing."}}
JSON
    exit 0
    ;;
  */graphify-out/*|graphify-out/*)
    cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"graphify-out/ is generated (AST rebuild via husky). Hand-editing it will be overwritten — confirm this is intentional (e.g. editing graphify-out/CLAUDE.md, the only tracked file)."}}
JSON
    exit 0
    ;;
esac
exit 0
