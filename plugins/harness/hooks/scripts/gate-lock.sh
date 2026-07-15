# Shared mutex for the harness Stop gates. Sourced, not executed.
#
# Claude Code runs all Stop hooks for an event in PARALLEL, and overlapping
# sessions (interactive + headless) can fire a gate while a previous run's
# verify command is still executing. Two concurrent gate runs in one project
# dir clobber each other's build artifacts and logs, double-count attempts,
# and race the sentinel/marker deletions. gate_lock serializes them.
#
# mkdir-based because macOS ships no flock(1). Lock: .cc-loop-gate.lock/
# (gitignored: the .cc-loop-* glob here, an explicit entry via harness-init
# in consumer projects) with the holder's PID inside. Known limitation: if
# the dead holder's PID is recycled by a long-lived same-user process, the
# lock stays "live" until a human removes it.
#
# Usage:  gate_lock "$DIR" || { <emit block JSON>; exit 0; }
# Released by an EXIT trap set on acquisition (fatal signals are routed
# through exit so the trap also fires on hook timeout/interrupt).
_gate_lock_acquired() {
  echo $$ > "$GATE_LOCK/pid"
  trap 'rm -rf "$GATE_LOCK"' EXIT
  trap 'exit 129' HUP; trap 'exit 130' INT; trap 'exit 143' TERM
}
gate_lock() {
  local dir="$1" pid
  GATE_LOCK="$dir/.cc-loop-gate.lock"
  if mkdir "$GATE_LOCK" 2>/dev/null; then
    _gate_lock_acquired
    return 0
  fi
  pid=$(cat "$GATE_LOCK/pid" 2>/dev/null || true)
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    return 1  # live holder -> contended
  fi
  if [ -z "$pid" ] && [ -z "$(find "$GATE_LOCK" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then
    return 1  # no pid yet and lock is young: holder is between mkdir and echo
  fi
  # Stale (holder dead, or pid never written and lock >30min old). Steal by
  # atomic rename: exactly one contender wins the mv; losers stay contended
  # rather than deleting a lock a sibling may have just re-acquired.
  mv "$GATE_LOCK" "$GATE_LOCK.stale.$$" 2>/dev/null || return 1
  rm -rf "$GATE_LOCK.stale.$$"
  if mkdir "$GATE_LOCK" 2>/dev/null; then
    _gate_lock_acquired
    return 0
  fi
  return 1  # a third contender re-acquired first
}
