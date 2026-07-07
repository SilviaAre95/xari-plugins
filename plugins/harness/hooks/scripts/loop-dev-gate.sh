#!/usr/bin/env bash
# Stop hook: staged dev loop. Opt-in via .cc-loop-dev-active sentinel.
# Blocks stop until BOTH the deterministic gate (.cc-verify) is green AND the
# reviews marker (.cc-dev-reviews-passed) exists. Circuit breaker after
# max_retries failed deterministic attempts. Coexists with loop-gate.sh.
set -uo pipefail
INPUT=$(cat)
DIR="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // "."')}"
SENTINEL="$DIR/.cc-loop-dev-active"
STATE="$DIR/.cc-loop-dev-state"
MARKER="$DIR/.cc-dev-reviews-passed"
GATE_FILE="$DIR/.cc-verify"
CFG="$DIR/.cc-dev.yaml"
LOG="$DIR/.cc-loop-dev.log"

# 1. Not armed for loop-dev -> allow stop.
[ -f "$SENTINEL" ] || exit 0

# 2. max_retries from .cc-dev.yaml (default 3).
MAX=3
if [ -f "$CFG" ]; then
  v=$(grep -E '^max_retries:' "$CFG" | head -1 | sed -E 's/^max_retries:[[:space:]]*//; s/[^0-9].*$//')
  [[ "$v" =~ ^[0-9]+$ ]] && MAX="$v"
fi

# 3. Resolve the deterministic gate: env override (tests) > .cc-verify > default.
if [ -n "${CC_GATE_CMD:-}" ]; then GATE="$CC_GATE_CMD"
elif [ -f "$GATE_FILE" ]; then GATE="$(cat "$GATE_FILE")"
else GATE="npm run lint && npm run build && npm test"; fi

# 4. Stage 1 — deterministic gate.
if ! ( cd "$DIR" && eval "$GATE" ) >"$LOG" 2>&1; then
  rm -f "$MARKER"   # code changed / broke -> any prior reviews are stale
  ATTEMPTS=$(cat "$STATE" 2>/dev/null || echo 0); [[ "$ATTEMPTS" =~ ^[0-9]+$ ]] || ATTEMPTS=0
  ATTEMPTS=$((ATTEMPTS + 1)); echo "$ATTEMPTS" > "$STATE"
  TAIL="$(tail -40 "$LOG" 2>/dev/null)"
  if [ "$ATTEMPTS" -ge "$MAX" ]; then
    rm -f "$SENTINEL" "$STATE"
    jq -n --arg log "$TAIL" --arg max "$MAX" \
      '{decision:"block", reason:("Circuit breaker: deterministic gate still failing after " + $max + " attempts. Stop fixing and summarize what is still broken:\n" + $log)}'
    exit 0
  fi
  jq -n --arg n "$ATTEMPTS" --arg max "$MAX" --arg gate "$GATE" --arg log "$TAIL" \
    '{decision:"block", reason:("Deterministic gate failed (attempt " + $n + "/" + $max + "): " + $gate + "\nFix the failures and continue; do not stop until green.\n" + $log)}'
  exit 0
fi

# 5. Stage 2 — reviews marker.
if [ ! -f "$MARKER" ]; then
  GRADERS=$(grep -E '^graders:' "$CFG" 2>/dev/null | head -1 | sed -E 's/^graders:[[:space:]]*//')
  [ -z "$GRADERS" ] && GRADERS="[code-review, security, bugs]"
  jq -n --arg g "$GRADERS" \
    '{decision:"block", reason:("Deterministic gate is green. Now run the review stages: " + $g + ". Dispatch one subagent per grader against the diff, fix every blocking finding, and re-verify. When ALL graders are clean AND you have made no further code edits, create the marker to finish:\n\n  touch .cc-dev-reviews-passed\n\nDo NOT create the marker before the reviews are actually clean.")}'
  exit 0
fi

# 6. Both green: disarm and allow stop.
rm -f "$SENTINEL" "$STATE" "$MARKER" "$LOG"
exit 0
