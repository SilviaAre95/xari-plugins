#!/usr/bin/env bash
# PreToolUse hook: auto-approve read-only tools in every tier so exploration never stalls.
set -uo pipefail
INPUT=$(cat)
TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')
case "$TOOL" in
  Read|Grep|Glob|NotebookRead)
    jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",permissionDecisionReason:"read-only tool auto-approved by harness"}}'
    ;;
  *)
    echo '{}'  # defer to normal permission flow (no permissionDecision set)
    ;;
esac
