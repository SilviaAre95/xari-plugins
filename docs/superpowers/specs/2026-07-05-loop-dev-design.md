---
type: spec
status: draft
created: 2026-07-05
topic: loop-dev
implementation_target: xari-plugins/plugins/harness
part_of: xari-work-loop-system (2 of 3)
---

# Spec 2 — `/loop-dev` (staged verification loop, dev side)

## Context

`harness` already ships `/loop-build`: a Stop hook that runs one deterministic gate (`.cc-verify` = `lint && build && test`) and won't let the agent stop until green, retrying up to 5×. `/loop-dev` **generalizes that single gate into a staged verification loop** — the "quality" layer (LangChain L2) — implementing Silvia's dev sequence:

> review specs → plan → code/fix → review code → security review → find bugs → fix → repeat until push-ready.

It lives in `harness` (reusable across all repos), builds on `/loop-build`'s hook + tier machinery, and grades against the feature bank (Spec 1).

## Goals

1. A `/loop-dev <task>` command that runs the full staged gate and loops until every grader is green, then opens a PR.
2. Reuse harness primitives: tiers, `.cc-verify`, the Stop-hook loop, read-only auto-approve.
3. Graders map to existing xari-plugins skills/agents — no new review logic invented.
4. Human oversight at the sensitive gate: **PR/push is a hard Approve/Deny** (ties to Ristretto's approval-loop).

## Non-goals

- NOT replacing `/loop-build` — it remains the lightweight "just get tests green" loop. `/loop-dev` is the heavier full-quality loop.
- NOT deploying anything — that's `/loop-deploy` (Spec 3).
- NOT auto-merging. The loop opens a PR and stops; merge is a human decision.
- NOT inventing graders — reuse `code-review`, `security:code-audit`, `qa:bug-review`.

## Architecture

Staged verification loop. **Deterministic checks first, LLM graders second** (cheap gates fail fast before spending tokens):

```
/loop-dev <task>
  │
  ├─ PREFLIGHT   feature-bank preflight (Spec 1): affected features,
  │              acceptance_criteria, non_goals    ── mismatch → escape hatch → STOP
  ├─ PLAN        implementation plan (writing-plans)
  ├─ BUILD       code/fix in harness `build` tier (auto-edit + allowlist)
  │
  ├─ VERIFY GATE (Stop hook — runs on every stop attempt, in order):
  │     1. deterministic:  .cc-verify  (lint && build && test)     [fast, cheap]
  │     2. code review:     code-review / code-reviewer agent
  │     3. security review: security:code-audit (+ vuln-scanner)
  │     4. bug hunt:        qa:bug-review (+ edge-case-finder)
  │
  │     any stage fails → write findings to .cc-loop-dev.findings →
  │        agent fixes using findings as feedback → re-run gate from stage 1
  │        (retry cap; then ESCALATE)
  │
  └─ all stages green = push-ready → open PR  ── HARD GATE: Approve/Deny
```

## Config & state

Extends harness conventions:

- **`.cc-verify`** (existing, committed) — the deterministic stage-1 command.
- **`.cc-dev.yaml`** (NEW, committed) — which graders run + order + retry cap:
  ```yaml
  graders: [code-review, security, bugs]   # stage 2-4, in order; omit to skip
  max_retries: 3                           # per full-gate cycle before escalation
  open_pr: true                            # false = stop at green, no PR
  ```
- **State (git-ignored):** `.cc-loop-dev.active` sentinel · `.cc-loop-dev.state` (stage + retry counters) · `.cc-loop-dev.findings` (current feedback) · `.cc-loop-dev.log`.

Flags: `/loop-dev <task> [--skip-security] [--skip-review] [--skip-bugs] [--max-retries N] [--no-pr]`.

## Data flow (the feedback loop)

Each grader emits structured findings → appended to `.cc-loop-dev.findings` → the fix step reads it as its task ("resolve these findings") → gate re-runs from stage 1. A grader passes when it emits zero blocking findings. This is LangChain's "failed output returns to the model with grader explanations."

## Error handling / escalation

- **Retry cap** (`max_retries`, default 3): if the same stage still fails after N full cycles → STOP, summarize the unresolved findings, hand to human. In Ristretto context the summary posts to Slack via the approval loop.
- **Preflight mismatch / non_goal hit** → escape hatch (diff-first), never code around the spec.
- **Non-convergence guard**: if two consecutive cycles produce identical findings (no progress) → escalate early (don't burn the full retry budget).

## Testing

- Unit (shell, like existing harness tests): gate advances stage-by-stage; a failing stage blocks stop; retry counter increments; cap triggers escalation; identical-findings guard triggers early escalation.
- Integration: run `/loop-dev` on a seeded repo with a known lint error, a known insecure snippet, and a known bug; assert each grader catches its issue and the loop only opens the PR once all are clean.

## Acceptance criteria

- [ ] `/loop-dev <task>` runs preflight → plan → build → 4-stage gate → PR.
- [ ] Deterministic stage runs before LLM graders; a fast failure skips the expensive ones that cycle.
- [ ] Findings from each grader feed back into the fix step.
- [ ] Retry cap + no-progress guard both escalate to a human summary.
- [ ] PR opening is a hard Approve/Deny gate.
- [ ] `.cc-dev.yaml` toggles/reorders graders; flags override per-run.

## Related
- [[2026-07-05-ristretto-feature-bank-design]] · [[2026-07-05-loop-deploy-design]]
- harness: `plugins/harness/commands/loop-build.md`
