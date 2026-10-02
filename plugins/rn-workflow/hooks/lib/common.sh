#!/usr/bin/env bash
# Shared helpers for the rn-workflow hooks. Sourced, never run directly.

# True when the project wires its OWN copy of this hook in .claude/settings*.json (e.g. a repo set up
# before it used the plugin). The plugin then steps aside, so the same check never runs twice — two
# jest runs at once is what freezes a 16 GB machine.
project_has_own_hook() {
  local name="$1" f
  for f in "${CLAUDE_PROJECT_DIR:-.}/.claude/settings.json" "${CLAUDE_PROJECT_DIR:-.}/.claude/settings.local.json"; do
    [ -f "$f" ] && grep -q "hooks/${name}" "$f" && return 0
  done
  return 1
}

# Per-project state directory (outside the repo) for caches like "last green fingerprint".
rnwf_state_dir() {
  local id
  id=$(printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}" | shasum | cut -c1-12)
  local d="${TMPDIR:-/tmp}/rn-workflow-state/$id"
  mkdir -p "$d" && printf '%s' "$d"
}

# Heap cap (MB) for jest / eslint processes; override with RN_WORKFLOW_NODE_MAX_MB.
RNWF_MAX_MB="${RN_WORKFLOW_NODE_MAX_MB:-2048}"
RNWF_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run a heavy command bounded (one at a time, heap-capped, time-limited, whole tree killed) — see run-bounded.mjs.
rnwf_run() { node "$RNWF_LIB/run-bounded.mjs" "$@"; }
