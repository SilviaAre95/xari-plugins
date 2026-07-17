# Pipeline Gaps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the gaps between Silvia's 10-step way-of-working and what the wayworks loops actually execute (2026-07-17 inspection), against marketplace 4.0.0.

**Architecture:** All changes are prose/spec edits to command and skill markdown plus one new skill; no hook-script changes, so the existing harness test suite is the deterministic gate. Release rule applies: plugin + marketplace version bumps, CHANGELOG, README counts in the same PR.

**Tech Stack:** Claude Code plugin markdown (house skill pattern), jq for manifest edits, bash test suite via `.cc-verify`.

## Global Constraints

- Release rule (CLAUDE.md): any `plugins/` change ships with plugin.json + marketplace.json version bumps (in sync), `metadata.version` bump, CHANGELOG entry, README counts.
- Skills: house pattern frontmatter (`name`, quoted `description`, `user-invocable`, `argument-hint`), `Steps → Output Format → Constraints`, ~300–450 words, `$ARGUMENTS` only.
- web-tester is REMOVED at HEAD (marketplace 4.0.0) — browser verification references point at built-in browser tooling / `chrome-devtools-mcp`, never `/web-verify`.
- Never commit loop-state files; `.cc-verify` must be green before PR.

---

### Task 1: loop-dev — plan input, design grader, dev-test stage, postflight, CI watch

**Files:**
- Modify: `plugins/harness/commands/loop-dev.md`
- Modify: `plugins/harness/templates/.cc-dev.yaml`

**Interfaces:**
- Produces: stage list `1 Preflight, 2 Plan, 3 Build, 4 Review, 5 Dev test, 6 Finish, 7 PR`; grader name `design` → `design:layout-review` (+ `design:heuristic-eval` for new flows); generic rule: unknown grader name maps to same-named skill else STOP; `--plan <path>` argument; feature-spec `test_plan` field consumed in stage 5 (defined in Task 2).

- [ ] Step 1: argument-hint → `<task description> [--plan <path>] [--check-plan]`.
- [ ] Step 2: Plan stage: with `--plan <path>`, read that plan file (e.g. a superpowers plan) and adopt it as the implementation plan — follow its tasks in order; otherwise write a short plan. `--check-plan` behavior unchanged.
- [ ] Step 3: grader list gains `design` mapping + extensibility rule (unknown grader → same-named skill, else stop and ask; never silently skip a configured grader).
- [ ] Step 4: insert new stage **5. Dev test (project-shaped)**: order of precedence (a) affected specs' `test_plan`, (b) stack inference — web → drive the changed flow with built-in browser tooling or `chrome-devtools-mcp`, console+network clean; API → hit affected endpoints on the dev server; data pipeline → `data-engineer:pipeline-verify` on a sample slice. Record what ran → PR body "How verified". If the flow can't run in dev, state that in the PR body, never skip silently.
- [ ] Step 5: Finish stage: run feature-bank postflight (Gate 3: `last_modified`, spec CHANGELOG entry, criteria re-verified) BEFORE stamping the marker.
- [ ] Step 6: PR stage: after create/reuse, `gh pr checks <branch> --watch --fail-fast`; red checks are loop work (fix → push → re-watch); Slack ping only after green (or no checks configured).
- [ ] Step 7: template `.cc-dev.yaml`: commented `# max_review_rounds: 3` and `design` grader example.
- [ ] Step 8: `bash .cc-verify` green; commit `feat(harness): loop-dev plan input, design grader, dev-test stage, postflight + CI watch`.

### Task 2: feature-bank — `test_plan` spec field

**Files:**
- Modify: `plugins/feature-bank/skills/feature-bank/references/spec-format.md`
- Modify: `plugins/feature-bank/skills/feature-bank/SKILL.md`

**Interfaces:**
- Produces: optional frontmatter `test_plan:` (list of concrete, agent-executable dev checks) consumed by loop-dev stage 5.

- [ ] Step 1: spec-format frontmatter block gains `test_plan:` (optional) + prose: checks an agent can execute (flow to drive, command over sample data, endpoint to hit) — not "run unit tests" (verify gate owns those).
- [ ] Step 2: SKILL.md scaffolding: propose a `test_plan` alongside acceptance criteria; postflight step 3: run the spec's `test_plan` when present. Keep the ≤800-word target.
- [ ] Step 3: commit `feat(feature-bank): optional test_plan field consumed by loop-dev dev-test stage`.

### Task 3: data-engineer — new `pipeline-verify` skill

**Files:**
- Create: `plugins/data-engineer/skills/pipeline-verify/SKILL.md`

- [ ] Step 1: house-pattern skill: run the pipeline against a bounded sample; assert schema conformance, row counts in vs out, null/dup rates, idempotency (second run = no change), DLQ empty or explained, logs clean; output a verification report table. Constraints: never against prod; bounded input; treat silent row loss as failure.
- [ ] Step 2: commit `feat(data-engineer): pipeline-verify skill — dev verification for data pipelines`.

### Task 4: security — stale model reference

**Files:**
- Modify: `plugins/security/skills/security-scan/SKILL.md`

- [ ] Step 1: heading `### Opus 4.6 Deep Analysis` → `### Deep analysis (\`--opus\` flag)`; body keeps the external tool's flag, drops the model-version claim.
- [ ] Step 2: commit `fix(security): drop stale model-version claim from security-scan`.

### Task 5: model policy reference doc

**Files:**
- Create: `docs/reference/model-policy.md`

- [ ] Step 1: document the tiers loop-dev already encodes (mid-tier for code-review/bugs, session model for security), `model:` frontmatter pinning for skills/agents (agents pin `sonnet` today), and the local-model path: Claude Code can't route stages to local LLMs natively — per-session proxy (`ANTHROPIC_BASE_URL`, LiteLLM-style) is the supported route; link the open local-model track. Docs-only, no bump.
- [ ] Step 2: commit `docs: model policy reference (grader tiers, frontmatter pins, local-model path)`.

### Task 6: README — superpowers handoff + drift + counts

**Files:**
- Modify: `README.md`

- [ ] Step 1: Daily section: front-half line — superpowers brainstorming → spec → writing-plans (or `pm`/`architect` skills), hand off via `/loop-dev --plan docs/superpowers/plans/<plan>.md`.
- [ ] Step 2: settings template gains `"superpowers@claude-plugins-official": true` (matches `/wayworks-init`).
- [ ] Step 3: loop-dev bullet → "spec preflight → plan → build → parallel reviews → dev test → docs postflight → PR + CI watch"; loop-deploy bullet → "+ knowledge sync (repo docs, vault log, Linear)".
- [ ] Step 4: counts 42→43 skills; data-engineer table + `/pipeline-verify` row; harness table wording.
- [ ] Step 5: commit `docs(readme): superpowers handoff, settings drift, new counts`.

### Task 7: loop-deploy — knowledge sync

**Files:**
- Modify: `plugins/harness/commands/loop-deploy.md`
- Modify: `plugins/harness/README.md`

- [ ] Step 1: Success step: before announcing — (a) repo docs reflect what shipped (postflight done, README/CHANGELOG if user-facing); (b) vault declared in global CLAUDE.md → append dated one-line entry to the project vault note's Log (follow the vault's write rules); (c) Linear issue → Done; then Slack ping.
- [ ] Step 2: harness README: one-line updates for the loop-dev/loop-deploy additions.
- [ ] Step 3: commit `feat(harness): loop-deploy knowledge sync (repo docs, vault log, Linear)`.

### Task 8: release rule

**Files:**
- Modify: `plugins/harness/.claude-plugin/plugin.json` (1.4.1 → 1.5.0), `plugins/feature-bank/.claude-plugin/plugin.json` (1.1.0 → 1.2.0), `plugins/data-engineer/.claude-plugin/plugin.json` (1.0.1 → 1.1.0), `plugins/security/.claude-plugin/plugin.json` (1.0.2 → 1.0.3)
- Modify: `.claude-plugin/marketplace.json` (same four + `metadata.version` 4.0.0 → 4.1.0)
- Modify: `CHANGELOG.md` (`[marketplace 4.1.0] — 2026-07-17`, grouped by plugin)

- [ ] Step 1: bump all six version sites; verify sync with the jq loop from the inspection.
- [ ] Step 2: CHANGELOG entry (Added: pipeline-verify, test_plan, dev-test stage, CI watch, knowledge sync, `--plan`; Fixed: security-scan model ref).
- [ ] Step 3: `bash .cc-verify` green; commit `chore(release): marketplace 4.1.0`; push; `gh pr create`.

## Self-Review

Spec coverage: 10-step mapping gaps 1–5 → Tasks 1/2/3/6/7; model router ask → Task 5 (+ tiers already at HEAD); doc drift → Tasks 4/6; release rule → Task 8. Vault way-of-working note is out-of-repo scope, done after the PR. Type consistency: `test_plan` named identically in Tasks 1/2; stage numbering 1–7 consistent in Task 1.
