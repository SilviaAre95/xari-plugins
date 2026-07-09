# Changelog

All notable changes to the **xari-plugins** marketplace and its plugins.
Format follows [Keep a Changelog](https://keepachangelog.com/); the marketplace and each plugin follow [Semantic Versioning](https://semver.org/).

## Versioning policy

- **Per plugin** (`plugins/<name>/.claude-plugin/plugin.json` **and** its `marketplace.json` entry — keep them in sync): bump **patch** for fixes/docs, **minor** for new backward-compatible skills/commands/hooks, **major** for breaking changes to a plugin's interface.
- **Marketplace** (`metadata.version`): bump when the set of plugins changes or a plugin ships a notable release — generally the largest bump of that release.
- A **brand-new plugin** enters at `1.0.0`.
- Record every release below, newest first, grouped by plugin.

---

## [marketplace 1.2.0] — 2026-07-09

### Added
- **`web-tester` plugin `1.0.0`** — live web-app verification. Declares the marketplace's first MCP server (Playwright, headless via `npx @playwright/mcp`) and ships `/web-verify`: drive the critical user flow in a real browser, assert console + network are clean, screenshot evidence.
- **`shared` `1.1.0`** — new `/xari-init` command: bootstrap any repo as a xari workspace (plugin fleet in `.claude/settings.json` via `extraKnownMarketplaces` + `enabledPlugins`, CLAUDE.md header template with stack/vault-note/Linear/verify pointers, harness handoff).

### Fixed
- **README** backfilled to reality (was 13 plugins/38 skills): now 16 plugins / 45 skills, documents `harness`, `feature-bank`, `web-tester`, and `security-scan`; settings templates corrected from the invalid `"plugins": []` key to the real `enabledPlugins` schema.

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
