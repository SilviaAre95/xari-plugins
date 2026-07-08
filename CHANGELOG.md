# Changelog

All notable changes to the **xari-plugins** marketplace and its plugins.
Format follows [Keep a Changelog](https://keepachangelog.com/); the marketplace and each plugin follow [Semantic Versioning](https://semver.org/).

## Versioning policy

- **Per plugin** (`plugins/<name>/.claude-plugin/plugin.json` **and** its `marketplace.json` entry — keep them in sync): bump **patch** for fixes/docs, **minor** for new backward-compatible skills/commands/hooks, **major** for breaking changes to a plugin's interface.
- **Marketplace** (`metadata.version`): bump when the set of plugins changes or a plugin ships a notable release — generally the largest bump of that release.
- A **brand-new plugin** enters at `1.0.0`.
- Record every release below, newest first, grouped by plugin.

---

## [marketplace 1.1.0] — 2026-07-08

### Added
- **`feature-bank` plugin `1.0.0`** — source-of-truth feature specs with preflight/postflight gates that stop agent drift; ships a portable `check-bank.sh` validator.
- **`harness` `1.1.0`** — two new commands extending the build-test-fix loop into a full work-loop system:
  - **`/loop-dev`** — staged verification loop: spec preflight → plan (`--check-plan` autonomy dial) → build → code-review / security / bug-hunt subagents → fix → PR. A `Stop` hook enforces the deterministic gate (`.cc-verify`) plus a reviews-passed marker; circuit breaker after `max_retries`. Config in `.cc-dev.yaml`.
  - **`/loop-deploy`** — production verify loop: deploy → watch → verify (health + smoke + error-rate) → fix→redeploy until healthy; after `max_redeploys` it runs `rollback` and escalates, so an exhausted loop never leaves prod broken. Prod deploy + DB migrations are hard Approve/Deny gates. Config in `.cc-deploy.yaml`.
  - `harness-init` now scaffolds `.cc-dev.yaml` / `.cc-deploy.yaml` and git-ignores the new loop state files.

## [harness 1.0.0] — earlier

### Added
- **`harness` plugin** — tiered autonomy (explore / build / ship / escape) + the `/loop-build` build-test-fix loop with a `Stop`-hook verify gate and circuit breaker.
- **`security` `security-scan` skill** — supply-chain scan via `ecc-agentshield`.

## [marketplace 1.0.0] — 2026-04-08

### Added
- Initial release: 13 plugins (`shared`, `architect`, `ui-designer`, `ux-researcher`, `backend-dev`, `frontend-dev`, `data-engineer`, `test-builder`, `qa`, `security`, `devops`, `tech-writer`, `pm`) — 39 skills, 5 sub-agents, 4 stack profiles.
