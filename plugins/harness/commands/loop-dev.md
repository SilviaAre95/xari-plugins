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
4. **Review stages (run in PARALLEL).** Dispatch one subagent per grader in `.cc-dev.yaml` `graders` (default `code-review`, `security`, `bugs`) **all at once — in a single batch of concurrent Task calls, not one after another** — each reviewing the diff against `base` (default `main`):
   - `code-review` → correctness/quality review (or the `/code-review` skill).
   - `security` → the `security:code-audit` skill (OWASP, injection, authz, secrets).
   - `bugs` → the `qa:bug-review` skill (edge cases, logic errors).
   Wait for all of them, then collect every blocking finding across all graders into one list; fix them; re-run only the affected graders (again in parallel) until all are clean. Running the graders concurrently is the point — do not serialize them.
5. **Finish.** When the deterministic gate (`.cc-verify`) is green AND all graders are clean AND you have made no further edits, stamp the marker with the anchor commit and tree fingerprint so late changes invalidate it:
   `mb=$(git merge-base <base> HEAD) && { echo "$mb"; git diff "$mb" | git hash-object --stdin; } > .cc-dev-reviews-passed`
   (outside a git repo: `touch .cc-dev-reviews-passed`). The Stop hook re-fingerprints the tree against the anchor stored in the marker; if anything changed after stamping — committed or not — the marker is rejected and you must re-run the affected graders.
6. **PR** (if `.cc-dev.yaml` `open_pr` is not false). Push the branch. Then check for an existing PR first — re-runs must converge to ONE PR, never two:
   `gh pr list --head <branch> --json url,state --jq '.[] | select(.state=="OPEN") | .url'`
   - If a URL comes back: reuse it. Do NOT run `gh pr create`. Update the PR body if the diff changed materially.
   - Only if empty: open the PR with `gh pr create`.
   Post to Slack: a one-line "what changed", the **bare** PR URL on its own line, and the Linear issue key. On the Linear issue: move it to "In Review" and add the PR-link comment ONLY if no comment with this PR URL already exists — a re-run must not double-post. Never merge — that is the user's call from their phone.

The `Stop` hook enforces this: you cannot finish until `.cc-verify` is green and `.cc-dev-reviews-passed` exists. If the deterministic gate fails it feeds the errors back; after `max_retries` a circuit breaker trips — then summarize what is still broken.

Task: $ARGUMENTS
