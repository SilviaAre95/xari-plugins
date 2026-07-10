# loop-deploy gate — end-to-end smoke scenario

The `loop-deploy-gate.sh` Stop hook drives the prod-verify loop: once armed
(`.cc-deploy-active` present), it runs a deterministic `verify` command. Green
closes the loop; a failure under `max_redeploys` blocks with "fix and
redeploy"; a failure that hits the cap runs `rollback`, disarms, and blocks
with "escalate". `loop-deploy-gate.test.sh` exercises this with a fresh
scratch dir per case via `CC_DEPLOY_VERIFY_CMD` / `CC_DEPLOY_ROLLBACK_CMD`
env overrides (no `.cc-deploy.yaml` needed). This doc is the manual,
reproducible complement: one scratch dir walked through all three
transitions an agent would encounter in practice, by hand.

## Setup

```bash
GATE=/path/to/wayworks/plugins/harness/hooks/scripts/loop-deploy-gate.sh
d=$(mktemp -d)

# arm the loop (what /loop-deploy does after a prod deploy)
touch "$d/.cc-deploy-active"
```

No `.cc-deploy.yaml` is created, so `max_redeploys` defaults to 3 and
`verify`/`rollback` come entirely from the env overrides below (mirrors
`loop-deploy-gate.test.sh` cases 2–4).

## Transition 1: armed, verify fails, under cap

```bash
printf '{"cwd":"%s"}' "$d" | CC_DEPLOY_VERIFY_CMD="false" bash "$GATE"
```

Expected output (mirrors `loop-deploy-gate.test.sh` case 3 — `verify-fail
blocks` / `verify-fail feedback` / `verify-fail counts` / `verify-fail keeps
sentinel`):

```json
{
  "decision": "block",
  "reason": "Prod verification failed (attempt 1/3). Fix the issue (you may run /loop-dev) and redeploy; do not stop until prod verifies healthy.\n"
}
```

- `decision` is `"block"`.
- `reason` contains `attempt 1/3` and tells the agent to fix and redeploy.
- `$d/.cc-deploy-state` now contains `1`.
- `$d/.cc-deploy-active` (the sentinel) still exists — the loop stays armed.

## Transition 2: verify passes — loop closed

```bash
printf '{"cwd":"%s"}' "$d" | CC_DEPLOY_VERIFY_CMD="true" bash "$GATE"
```

Expected output (mirrors `loop-deploy-gate.test.sh` case 2 — `verify-pass
allows` / `verify-pass disarms`):

```
(empty — no stdout)
```

- stdout is empty, so Stop is allowed.
- `$d/.cc-deploy-active`, `$d/.cc-deploy-state`, and `$d/.cc-deploy.log` are
  all removed (state cleaned; the loop is closed).

## Transition 3: a new deploy round fails at the cap — rollback + escalate

A fresh prod deploy re-arms the loop. Seed the state file at `max - 1` (2,
since the default cap is 3) so the next failure hits the cap, and provide a
rollback command:

```bash
touch "$d/.cc-deploy-active"
echo 2 > "$d/.cc-deploy-state"
printf '{"cwd":"%s"}' "$d" | CC_DEPLOY_VERIFY_CMD="false" CC_DEPLOY_ROLLBACK_CMD="touch $d/ROLLED_BACK" bash "$GATE"
```

Expected output (mirrors `loop-deploy-gate.test.sh` case 4 — `cap triggers
escalate` / `rollback command ran` / `cap disarms`):

```json
{
  "decision": "block",
  "reason": "Prod still failing after 3 redeploys. rolled back via: touch <d>/ROLLED_BACK. STOP redeploying — escalate to the user with what broke and what you tried:\n"
}
```

- `decision` is `"block"`.
- `reason` contains `escalate` and confirms the rollback command that ran.
- `$d/ROLLED_BACK` now exists — proof the rollback command actually ran.
- `$d/.cc-deploy-active` and `$d/.cc-deploy-state` are both removed (disarmed).

## Cleanup

```bash
rm -rf "$d"
```

---

## Verified run

Actually executed on 2026-07-08 against
`plugins/harness/hooks/scripts/loop-deploy-gate.sh` in a fresh `mktemp -d`
scratch dir (`/var/folders/45/gb12w3g91qj49tw9k5qfps4c0000gn/T/tmp.m9YxWigOUj`),
following the exact steps above, one continuous walkthrough.

**Setup:**

```
$ ls -la "$d"
total 0
drwx------    3 ... .
drwx------@ 432 ... ..
-rw-r--r--    1 ...   0 .cc-deploy-active
```

**Transition 1 (verify fails, under cap) — actual stdout:**

```json
{
  "decision": "block",
  "reason": "Prod verification failed (attempt 1/3). Fix the issue (you may run /loop-dev) and redeploy; do not stop until prod verifies healthy.\n"
}
```

Exit code: `0`. `.cc-deploy-state` contents after: `1`. Sentinel
`.cc-deploy-active` still present. Matches the documented expectation
exactly.

**Transition 2 (verify passes) — actual stdout:**

```
(empty)
```

Exit code: `0`. After this run:

```
$ ls -la "$d"
total 0
drwx------    2 ... .
drwx------@ 432 ... ..
```

`.cc-deploy-active` and `.cc-deploy-state` are both gone — state fully
cleaned, loop closed. Matches the documented expectation exactly.

**Re-arm for a new deploy round:**

```
$ ls -la "$d"
total 8
drwx------    4 ... .
drwx------@ 432 ... ..
-rw-r--r--    1 ...   0 .cc-deploy-active
-rw-r--r--    1 ...   2 .cc-deploy-state
```

**Transition 3 (verify fails at cap) — actual stdout:**

```json
{
  "decision": "block",
  "reason": "Prod still failing after 3 redeploys. rolled back via: touch /var/folders/45/gb12w3g91qj49tw9k5qfps4c0000gn/T/tmp.m9YxWigOUj/ROLLED_BACK. STOP redeploying — escalate to the user with what broke and what you tried:\n"
}
```

Exit code: `0`. After this run:

```
$ ls -la "$d"
total 0
drwx------    4 ... .
drwx------@ 432 ... ..
-rw-r--r--    1 ...   0 .cc-deploy.log
-rw-r--r--    1 ...   0 ROLLED_BACK
```

`ROLLED_BACK` is present — direct proof the rollback command
(`touch $d/ROLLED_BACK`) actually ran. `.cc-deploy-active` and
`.cc-deploy-state` are both gone (disarmed). `.cc-deploy.log` remains
(empty, from the last verify+rollback run) — the gate only removes the
sentinel and state on the escalate path, not the log. Matches the
documented expectation exactly.

**Result: all three transitions verified, output byte-for-byte as
documented above (rollback command confirmed to actually execute via the
`ROLLED_BACK` sentinel file).**
