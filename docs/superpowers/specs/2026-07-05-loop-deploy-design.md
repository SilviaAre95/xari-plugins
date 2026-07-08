---
type: spec
status: draft
created: 2026-07-05
topic: loop-deploy
implementation_target: xari-plugins/plugins/harness
part_of: xari-work-loop-system (3 of 3)
---

# Spec 3 — `/loop-deploy` (verification loop, production side)

## Context

`/loop-dev` (Spec 2) verifies code against *local* rubrics and stops at an open PR. `/loop-deploy` closes the outer loop against **production signals** — LangChain L2 verification where the rubric is "prod is actually healthy." It implements Silvia's deploy sequence:

> deploy → watch deploying → verify prod → find issues → fix immediately → deploy again → watch → repeat until the loop is closed.

Lives in `harness`, reuses the Stop-hook + config conventions, and is deploy-provider-agnostic (Vercel, Railway, GitHub Pages, Supabase — different repos use different targets).

## Goals

1. A `/loop-deploy` command that deploys, watches, verifies prod, and — if prod is unhealthy — fixes and redeploys until healthy or escalation.
2. Provider-agnostic via a per-repo config (like `.cc-verify`).
3. Sensitive-op oversight: **deploying to prod is a hard Approve/Deny**; DB migrations are called out as an extra explicit gate.
4. **Rollback** as the safety net when redeploys don't converge.

## Non-goals

- NOT building CI/CD from scratch — it drives the repo's existing deploy command (Vercel/Railway/etc.).
- NOT the code-quality loop — that's `/loop-dev`. `/loop-deploy` may *call* `/loop-dev` to fix a prod issue, but its own rubric is prod health.
- NOT auto-approving prod deploys or destructive migrations.

## Architecture

```
/loop-deploy [--env prod]
  │
  ├─ HARD GATE:   Approve deploy to prod?  (Approve/Deny; migrations = separate explicit gate)
  ├─ DEPLOY       run `.cc-deploy.yaml: deploy`
  ├─ WATCH        poll `.cc-deploy.yaml: watch` until complete | failed | timeout
  │
  ├─ VERIFY PROD (graders, deterministic):
  │     health   — GET health URL, expect 200
  │     smoke    — prod smoke tests
  │     errors   — error-rate / log grader under threshold (post-deploy window)
  │
  │     unhealthy → findings → fix immediately (may invoke /loop-dev) → REDEPLOY
  │        (cap: max_redeploys; then ROLLBACK + escalate)
  │
  └─ prod healthy = loop closed → report (what shipped, verify results)
```

## Config & state

- **`.cc-deploy.yaml`** (NEW, committed):
  ```yaml
  deploy: "vercel deploy --prod"          # provider deploy command
  watch:  "vercel inspect --wait"         # blocks until deploy resolves
  verify:
    health: "https://app.example.com/health"   # expect 200
    smoke:  "npm run smoke:prod"                # optional
    errors: "npm run check:error-rate"          # exit non-zero if over threshold
  migrations_gate: true                    # DB migration = extra explicit Approve
  max_redeploys: 3
  rollback: "vercel rollback"              # run on give-up
  ```
- **State (git-ignored):** `.cc-deploy.active` · `.cc-deploy.state` (attempt counter) · `.cc-deploy.findings` · `.cc-deploy.log`.

Flags: `/loop-deploy [--env prod|staging] [--max-redeploys N] [--no-rollback]`.

## Data flow

Verify graders emit findings → `.cc-deploy.findings` → fix step (inline or delegated to `/loop-dev`) → redeploy → re-verify. A clean pass on all three verify graders = loop closed. Deploy/watch failure is treated as a verify failure (feeds the same fix→redeploy path).

## Error handling / escalation

- **Watch timeout** → treat as failed deploy → fix/redeploy path.
- **max_redeploys exceeded** → run `rollback`, restore last-good, STOP, page human with the full findings trail. Prod is never left broken by an exhausted loop.
- **No-progress guard** → identical verify findings twice → rollback + escalate early.
- **Migration detected** with `migrations_gate: true` → extra Approve/Deny before deploy proceeds (LangChain: humans in the loop for destructive/data ops).

## Testing

- Unit (shell): deploy success→verify pass = closed; verify fail → redeploy increments; cap → rollback+escalate; watch timeout path; migration gate blocks without approval.
- Integration: mock a provider whose 1st deploy fails health, 2nd passes → assert one redeploy then closed; a provider that never passes → assert rollback + escalation after cap.

## Acceptance criteria

- [ ] `/loop-deploy` deploys, watches to completion, and verifies prod (health + smoke + errors).
- [ ] Unhealthy prod triggers fix → redeploy until healthy or cap.
- [ ] Prod deploy is a hard Approve/Deny; migrations get a second explicit gate.
- [ ] Hitting the redeploy cap rolls back and escalates — never leaves prod broken.
- [ ] Provider-agnostic via `.cc-deploy.yaml`.

## Related
- [[2026-07-05-ristretto-feature-bank-design]] · [[2026-07-05-loop-dev-design]]
