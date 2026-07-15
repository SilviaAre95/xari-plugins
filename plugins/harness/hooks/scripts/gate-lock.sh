# Shared mutex for the harness Stop gates. Sourced, not executed.
#
# Claude Code runs all Stop hooks for an event in PARALLEL, and overlapping
# sessions (interactive + headless) can fire a gate while a previous run's
# verify command is still executing. Two concurrent gate runs in one project
# dir clobber each other's build artifacts and logs, double-count attempts,
# and race the sentinel/marker deletions. gate_lock serializes them.
#
# mkdir-based because macOS ships no flock(1). Lock: .cc-loop-gate.lock/
# (covered by the .cc-loop-* gitignore pattern) with the holder's PID inside.
#
# Usage:  gate_lock "$DIR" || { <emit block JSON>; exit 0; }
# The lock is released by an EXIT trap set on acquisition.
gate_lock() {
  local dir="$1" pid
  GATE_LOCK="$dir/.cc-loop-gate.lock"
  if mkdir "$GATE_LOCK" 2>/dev/null; then
    echo $$ > "$GATE_LOCK/pid"
    trap 'rm -rf "$GATE_LOCK"' EXIT
    return 0
  fi
  pid=$(cat "$GATE_LOCK/pid" 2>/dev/null || true)
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    return 1  # live holder -> contended
  fi
  if [ -z "$pid" ] && [ -z "$(find "$GATE_LOCK" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then
    return 1  # no pid yet and lock is young: holder is between mkdir and echo
  fi
  # Stale (holder dead, or pid never written and lock >30min old): steal it.
  rm -rf "$GATE_LOCK"
  if mkdir "$GATE_LOCK" 2>/dev/null; then
    echo $$ > "$GATE_LOCK/pid"
    trap 'rm -rf "$GATE_LOCK"' EXIT
    return 0
  fi
  return 1  # lost the steal race to another instance
}
