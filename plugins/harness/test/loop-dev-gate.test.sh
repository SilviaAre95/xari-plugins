#!/usr/bin/env bash
# Tests for loop-dev-gate.sh — the staged Stop gate.
set -uo pipefail
GATE="$(cd "$(dirname "$0")/.." && pwd)/hooks/scripts/loop-dev-gate.sh"
pass=0; fail=0
run() { # run <cwd> ; feeds stdin JSON, prints hook stdout
  printf '{"cwd":"%s"}' "$1" | bash "$GATE"
}
check() { # check <name> <condition-desc> <actual> <expected-substring-or-EMPTY>
  local name="$1" actual="$3" want="$4"
  if [ "$want" = "EMPTY" ]; then
    if [ -z "$actual" ]; then echo "ok: $name"; pass=$((pass+1)); else echo "FAIL: $name (wanted empty, got: $actual)"; fail=$((fail+1)); fi
  else
    if printf '%s' "$actual" | grep -q "$want"; then echo "ok: $name"; pass=$((pass+1)); else echo "FAIL: $name (wanted '$want' in: $actual)"; fail=$((fail+1)); fi
  fi
}
check_not() { # check_not <name> <actual> <unwanted-fixed-string>
  local name="$1" actual="$2" unwanted="$3"
  if printf '%s' "$actual" | grep -qF "$unwanted"; then echo "FAIL: $name (unwanted '$unwanted' found in: $actual)"; fail=$((fail+1)); else echo "ok: $name"; pass=$((pass+1)); fi
}

# 1. Not armed -> allow (no output)
d=$(mktemp -d); out=$(run "$d"); check "not-armed allows" "" "$out" "EMPTY"; rm -rf "$d"

# 2. Armed + deterministic FAIL -> block+feedback, counter=1, marker cleared
d=$(mktemp -d); touch "$d/.cc-loop-dev-active" "$d/.cc-dev-reviews-passed"
out=$(CC_GATE_CMD="false" run "$d")
check "det-fail blocks" "" "$out" '"decision": *"block"'
check "det-fail feedback" "" "$out" "attempt 1/3"
check "det-fail clears marker" "" "$([ -f "$d/.cc-dev-reviews-passed" ] && echo present || echo gone)" "gone"
rm -rf "$d"

# 3. Armed + deterministic GREEN + no marker -> block asking for reviews, sentinel kept
d=$(mktemp -d); touch "$d/.cc-loop-dev-active"
out=$(CC_GATE_CMD="true" run "$d")
check "green-no-marker asks reviews" "" "$out" "review stages"
check "green-no-marker keeps sentinel" "" "$([ -f "$d/.cc-loop-dev-active" ] && echo present)" "present"
rm -rf "$d"

# 4. Armed + green + marker -> allow (no output), state cleaned
d=$(mktemp -d); touch "$d/.cc-loop-dev-active" "$d/.cc-dev-reviews-passed"
out=$(CC_GATE_CMD="true" run "$d")
check "green+marker allows" "" "$out" "EMPTY"
check "green+marker disarms" "" "$([ -f "$d/.cc-loop-dev-active" ] && echo present || echo gone)" "gone"
rm -rf "$d"

# 5. Circuit breaker: counter at max-1, fail -> trips, sentinel removed
d=$(mktemp -d); touch "$d/.cc-loop-dev-active"; echo 2 > "$d/.cc-loop-dev-state"
out=$(CC_GATE_CMD="false" run "$d")
check "circuit breaker trips" "" "$out" "Circuit breaker"
check "circuit breaker disarms" "" "$([ -f "$d/.cc-loop-dev-active" ] && echo present || echo gone)" "gone"
rm -rf "$d"

# 6. .cc-dev.yaml graders line with trailing comment -> comment stripped from feedback
d=$(mktemp -d); touch "$d/.cc-loop-dev-active"
printf 'graders: [a, b]   # some comment\n' > "$d/.cc-dev.yaml"
out=$(CC_GATE_CMD="true" run "$d")
check "graders comment stripped: shows list" "" "$out" 'review stages: \[a, b\]'
check_not "graders comment stripped: no comment text" "$out" "# some comment"
check_not "graders comment stripped: no bare #" "$out" "#"
rm -rf "$d"

# 7. Deterministic gate GREEN -> failure counter reset to 0
d=$(mktemp -d); touch "$d/.cc-loop-dev-active"; echo 2 > "$d/.cc-loop-dev-state"
out=$(CC_GATE_CMD="true" run "$d")
check "green resets counter" "" "$(cat "$d/.cc-loop-dev-state" 2>/dev/null)" "0"
rm -rf "$d"

echo "---"; echo "pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
