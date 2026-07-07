#!/usr/bin/env bash
# Stop hook: production verify loop. Opt-in via .cc-deploy-active sentinel.
# Runs the deterministic prod-verify command; green => loop closed. Failing =>
# block "fix and redeploy". After max_redeploys => run the rollback command,
# disarm, and block telling the agent to escalate. Never leaves prod broken by
# an exhausted loop. Coexists with loop-gate.sh / loop-dev-gate.sh.
set -uo pipefail
INPUT=$(cat)
DIR="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // "."')}"
SENTINEL="$DIR/.cc-deploy-active"
STATE="$DIR/.cc-deploy-state"
CFG="$DIR/.cc-deploy.yaml"
LOG="$DIR/.cc-deploy.log"

# 1. Not armed for loop-deploy -> allow stop.
[ -f "$SENTINEL" ] || exit 0

# 2. max_redeploys from .cc-deploy.yaml (default 3).
MAX=3
if [ -f "$CFG" ]; then
  v=$(grep -E '^max_redeploys:' "$CFG" | head -1 | sed -E 's/^max_redeploys:[[:space:]]*//; s/[^0-9].*$//')
  [[ "$v" =~ ^[0-9]+$ ]] && MAX="$v"
fi

# 3. Resolve verify + rollback: env overrides (tests) > .cc-deploy.yaml.
if [ -n "${CC_DEPLOY_VERIFY_CMD:-}" ]; then VERIFY="$CC_DEPLOY_VERIFY_CMD"
elif [ -f "$CFG" ]; then VERIFY="$(grep -E '^verify:' "$CFG" | head -1 | sed -E 's/^verify:[[:space:]]*//')"
else VERIFY=""; fi
if [ -n "${CC_DEPLOY_ROLLBACK_CMD:-}" ]; then ROLLBACK="$CC_DEPLOY_ROLLBACK_CMD"
elif [ -f "$CFG" ]; then ROLLBACK="$(grep -E '^rollback:' "$CFG" | head -1 | sed -E 's/^rollback:[[:space:]]*//')"
else ROLLBACK=""; fi

# Strip surrounding quotes a YAML author may have added.
VERIFY="${VERIFY%\"}"; VERIFY="${VERIFY#\"}"
ROLLBACK="${ROLLBACK%\"}"; ROLLBACK="${ROLLBACK#\"}"

# 4. No verify command configured -> cannot gate; tell the agent and allow stop.
if [ -z "$VERIFY" ]; then
  jq -n '{decision:"block", reason:"loop-deploy is armed but .cc-deploy.yaml has no `verify:` command. Add one (health check + smoke + error-rate) or disarm with: rm .cc-deploy-active"}'
  rm -f "$SENTINEL" "$STATE"
  exit 0
fi

# 5. Run the prod-verify.
if ( cd "$DIR" && eval "$VERIFY" ) >"$LOG" 2>&1; then
  rm -f "$SENTINEL" "$STATE" "$LOG"
  exit 0   # prod healthy -> loop closed
fi

# 6. Unhealthy: increment redeploy counter.
ATTEMPTS=$(cat "$STATE" 2>/dev/null || echo 0); [[ "$ATTEMPTS" =~ ^[0-9]+$ ]] || ATTEMPTS=0
ATTEMPTS=$((ATTEMPTS + 1)); echo "$ATTEMPTS" > "$STATE"
TAIL="$(tail -40 "$LOG" 2>/dev/null)"

if [ "$ATTEMPTS" -ge "$MAX" ]; then
  # Exhausted: roll back to last-good, disarm, escalate.
  ROLLMSG="(no rollback command configured)"
  if [ -n "$ROLLBACK" ]; then
    if ( cd "$DIR" && eval "$ROLLBACK" ) >>"$LOG" 2>&1; then ROLLMSG="rolled back via: $ROLLBACK"; else ROLLMSG="ROLLBACK FAILED: $ROLLBACK — prod may be broken, act now"; fi
  fi
  rm -f "$SENTINEL" "$STATE"
  jq -n --arg max "$MAX" --arg roll "$ROLLMSG" --arg log "$TAIL" \
    '{decision:"block", reason:("Prod still failing after " + $max + " redeploys. " + $roll + ". STOP redeploying — escalate to the user with what broke and what you tried:\n" + $log)}'
  exit 0
fi

# 7. Under the cap: block and tell the agent to fix + redeploy.
jq -n --arg n "$ATTEMPTS" --arg max "$MAX" --arg log "$TAIL" \
  '{decision:"block", reason:("Prod verification failed (attempt " + $n + "/" + $max + "). Fix the issue (you may run /loop-dev) and redeploy; do not stop until prod verifies healthy.\n" + $log)}'
exit 0
