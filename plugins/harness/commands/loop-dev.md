---
description: Arm the staged dev loop — implement a task through spec/code/review/security/bugs to a PR
argument-hint: <task description> [--check-plan]
allowed-tools: Bash(touch:*), Bash(echo:*), Bash(cat:*), Bash(rm:*)
---

Arm the dev loop for this project:

!`touch .cc-loop-dev-active && echo 0 > .cc-loop-dev-state && rm -f .cc-dev-reviews-passed && echo "loop-dev armed"`

The staged dev loop is **ARMED**. Config lives in `.cc-dev.yaml` (graders, max_retries, base, open_pr) — read it now if present.

Work in the `acceptEdits` tier (Shift+Tab) so edits and the allowlist run without prompts. Then execute these stages for the task below:

1. **Preflight (specs).** If `docs/features/INDEX.md` exists, run the `feature-bank` preflight: identify affected feature(s), confirm the change satisfies their `acceptance_criteria` and violates no `non_goals`. On a spec mismatch, STOP and surface the diff-first escape hatch — do not code around the spec.
2. **Plan.** Write a short implementation plan. If the invocation included `--check-plan`, post the plan and WAIT for the user's approval before building.
3. **Build.** Implement the task.
4. **Review stages.** For each grader in `.cc-dev.yaml` `graders` (default `code-review`, `security`, `bugs`), dispatch a **subagent** to review the diff against `base` (default `main`):
   - `code-review` → correctness/quality review (or the `/code-review` skill).
   - `security` → the `security:code-audit` skill (OWASP, injection, authz, secrets).
   - `bugs` → the `qa:bug-review` skill (edge cases, logic errors).
   Collect blocking findings; fix every one; re-run the affected grader until clean.
5. **Finish.** When the deterministic gate (`.cc-verify`) is green AND all graders are clean AND you have made no further edits, create the marker: `touch .cc-dev-reviews-passed`.
6. **PR** (if `.cc-dev.yaml` `open_pr` is not false). Push the branch and open a PR to `base`. Post to Slack: a one-line "what changed", the **bare** PR URL on its own line, and the Linear issue key. Move the Linear issue to "In Review". Never merge — that is the user's call from their phone.

The `Stop` hook enforces this: you cannot finish until `.cc-verify` is green and `.cc-dev-reviews-passed` exists. If the deterministic gate fails it feeds the errors back; after `max_retries` a circuit breaker trips — then summarize what is still broken.

Task: $ARGUMENTS
