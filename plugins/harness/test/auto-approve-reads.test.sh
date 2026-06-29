#!/usr/bin/env bash
# Dependency-free assertions for the auto-approve-reads PreToolUse hook.
set -uo pipefail
HOOK="$(dirname "$0")/../hooks/scripts/auto-approve-reads.sh"
fail=0
check() { # name | input-json | expect-decision-or-EMPTY
  local name="$1" input="$2" expect="$3"
  local out; out=$(printf '%s' "$input" | bash "$HOOK")
  local got; got=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "EMPTY"' 2>/dev/null || echo PARSE_ERR)
  if [ "$got" = "$expect" ]; then echo "ok   - $name"; else echo "FAIL - $name (got '$got' want '$expect')"; fail=1; fi
}
check "Read is approved"  '{"tool_name":"Read"}'  "allow"
check "Grep is approved"  '{"tool_name":"Grep"}'  "allow"
check "Glob is approved"  '{"tool_name":"Glob"}'  "allow"
check "Write defers"      '{"tool_name":"Write"}' "EMPTY"
check "Bash defers"       '{"tool_name":"Bash"}'  "EMPTY"
exit $fail
