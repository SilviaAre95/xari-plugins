# /loop-deploy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/loop-deploy` command to the `harness` plugin: a production verification loop (deploy → watch → verify → fix→redeploy, roll back + escalate on exhaustion).

**Architecture:** Command-orchestrated + hook-enforced verify. The `/loop-deploy` command drives the agent through the side-effecting actions (approve → deploy → watch → redeploy). A `Stop` hook (`loop-deploy-gate.sh`) runs the **deterministic** prod-verify command (`verify` in `.cc-deploy.yaml`) on every stop attempt: green → loop closed; failing → block with "fix and redeploy"; after `max_redeploys` it runs the `rollback` command, disarms, and blocks telling the agent to escalate — so an exhausted loop never leaves prod broken. Mirrors `/loop-dev`'s gate shape with its own state files; coexists with `/loop-build` and `/loop-dev`.

**Tech Stack:** POSIX shell + `jq` (hook scripts); Markdown command files; YAML config via `grep`/`sed`.

## Global Constraints

- Build in **wayworks on branch `feat/work-loop-system`**. Commit there.
- Match harness hook conventions: bash + jq, `{decision:"block",reason}` to block a stop, `exit 0` with no output to allow it. Command frontmatter: `description` / `argument-hint` / `allowed-tools`.
- New state files (git-ignored, distinct from loop-build/loop-dev): sentinel `.cc-deploy-active`, counter `.cc-deploy-state`, log `.cc-deploy.log`. Config (committed): `.cc-deploy.yaml`.
- Default `max_redeploys: 3`. `CC_DEPLOY_VERIFY_CMD` env overrides the verify command (for tests); `CC_DEPLOY_ROLLBACK_CMD` overrides rollback (for tests).
- The gate NEVER runs `deploy`/`watch` (those are the agent's one-shot actions) — it only runs `verify`, and `rollback` on exhaustion.
- The prod-deploy approval + the DB-migration second gate are the agent/Ris approval-loop's responsibility (the command instructs them); the harness hook does not implement approval.

---

### Task 1: `loop-deploy-gate.sh` Stop hook + `.cc-deploy.yaml` template

**Files:**
- Create: `plugins/harness/hooks/scripts/loop-deploy-gate.sh`
- Create: `plugins/harness/templates/.cc-deploy.yaml`
- Test: `plugins/harness/test/loop-deploy-gate.test.sh`

**Interfaces:**
- Produces: a Stop hook enforcing the prod-verify loop with rollback-on-exhaustion. Consumed by Task 2 (hooks.json) and Task 3 (command arms its sentinel).

- [ ] **Step 1: Write the failing test** `plugins/harness/test/loop-deploy-gate.test.sh`

```bash
#!/usr/bin/env bash
# Tests for loop-deploy-gate.sh — the prod-verify loop gate.
set -uo pipefail
GATE="$(cd "$(dirname "$0")/.." && pwd)/hooks/scripts/loop-deploy-gate.sh"
pass=0; fail=0
run() { printf '{"cwd":"%s"}' "$1" | bash "$GATE"; }
has() { if printf '%s' "$2" | grep -q "$3"; then echo "ok: $1"; pass=$((pass+1)); else echo "FAIL: $1 (want '$3' in: $2)"; fail=$((fail+1)); fi; }
empty() { if [ -z "$2" ]; then echo "ok: $1"; pass=$((pass+1)); else echo "FAIL: $1 (want empty, got: $2)"; fail=$((fail+1)); fi; }
eq() { if [ "$2" = "$3" ]; then echo "ok: $1"; pass=$((pass+1)); else echo "FAIL: $1 (want '$3' got '$2')"; fail=$((fail+1)); fi; }

# 1. Not armed -> allow
d=$(mktemp -d); empty "not-armed allows" "$(run "$d")"; rm -rf "$d"

# 2. Armed + verify PASS -> allow (empty), state cleaned
d=$(mktemp -d); touch "$d/.cc-deploy-active"
out=$(CC_DEPLOY_VERIFY_CMD="true" run "$d")
empty "verify-pass allows" "$out"
eq "verify-pass disarms" "$([ -f "$d/.cc-deploy-active" ] && echo present || echo gone)" "gone"
rm -rf "$d"

# 3. Armed + verify FAIL (under cap) -> block, counter=1
d=$(mktemp -d); touch "$d/.cc-deploy-active"
out=$(CC_DEPLOY_VERIFY_CMD="false" run "$d")
has "verify-fail blocks" "$out" '"decision": *"block"'
has "verify-fail feedback" "$out" "attempt 1/3"
eq "verify-fail counts" "$(cat "$d/.cc-deploy-state")" "1"
eq "verify-fail keeps sentinel" "$([ -f "$d/.cc-deploy-active" ] && echo present)" "present"
rm -rf "$d"

# 4. Armed + verify FAIL at cap -> rollback runs, disarm, escalate message
d=$(mktemp -d); touch "$d/.cc-deploy-active"; echo 2 > "$d/.cc-deploy-state"
out=$(CC_DEPLOY_VERIFY_CMD="false" CC_DEPLOY_ROLLBACK_CMD="touch $d/ROLLED_BACK" run "$d")
has "cap triggers escalate" "$out" "escalate"
eq "rollback command ran" "$([ -f "$d/ROLLED_BACK" ] && echo yes || echo no)" "yes"
eq "cap disarms" "$([ -f "$d/.cc-deploy-active" ] && echo present || echo gone)" "gone"
rm -rf "$d"

# 5. max_redeploys read from .cc-deploy.yaml (with comment) -> cap honored at 2
d=$(mktemp -d); touch "$d/.cc-deploy-active"; echo 1 > "$d/.cc-deploy-state"
printf 'max_redeploys: 2   # keep it tight\n' > "$d/.cc-deploy.yaml"
out=$(CC_DEPLOY_VERIFY_CMD="false" CC_DEPLOY_ROLLBACK_CMD="true" run "$d")
has "cfg cap honored" "$out" "escalate"
rm -rf "$d"

echo "---"; echo "pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
```

- [ ] **Step 2: Run it to verify it fails** — Run: `bash plugins/harness/test/loop-deploy-gate.test.sh`
Expected: FAIL — script does not exist.

- [ ] **Step 3: Write `plugins/harness/hooks/scripts/loop-deploy-gate.sh`**

```bash
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
```
Then: `chmod +x plugins/harness/hooks/scripts/loop-deploy-gate.sh`

- [ ] **Step 4: Write the config template** `plugins/harness/templates/.cc-deploy.yaml`

```yaml
# /loop-deploy config. Committed per-project.
deploy: "vercel deploy --prod"     # command that deploys (the agent runs it once per attempt)
watch: "vercel inspect --wait"     # blocks until the deploy resolves
# verify: a single command that is 0 iff prod is healthy — compose health + smoke + error-rate:
verify: "curl -fsS https://app.example.com/health >/dev/null && npm run smoke:prod && npm run check:error-rate"
rollback: "vercel rollback"        # run when max_redeploys is exceeded — never leave prod broken
max_redeploys: 3
migrations_gate: true              # a DB migration deploy needs a SECOND explicit approval
```

- [ ] **Step 5: Run the tests to green** — Run: `bash plugins/harness/test/loop-deploy-gate.test.sh`
Expected: `pass=12 fail=0`.

- [ ] **Step 6: Commit**

```bash
git add plugins/harness/hooks/scripts/loop-deploy-gate.sh plugins/harness/templates/.cc-deploy.yaml plugins/harness/test/loop-deploy-gate.test.sh
git commit -m "feat(harness): loop-deploy Stop gate (prod verify + rollback on exhaustion) + config"
```

---

### Task 2: Register the hook + verify coexistence

**Files:**
- Modify: `plugins/harness/hooks/hooks.json`
- Test: `plugins/harness/test/loop-deploy-coexist.test.sh`

- [ ] **Step 1: Write the failing coexistence test** `plugins/harness/test/loop-deploy-coexist.test.sh`

```bash
#!/usr/bin/env bash
# loop-deploy gate must ignore the other loops' sentinels, and vice versa.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEP="$ROOT/hooks/scripts/loop-deploy-gate.sh"
DEV="$ROOT/hooks/scripts/loop-dev-gate.sh"
BUILD="$ROOT/hooks/scripts/loop-gate.sh"
pass=0; fail=0
empty() { if [ -z "$2" ]; then echo "ok: $1"; pass=$((pass+1)); else echo "FAIL: $1 got: $2"; fail=$((fail+1)); fi; }

# deploy gate ignores build + dev sentinels
d=$(mktemp -d); touch "$d/.cc-loop-active" "$d/.cc-loop-dev-active"
empty "deploy-gate ignores other sentinels" "$(printf '{"cwd":"%s"}' "$d" | bash "$DEP")"; rm -rf "$d"
# build + dev gates ignore deploy sentinel
d=$(mktemp -d); touch "$d/.cc-deploy-active"
empty "build-gate ignores deploy sentinel" "$(printf '{"cwd":"%s"}' "$d" | bash "$BUILD")"
empty "dev-gate ignores deploy sentinel" "$(printf '{"cwd":"%s"}' "$d" | bash "$DEV")"; rm -rf "$d"

echo "---"; echo "pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
```

- [ ] **Step 2: Run it** — Run: `bash plugins/harness/test/loop-deploy-coexist.test.sh` — Expected: PASS (the scripts already key off their own sentinels; this documents the invariant).

- [ ] **Step 3: Add the hook to `hooks.json`** — append a third entry to the `Stop` array:

```json
{ "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/loop-deploy-gate.sh" } ] }
```

- [ ] **Step 4: Validate JSON + rerun tests**

Run: `python3 -c "import json;json.load(open('plugins/harness/hooks/hooks.json'))" && echo JSON_OK`
Run: `bash plugins/harness/test/loop-deploy-coexist.test.sh`
Expected: `JSON_OK`; `pass=3 fail=0`.

- [ ] **Step 5: Commit**

```bash
git add plugins/harness/hooks/hooks.json plugins/harness/test/loop-deploy-coexist.test.sh
git commit -m "feat(harness): register loop-deploy Stop hook alongside loop-build/loop-dev"
```

---

### Task 3: The `/loop-deploy` command

**Files:**
- Create: `plugins/harness/commands/loop-deploy.md`

- [ ] **Step 1: Write `plugins/harness/commands/loop-deploy.md`**

````markdown
---
description: Deploy, watch, verify prod, and fix→redeploy until healthy (or roll back + escalate)
argument-hint: [--env prod|staging]
allowed-tools: Bash(touch:*), Bash(echo:*), Bash(cat:*), Bash(rm:*)
---

Read `.cc-deploy.yaml` (deploy, watch, verify, rollback, max_redeploys, migrations_gate). If it is missing, stop and ask the user to create it — do not guess deploy commands.

Then arm the deploy loop:

!`touch .cc-deploy-active && echo 0 > .cc-deploy-state && echo "loop-deploy armed"`

The deploy loop is **ARMED**. Execute these stages for the target below:

1. **Approve (hard gate).** Deploying to production is a risky action — get an explicit Approve/Deny first. If this deploy runs a **database migration** and `.cc-deploy.yaml` `migrations_gate` is true, get a **second** explicit approval that names the migration. Never deploy prod or run a migration unattended.
2. **Deploy.** Run the `deploy` command. Post to Slack a "🚀 deploying <target>" start ping (bare URLs only).
3. **Watch.** Run the `watch` command until the deploy resolves. If it fails or times out, treat it as a failed verify and go to the fix path.
4. **Verify.** When you attempt to finish, the `Stop` hook runs the `verify` command (health + smoke + error-rate). If it fails, it blocks: fix the problem (you may run `/loop-dev` for a code fix) and **redeploy**. Do not stop until prod verifies healthy.
5. **Exhaustion.** After `max_redeploys` failed attempts the hook runs the `rollback` command, disarms, and tells you to stop — then post to `#alerts`: "⚠️ <target> failed to deploy, rolled back — <one-line why>". Never leave prod broken.
6. **Success.** When verify passes, the loop closes. Post to Slack: "🚀 <target> deployed, prod healthy" with the bare deployment URL, and move the Linear issue to Done.

The `Stop` hook enforces the verify gate — you cannot finish while prod verification is failing, and you cannot exceed the redeploy budget without a rollback.

Target: $ARGUMENTS
````

- [ ] **Step 2: Verify arming works** — Run:
```bash
d=$(mktemp -d); (cd "$d" && touch .cc-deploy-active && echo 0 > .cc-deploy-state && echo armed); ls -a "$d" | grep cc-deploy; rm -rf "$d"
```
Expected: prints `armed`; `.cc-deploy-active` + `.cc-deploy-state` exist.

- [ ] **Step 3: Commit**

```bash
git add plugins/harness/commands/loop-deploy.md
git commit -m "feat(harness): /loop-deploy command (deploy→watch→verify→redeploy/rollback)"
```

---

### Task 4: `harness-init` scaffold + README

**Files:**
- Modify: `plugins/harness/commands/harness-init.md`
- Modify: `plugins/harness/README.md`

- [ ] **Step 1: Read `plugins/harness/commands/harness-init.md`**, then add steps that: copy `templates/.cc-deploy.yaml` to the project root if absent, and add `.cc-deploy-active`, `.cc-deploy-state`, `.cc-deploy.log` to the git-ignore block. Leave `.cc-deploy.yaml` tracked (committed config).

- [ ] **Step 2: Update `plugins/harness/README.md`** — add a `/loop-deploy` subsection under "The loop": deploy → watch → verify (health + smoke + error-rate) → fix→redeploy until healthy; after `max_redeploys` it runs `rollback` and escalates so prod is never left broken; prod deploy + DB migrations are hard Approve/Deny gates; config in `.cc-deploy.yaml`. Add the new state files to the "State files" lists (git-ignored: the 3 state files; committed: `.cc-deploy.yaml`).

- [ ] **Step 3: Commit**

```bash
git add plugins/harness/commands/harness-init.md plugins/harness/README.md
git commit -m "docs(harness): scaffold .cc-deploy.yaml in harness-init; document /loop-deploy"
```

---

### Task 5: End-to-end smoke verification

**Files:**
- Create: `plugins/harness/test/loop-deploy-smoke.md`

- [ ] **Step 1: Write `plugins/harness/test/loop-deploy-smoke.md`** documenting a reproducible scenario driving the gate through its transitions in a scratch dir, using `CC_DEPLOY_VERIFY_CMD` / `CC_DEPLOY_ROLLBACK_CMD` overrides:
  - armed + verify fails (`CC_DEPLOY_VERIFY_CMD=false`), counter under cap → block "Fix the issue … redeploy", counter increments.
  - armed + verify passes (`CC_DEPLOY_VERIFY_CMD=true`) → allow (empty), state cleaned = loop closed.
  - armed + verify fails at cap (state = max-1, `CC_DEPLOY_ROLLBACK_CMD="touch ROLLED_BACK"`) → rollback command runs, disarm, block "escalate".
  Include exact commands + expected outputs (mirror the assertions in `loop-deploy-gate.test.sh`).

- [ ] **Step 2: Run the documented scenario once**, confirm the transitions, and record real results under "## Verified run".

- [ ] **Step 3: Commit**

```bash
git add plugins/harness/test/loop-deploy-smoke.md
git commit -m "test(harness): documented loop-deploy end-to-end smoke scenario"
```

---

## Self-Review

- **Spec coverage** (`2026-07-05-loop-deploy-design.md`): deploy → watch → verify → fix→redeploy loop (Task 1 gate + Task 3 command) ✓; provider-agnostic via `.cc-deploy.yaml` (Task 1) ✓; prod deploy + migration hard-gates (Task 3, via the approval loop) ✓; rollback + escalate on `max_redeploys` (Task 1) ✓; success/failure notifications incl. `#alerts` on rollback (Task 3) ✓; coexist with loop-build/loop-dev (Task 2) ✓; state files git-ignored (Task 4) ✓. Deviations from spec, consciously: `verify` is a single composed command (health+smoke+errors folded into one) rather than three sub-keys — simpler and shell-enforceable; the no-progress/identical-findings early guard is not implemented (only the redeploy cap), matching the /loop-dev scope decision.
- **Placeholder scan:** gate, config, tests, command complete; no TBDs.
- **Type/name consistency:** `.cc-deploy-active` / `.cc-deploy-state` / `.cc-deploy.log` / `.cc-deploy.yaml` used identically across Tasks 1–5 and distinct from loop-build's and loop-dev's state files.
