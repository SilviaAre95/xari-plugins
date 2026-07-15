#!/usr/bin/env bash
# Stop hook: staged dev loop. Opt-in via .cc-loop-dev-active sentinel.
# Blocks stop until BOTH the deterministic gate (.cc-verify) is green AND the
# reviews marker (.cc-dev-reviews-passed) exists and is fresh. Circuit breaker
# after max_retries failed deterministic attempts. Coexists with loop-gate.sh;
# serialized against sibling gates and overlapping sessions via gate-lock.sh.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gate-lock.sh"
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

# 2. One gate run at a time. Stop hooks run in parallel and sessions can
#    overlap; a concurrent run must not race the verify command or the state.
if ! gate_lock "$DIR"; then
  jq -n '{decision:"block", reason:"Another harness gate run is already in progress in this project (.cc-loop-gate.lock). Wait for it to finish, then try to stop again. If no gate is actually running, remove the stale lock: rm -rf .cc-loop-gate.lock"}'
  exit 0
fi

# 3. max_retries from .cc-dev.yaml (default 3).
MAX=3
if [ -f "$CFG" ]; then
  v=$(grep -E '^max_retries:' "$CFG" | head -1 | sed -E 's/^max_retries:[[:space:]]*//; s/[^0-9].*$//')
  [[ "$v" =~ ^[0-9]+$ ]] && MAX="$v"
fi

# 4. Resolve the deterministic gate: env override (tests) > .cc-verify > default.
if [ -n "${CC_GATE_CMD:-}" ]; then GATE="$CC_GATE_CMD"
elif [ -f "$GATE_FILE" ]; then GATE="$(cat "$GATE_FILE")"
else GATE="npm run lint && npm run build && npm test"; fi

# 5. Stage 1 — deterministic gate.
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

echo 0 > "$STATE"

# The reviews marker carries a fingerprint of the working tree (diff vs the
# merge-base with `base`) taken when the graders passed. Invariant under
# commits, so the PR stage never falsifies it; any tracked edit changes it.
BASE=$(grep -E '^base:' "$CFG" 2>/dev/null | head -1 | sed -E 's/^base:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//')
[ -z "$BASE" ] && BASE="main"
STAMP="git diff \"\$(git merge-base $BASE HEAD)\" | git hash-object --stdin > .cc-dev-reviews-passed"
tree_fp() {  # prints the fingerprint; prints nothing when git/base is unavailable
  local mb
  git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  mb=$(git -C "$DIR" merge-base "$BASE" HEAD 2>/dev/null) || return 0
  git -C "$DIR" diff "$mb" 2>/dev/null | git -C "$DIR" hash-object --stdin
}

# 6. Stage 2 — reviews marker must exist.
if [ ! -f "$MARKER" ]; then
  GRADERS=$(grep -E '^graders:' "$CFG" 2>/dev/null | head -1 | sed -E 's/^graders:[[:space:]]*//; s/[[:space:]]*#.*$//')
  [ -z "$GRADERS" ] && GRADERS="[code-review, security, bugs]"
  jq -n --arg g "$GRADERS" --arg stamp "$STAMP" \
    '{decision:"block", reason:("Deterministic gate is green. Now run the review stages: " + $g + ". Dispatch one subagent per grader against the diff, fix every blocking finding, and re-verify. When ALL graders are clean AND you have made no further code edits, stamp the marker to finish:\n\n  " + $stamp + "\n\n(outside a git repo: touch .cc-dev-reviews-passed)\n\nDo NOT create the marker before the reviews are actually clean.")}'
  exit 0
fi

# 7. Stage 3 — a stamped marker must still match the tree. Late edits (the
#    agent, or background jobs finishing after the graders passed) invalidate
#    the reviews; an empty marker (touch) is the legacy/non-git escape hatch.
if [ -s "$MARKER" ]; then
  FP=$(tree_fp)
  if [ -n "$FP" ] && [ "$(head -1 "$MARKER" | tr -d '[:space:]')" != "$FP" ]; then
    rm -f "$MARKER"
    jq -n --arg stamp "$STAMP" \
      '{decision:"block", reason:("Reviews marker is stale: the working tree changed after the graders passed (fingerprint mismatch — late edits or background jobs?). Re-run the affected graders on the current diff, fix any findings, then re-stamp:\n\n  " + $stamp)}'
    exit 0
  fi
fi

# 8. All green: disarm and allow stop.
rm -f "$SENTINEL" "$STATE" "$MARKER" "$LOG"
exit 0
