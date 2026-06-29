# Harness Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reusable `harness` Claude Code plugin (tiered autonomy + build-test-fix loop) plus the settings-side permission policy it depends on.

**Architecture:** Tiers map onto native permission modes (Shift+Tab); a `Stop` hook drives an opt-in build-test-fix loop with a 5-attempt circuit breaker; a `PreToolUse` hook auto-approves read-only tools. Permission policy lives in `settings.json` (a plugin cannot grant permissions); the plugin's `/harness-init` command writes it interactively.

**Tech Stack:** Claude Code plugin (plugin.json + hooks.json + markdown commands), POSIX bash + `jq` for hook scripts. Dependency-free bash test harnesses (the repo has no test framework today).

## Global Constraints

- Public-safe: no secrets, no machine-specific absolute paths in committed files. README/command examples are generic.
- Hook scripts must be POSIX bash, executable (`chmod +x`), and reference themselves via `${CLAUDE_PLUGIN_ROOT}`.
- `jq` is an assumed dependency (already in the user's toolset).
- Plugin name: `harness`. Marketplace owner/author: `Silvia Arellano`. Repo: `https://github.com/SilviaAre95/xari-plugins`. License: `MIT`. Version: `1.0.0`.
- Permission precedence is `deny` > `ask` > `allow`. The floor (`deny`) applies in every tier including `bypassPermissions`.
- State files (git-ignored, per project): `.cc-loop-active` (sentinel), `.cc-loop-state` (attempt counter), `.cc-verify` (optional gate override). Default gate: `npm run lint && npm run build && npm test`.
- Circuit breaker: `MAX=5` attempts.
- Branch: `feat/harness-plugin`. Conventional commits.

---

## File Structure

```
plugins/harness/
  .claude-plugin/plugin.json          # manifest: commands + hooks
  hooks/hooks.json                    # registers PreToolUse + Stop hooks
  hooks/scripts/auto-approve-reads.sh # PreToolUse: approve read-only tools
  hooks/scripts/loop-gate.sh          # Stop: build-test-fix loop + breaker
  commands/loop-build.md              # arm loop + frame task
  commands/harness-init.md            # write permission policy into a project (with approval)
  test/auto-approve-reads.test.sh     # bash test harness
  test/loop-gate.test.sh              # bash test harness (decision table)
  README.md                           # docs + the permission policy users must add
.claude-plugin/marketplace.json       # +1 entry: harness
docs/reference/permission-policy.md   # canonical floor/allow/ask block (sourced by README + harness-init)
```

---

### Task 1: Plugin scaffold + marketplace registration

**Files:**
- Create: `plugins/harness/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (add `harness` to the `plugins` array)

**Interfaces:**
- Produces: a loadable plugin named `harness` referencing `./commands/` and `./hooks/hooks.json`. (Files those point at are created in later tasks; this task only establishes the manifest.)

- [ ] **Step 1: Write `plugins/harness/.claude-plugin/plugin.json`**

```json
{
  "name": "harness",
  "version": "1.0.0",
  "description": "Tiered autonomy + build-test-fix loop for hands-off AI workflows",
  "author": {
    "name": "Silvia Arellano"
  },
  "repository": "https://github.com/SilviaAre95/xari-plugins",
  "license": "MIT",
  "keywords": ["workflow", "automation", "hooks", "autonomy", "loop"],
  "commands": "./commands/",
  "hooks": "./hooks/hooks.json"
}
```

- [ ] **Step 2: Register in `.claude-plugin/marketplace.json`**

Add this object to the `plugins` array (after the `pm` entry):

```json
    {
      "name": "harness",
      "source": "./plugins/harness",
      "description": "Tiered autonomy + build-test-fix loop for hands-off AI workflows",
      "version": "1.0.0",
      "category": "workflow",
      "tags": ["workflow", "automation", "hooks", "autonomy", "loop"]
    }
```

- [ ] **Step 3: Validate JSON**

Run: `jq . plugins/harness/.claude-plugin/plugin.json && jq . .claude-plugin/marketplace.json`
Expected: both pretty-print with no parse error.

- [ ] **Step 4: Commit**

```bash
git add plugins/harness/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "feat(harness): scaffold plugin manifest and register in marketplace"
```

---

### Task 2: PreToolUse auto-approve-reads hook

**Files:**
- Create: `plugins/harness/hooks/scripts/auto-approve-reads.sh`
- Create: `plugins/harness/hooks/hooks.json`
- Create (test): `plugins/harness/test/auto-approve-reads.test.sh`

**Interfaces:**
- Consumes: PreToolUse hook JSON on stdin with field `.tool_name`.
- Produces: on read-only tools, prints `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow",...}}` and exits 0; otherwise exits 0 with no output (defers to normal permission flow). `hooks.json` registers this under `PreToolUse` with matcher `Read|Grep|Glob|NotebookRead`.

- [ ] **Step 1: Write the failing test `plugins/harness/test/auto-approve-reads.test.sh`**

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash plugins/harness/test/auto-approve-reads.test.sh`
Expected: FAIL — script not found / no output (hook doesn't exist yet).

- [ ] **Step 3: Write `plugins/harness/hooks/scripts/auto-approve-reads.sh`**

```bash
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
    exit 0  # defer to normal permission flow
    ;;
esac
```

- [ ] **Step 4: Write `plugins/harness/hooks/hooks.json`**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Grep|Glob|NotebookRead",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/auto-approve-reads.sh" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/loop-gate.sh" }
        ]
      }
    ]
  }
}
```
> The `Stop` entry references `loop-gate.sh`, created in Task 3. That's fine — the hook only fires at runtime, after Task 3 lands.

- [ ] **Step 5: Make executable and run test to verify it passes**

Run: `chmod +x plugins/harness/hooks/scripts/auto-approve-reads.sh plugins/harness/test/auto-approve-reads.test.sh && bash plugins/harness/test/auto-approve-reads.test.sh`
Expected: all 5 lines `ok`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add plugins/harness/hooks plugins/harness/test/auto-approve-reads.test.sh
git commit -m "feat(harness): add PreToolUse auto-approve-reads hook + hooks.json"
```

---

### Task 3: Stop hook — build-test-fix loop + circuit breaker

**Files:**
- Create: `plugins/harness/hooks/scripts/loop-gate.sh`
- Create (test): `plugins/harness/test/loop-gate.test.sh`

**Interfaces:**
- Consumes: Stop hook JSON on stdin with fields `.stop_hook_active` (bool) and `.cwd` (string). Reads env `CLAUDE_PROJECT_DIR` (preferred) else `.cwd`. Reads project files `.cc-loop-active`, `.cc-loop-state`, `.cc-verify`. Honors env `CC_GATE_CMD` override (used by tests to inject a fake gate).
- Produces: prints `{"decision":"block","reason":...}` to keep iterating; exits 0 with no block to allow stop. On green or breaker it removes `.cc-loop-active` and `.cc-loop-state`.

- [ ] **Step 1: Write the failing test `plugins/harness/test/loop-gate.test.sh`**

```bash
#!/usr/bin/env bash
# Decision-table tests for the loop-gate Stop hook. Uses a temp project dir and
# CC_GATE_CMD to fake pass/fail without a real build.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")/../hooks/scripts" && pwd)/loop-gate.sh"
fail=0
decision() { printf '%s' "$1" | jq -r '.decision // "ALLOW"' 2>/dev/null || echo PARSE_ERR; }

# helper: run hook in a fresh temp dir; args: armed(0/1) gatecmd stop_active
run() {
  local armed="$1" gate="$2" stopactive="$3"
  local dir; dir=$(mktemp -d)
  [ "$armed" = "1" ] && touch "$dir/.cc-loop-active"
  CLAUDE_PROJECT_DIR="$dir" CC_GATE_CMD="$gate" \
    printf '{"stop_hook_active":%s,"cwd":"%s"}' "$stopactive" "$dir" \
    | CLAUDE_PROJECT_DIR="$dir" CC_GATE_CMD="$gate" bash "$HOOK"
  echo "::$dir"  # emit dir on its own marker line for post-checks
}

check() { local name="$1" got="$2" want="$3"; if [ "$got" = "$want" ]; then echo "ok   - $name"; else echo "FAIL - $name (got '$got' want '$want')"; fail=1; fi; }

# 1. Not armed -> allow stop (no output)
out=$(run 0 "true" false); d=$(decision "$(printf '%s' "$out" | grep -v '^::')"); check "unarmed allows stop" "$d" "ALLOW"

# 2. stop_hook_active -> allow (recursion guard)
out=$(run 1 "false" true); d=$(decision "$(printf '%s' "$out" | grep -v '^::')"); check "stop_hook_active allows stop" "$d" "ALLOW"

# 3. Armed + gate passes -> allow + sentinel removed
out=$(run 1 "true" false); dir=$(printf '%s' "$out" | sed -n 's/^:://p'); d=$(decision "$(printf '%s' "$out" | grep -v '^::')")
check "green allows stop" "$d" "ALLOW"
[ -f "$dir/.cc-loop-active" ] && { echo "FAIL - green removes sentinel"; fail=1; } || echo "ok   - green removes sentinel"

# 4. Armed + gate fails, attempt < MAX -> block
out=$(run 1 "false" false); d=$(decision "$(printf '%s' "$out" | grep -v '^::')")
check "fail under cap blocks stop" "$d" "block"

# 5. Armed + gate fails at MAX -> block once (summary) AND sentinel removed
dir=$(mktemp -d); touch "$dir/.cc-loop-active"; echo 4 > "$dir/.cc-loop-state"
out=$(CLAUDE_PROJECT_DIR="$dir" CC_GATE_CMD="false" printf '{"stop_hook_active":false,"cwd":"%s"}' "$dir" | CLAUDE_PROJECT_DIR="$dir" CC_GATE_CMD="false" bash "$HOOK")
d=$(decision "$out"); check "breaker still blocks once to summarize" "$d" "block"
[ -f "$dir/.cc-loop-active" ] && { echo "FAIL - breaker removes sentinel"; fail=1; } || echo "ok   - breaker removes sentinel"

exit $fail
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash plugins/harness/test/loop-gate.test.sh`
Expected: FAIL — `loop-gate.sh` does not exist.

- [ ] **Step 3: Write `plugins/harness/hooks/scripts/loop-gate.sh`**

```bash
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
```

- [ ] **Step 4: Make executable and run test to verify it passes**

Run: `chmod +x plugins/harness/hooks/scripts/loop-gate.sh plugins/harness/test/loop-gate.test.sh && bash plugins/harness/test/loop-gate.test.sh`
Expected: all `ok`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add plugins/harness/hooks/scripts/loop-gate.sh plugins/harness/test/loop-gate.test.sh
git commit -m "feat(harness): add Stop-hook build-test-fix loop with circuit breaker"
```

---

### Task 4: `/loop-build` command

**Files:**
- Create: `plugins/harness/commands/loop-build.md`

**Interfaces:**
- Consumes: `$ARGUMENTS` (the task description). The Stop hook from Task 3 (reads `.cc-loop-active`).
- Produces: a slash command that arms the sentinel, resets the counter, and frames the task.

- [ ] **Step 1: Write `plugins/harness/commands/loop-build.md`**

````markdown
---
description: Arm the build-test-fix loop, then implement a task that runs to green
argument-hint: <task description>
allowed-tools: Bash(touch:*), Bash(echo:*)
---

Arm the loop for this project:

!`touch .cc-loop-active && echo 0 > .cc-loop-state && echo "loop armed"`

The build-test-fix loop is now **ARMED**. Implement the task below. When you think you are done, the `Stop` hook runs this project's verify gate (`.cc-verify` if present, else `npm run lint && npm run build && npm test`):

- Gate **passes** → you're allowed to finish.
- Gate **fails** → you'll be told the failures; fix them and continue. Do not stop until green.
- After **5** failed attempts a circuit breaker trips: stop fixing and summarize what's still broken.

Work in the `acceptEdits` tier (Shift+Tab) so edits and the allowlist run without prompts.

Task: $ARGUMENTS
````

- [ ] **Step 2: Validate frontmatter parses**

Run: `head -6 plugins/harness/commands/loop-build.md`
Expected: shows the YAML frontmatter block with `description`, `argument-hint`, `allowed-tools`.

- [ ] **Step 3: Commit**

```bash
git add plugins/harness/commands/loop-build.md
git commit -m "feat(harness): add /loop-build command to arm the loop"
```

---

### Task 5: Canonical permission policy + `/harness-init` command

**Files:**
- Create: `docs/reference/permission-policy.md` (single source of truth for the floor/allow/ask block)
- Create: `plugins/harness/commands/harness-init.md`

**Interfaces:**
- Consumes: the policy reference doc.
- Produces: a command that, in any project, writes/merges the permission block into `.claude/settings.json`, creates `.cc-verify`, and git-ignores the loop state files — all via Edit/Write with the user seeing each change.

- [ ] **Step 1: Write `docs/reference/permission-policy.md`**

````markdown
# Harness Permission Policy (canonical)

A plugin cannot grant permissions — these go in `settings.json`. Precedence: `deny` > `ask` > `allow`.

## Universal floor — `~/.claude/settings.json` → `permissions.deny`
Applies in every tier, including `bypassPermissions`.

```json
"deny": [
  "Bash(sudo *)",
  "Bash(rm -rf /*)",
  "Bash(rm -rf ~/*)",
  "Write(.git/**)",
  "Write(.env)",
  "Write(.env.*)"
]
```

## Hard gates — `permissions.ask` (always prompt, even in build/bypass)

```json
"ask": [
  "Bash(railway up*)",
  "Bash(vercel*--prod*)",
  "Bash(vercel --prod*)",
  "Read(.env)",
  "Read(.env.*)",
  "Bash(railway variables set*)"
]
```
External-send MCP tools (email/comment posting) are gated by omission from `allow`: in the `ship`/`default` tier they prompt naturally.

## Generous allow — project `.claude/settings.json` → `permissions.allow`

```json
"allow": [
  "Bash(npm run *)", "Bash(npm install*)", "Bash(npm test*)",
  "Bash(git add *)", "Bash(git commit *)", "Bash(git status*)",
  "Bash(git diff*)", "Bash(git log*)", "Bash(git push *)",
  "Bash(railway status*)", "Bash(railway logs*)", "Bash(railway variables)",
  "Bash(vercel ls*)", "Bash(vercel inspect*)",
  "Read(*)", "Grep(*)", "Glob(*)"
]
```
````

- [ ] **Step 2: Write `plugins/harness/commands/harness-init.md`**

````markdown
---
description: Set up the harness in this project — permission policy, verify gate, gitignore
allowed-tools: Read, Edit, Write, Bash(cat:*), Bash(ls:*)
---

Set up the harness in the current project. Make each change visible and ask before overwriting existing values.

1. **Verify gate** — if `.cc-verify` does not exist, create it containing the project's green-gate command. Default for a Node/npm repo:
   ```
   npm run lint && npm run build && npm test
   ```
   If the project is not Node, infer the correct command (e.g. `pytest`, `cargo test`) and confirm with the user.

2. **Git-ignore loop state** — ensure `.gitignore` contains these lines (append if missing):
   ```
   .cc-loop-active
   .cc-loop-state
   .cc-verify
   .cc-loop.log
   ```

3. **Project allow list** — merge the `permissions.allow` block from the harness permission policy into this project's `.claude/settings.json` (create the file if absent). Do NOT duplicate entries already present. The canonical block is:
   ```json
   "allow": [
     "Bash(npm run *)", "Bash(npm install*)", "Bash(npm test*)",
     "Bash(git add *)", "Bash(git commit *)", "Bash(git status*)",
     "Bash(git diff*)", "Bash(git log*)", "Bash(git push *)",
     "Read(*)", "Grep(*)", "Glob(*)"
   ]
   ```
   Add project-specific deploy-tool reads (e.g. `Bash(railway status*)`) only if that tooling is present.

4. **Remind the user** that the universal floor (`deny`) and hard gates (`ask`) belong in `~/.claude/settings.json` (global), not the project — point them to `docs/reference/permission-policy.md` in the xari-plugins repo, and note that this command intentionally does not edit global settings.

Report a summary of exactly which files you changed.
````

- [ ] **Step 3: Validate JSON snippets in the docs parse**

Run: `awk '/```json/{f=1;next}/```/{f=0}f' docs/reference/permission-policy.md | jq -e -s 'length>0' >/dev/null && echo "json blocks OK"`
Expected: prints `json blocks OK` (each fenced json block is individually valid; if this errors, the blocks are fragments — that's expected since they are object *fragments*, so instead just eyeball them).
> Note: the blocks are object *fragments* (`"allow": [...]`), not whole objects, so `jq` on the raw fragment will fail. Manual read is the real check here; this step is a reminder to eyeball them.

- [ ] **Step 4: Commit**

```bash
git add docs/reference/permission-policy.md plugins/harness/commands/harness-init.md
git commit -m "feat(harness): add permission-policy reference and /harness-init command"
```

---

### Task 6: README

**Files:**
- Create: `plugins/harness/README.md`

**Interfaces:**
- Consumes: everything above.
- Produces: install + usage docs, the tier table, and an explicit "you must add the permission policy" section.

- [ ] **Step 1: Write `plugins/harness/README.md`**

```markdown
# harness

Tiered autonomy + a build-test-fix loop, so development becomes "kick off a workflow and walk away."

## Tiers (switch with Shift+Tab)

| Tier | Permission mode | Behavior |
|------|-----------------|----------|
| explore | `plan` | read/search only |
| build | `acceptEdits` | auto-accept edits + auto-run your allow list |
| ship | `default` | interactive; only hard gates prompt |
| escape | `bypassPermissions` | full auto (floor `deny` still applies) |

## The loop

`/loop-build <task>` arms a `Stop` hook that runs your verify gate
(`.cc-verify`, default `npm run lint && npm run build && npm test`) and won't let
Claude stop until it's green — fixing and retrying up to 5 times, then summarizing.
Read-only tools are auto-approved in every tier so exploration never stalls.

## Setup

1. Enable the plugin (it's in the `xari-plugins` marketplace).
2. Run `/harness-init` in each project to create `.cc-verify`, git-ignore loop
   state, and seed the project allow list.
3. Add the **permission policy** to your settings — a plugin cannot grant
   permissions. See `docs/reference/permission-policy.md`: the floor (`deny`) and
   hard gates (`ask`) go in `~/.claude/settings.json`.

## State files (git-ignored)

`.cc-loop-active` sentinel · `.cc-loop-state` counter · `.cc-verify` gate override · `.cc-loop.log` last gate output.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/harness/README.md
git commit -m "docs(harness): add plugin README"
```

---

### Task 7: Fix global `~/.claude/settings.json` (floor + allow + ask)

> Machine-local change, NOT committed to the repo. This removes the dead `allowedCommands` no-op and installs the real policy floor + hard gates.

**Files:**
- Modify: `~/.claude/settings.json`

- [ ] **Step 1: Back up current settings**

Run: `cp ~/.claude/settings.json ~/.claude/settings.json.bak && echo backed up`
Expected: `backed up`.

- [ ] **Step 2: Remove the dead `allowedCommands` key and add `permissions`**

Replace the top-level `"allowedCommands": [...]` array with a `permissions` block. Final file should keep all existing keys (`model`, `enabledPlugins`, `extraKnownMarketplaces`, `tui`) and add:

```json
"permissions": {
  "deny": [
    "Bash(sudo *)",
    "Bash(rm -rf /*)",
    "Bash(rm -rf ~/*)",
    "Write(.git/**)",
    "Write(.env)",
    "Write(.env.*)"
  ],
  "ask": [
    "Bash(railway up*)",
    "Bash(vercel*--prod*)",
    "Bash(vercel --prod*)",
    "Read(.env)",
    "Read(.env.*)",
    "Bash(railway variables set*)"
  ],
  "allow": [
    "Read(*)", "Grep(*)", "Glob(*)",
    "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)"
  ]
}
```

- [ ] **Step 3: Validate**

Run: `jq . ~/.claude/settings.json >/dev/null && jq -e '.allowedCommands == null' ~/.claude/settings.json && echo "valid, allowedCommands removed"`
Expected: `true` then `valid, allowedCommands removed`.

- [ ] **Step 4: Verify in a live session**

Manual: launch `claude`, run `/permissions`, confirm the deny/ask/allow rules appear. Confirm `railway up` triggers a prompt even with `npm run *` allowed (deny>ask>allow precedence).

---

### Task 8: Seed crema-connect + end-to-end loop test

**Files:**
- Modify: `/Users/silviaxari/ventures/code/crema-connect/.claude/settings.json`
- Create: `/Users/silviaxari/ventures/code/crema-connect/.cc-verify`
- Modify: `/Users/silviaxari/ventures/code/crema-connect/.gitignore`

- [ ] **Step 1: Run `/harness-init` in crema-connect**

Manual: in a crema-connect session run `/harness-init`. Confirm it creates `.cc-verify` (= `npm run lint && npm run build && npm test`), git-ignores the state files, and merges the allow list into committed `.claude/settings.json`.

- [ ] **Step 2: End-to-end loop test (deliberate failure)**

Manual in crema-connect: introduce a trivial failing test, run `/loop-build "make the suite pass"`, and confirm the loop iterates (block → fix → retry). Then confirm that with an unfixable failure it trips the breaker at 5 and summarizes.

- [ ] **Step 3: Confirm green path**

Manual: fix the failure, confirm the loop reaches green, removes `.cc-loop-active`/`.cc-loop-state`, and allows stop.

- [ ] **Step 4: Commit crema-connect changes**

```bash
cd /Users/silviaxari/ventures/code/crema-connect
git add .claude/settings.json .gitignore
git commit -m "chore: adopt harness — seed permission allow list and verify gate"
```

---

## Self-Review

**Spec coverage:**
- Policy floor → Task 5 (policy doc) + Task 7 (global apply). ✅
- Hard gates (`ask`) → Task 5 + Task 7. ✅
- Generous allow → Task 5 + Task 8. ✅
- Tiers via permission modes → documented (Task 6 README); no code needed (native). ✅
- Auto-approve reads (PreToolUse) → Task 2. ✅
- Build-test-fix loop (Stop hook) + breaker + sentinel opt-in → Task 3. ✅
- `/loop-build` → Task 4. ✅
- `/harness-init` bridge → Task 5. ✅
- Plugin structure + marketplace entry → Task 1. ✅
- Testing strategy (decision tables, e2e) → Tasks 2, 3, 8. ✅

**Placeholder scan:** No TBD/TODO; every code/step block is concrete. The one "eyeball" step (Task 5 Step 3) is explicitly explained, not a hidden gap.

**Type/name consistency:** `.cc-loop-active`, `.cc-loop-state`, `.cc-verify`, `.cc-loop.log`, `MAX=5`, `CC_GATE_CMD`, `CLAUDE_PROJECT_DIR`, and the `{"decision":"block"|allow}` / `permissionDecision:"allow"` shapes are used identically across hook scripts, tests, command, and README.

**Note carried into execution:** the global-settings task (7) and crema-connect tasks (8) are partly manual/live-session checks — they can't be unit-tested in the repo. They're sequenced last so the plugin is proven first.
