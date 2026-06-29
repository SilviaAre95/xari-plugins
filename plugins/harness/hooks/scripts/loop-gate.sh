#!/usr/bin/env bash
# Stop hook: build-test-fix loop. Opt-in via .cc-loop-active sentinel.
# Blocks Claude from stopping until the project's verify gate is green, with a
# circuit breaker after MAX failed attempts. Recursion-guarded via stop_hook_active.
set -uo pipefail
MAX=5
INPUT=$(cat)
DIR="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // "."')}"
SENTINEL="$DIR/.cc-loop-active"
STATE="$DIR/.cc-loop-state"
GATE_FILE="$DIR/.cc-verify"
LOG="$DIR/.cc-loop.log"

# 1. Loop not armed -> allow stop.
[ -f "$SENTINEL" ] || exit 0

# 2. Already inside a stop-hook loop -> allow (prevent infinite re-entry).
if [ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

# 3. Resolve the gate command: env override (tests) > .cc-verify > default.
if [ -n "${CC_GATE_CMD:-}" ]; then
  GATE="$CC_GATE_CMD"
elif [ -f "$GATE_FILE" ]; then
  GATE="$(cat "$GATE_FILE")"
else
  GATE="npm run lint && npm run build && npm test"
fi

# 4. Run the gate.
if ( cd "$DIR" && eval "$GATE" ) >"$LOG" 2>&1; then
  rm -f "$SENTINEL" "$STATE" "$LOG"
  exit 0   # green -> allow stop
fi

# 5. Failed: increment attempt counter.
ATTEMPTS=$(cat "$STATE" 2>/dev/null || echo 0)
ATTEMPTS=$((ATTEMPTS + 1))
echo "$ATTEMPTS" > "$STATE"

TAIL="$(tail -40 "$LOG" 2>/dev/null)"

if [ "$ATTEMPTS" -ge "$MAX" ]; then
  # Circuit breaker: disarm, then block ONCE telling Claude to summarize.
  # Sentinel is now gone, so the next stop attempt is allowed.
  rm -f "$SENTINEL" "$STATE"
  jq -n --arg log "$TAIL" --arg max "$MAX" \
    '{decision:"block", reason:("Circuit breaker tripped: verify gate still failing after " + $max + " attempts. STOP trying to fix. Summarize for the user what is still failing, what you tried, and the last error below:\n" + $log)}'
  exit 0
fi

# 6. Under the cap: block and feed failures back so Claude fixes and continues.
jq -n --arg n "$ATTEMPTS" --arg max "$MAX" --arg gate "$GATE" --arg log "$TAIL" \
  '{decision:"block", reason:("Verify gate failed (attempt " + $n + "/" + $max + "): " + $gate + "\nFix the failures and continue; do not stop until green.\n" + $log)}'
exit 0
