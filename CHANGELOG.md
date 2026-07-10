# Changelog

All notable changes to the **xari-plugins** marketplace and its plugins.
Format follows [Keep a Changelog](https://keepachangelog.com/); the marketplace and each plugin follow [Semantic Versioning](https://semver.org/).

## Versioning policy

- **Per plugin** (`plugins/<name>/.claude-plugin/plugin.json` **and** its `marketplace.json` entry — keep them in sync): bump **patch** for fixes/docs, **minor** for new backward-compatible skills/commands/hooks, **major** for breaking changes to a plugin's interface.
- **Marketplace** (`metadata.version`): bump when the set of plugins changes or a plugin ships a notable release — generally the largest bump of that release.
- A **brand-new plugin** enters at `1.0.0`.
- Record every release below, newest first, grouped by plugin.

---

## [marketplace 3.0.0] — 2026-07-10

**The project is now `wayworks`** (was `xari-plugins`) — an open-source way of work for AI-assisted building: plugins + second-brain (Obsidian) support + tracker (Linear) integration.

### Breaking / Migration
- Marketplace renamed: every consumer key changes from `<plugin>@xari-plugins` to `<plugin>@wayworks`, and the marketplace source is now `SilviaAre95/wayworks` (old GitHub URLs redirect). Update `.claude/settings.json`: `extraKnownMarketplaces` entry + all `enabledPlugins` keys.
- **`shared` `2.0.0`** — commands renamed: `/xari-init` → `/wayworks-init`, `/xari-onboard` → `/wayworks-onboard`. The CLAUDE.md header they scaffold is now `## Wayworks config`.

### Changed
- All plugin `repository` URLs, README, and docs updated to the new identity. Historical CHANGELOG entries below intentionally keep the old name.

## [marketplace 2.0.1] — 2026-07-09

### Fixed
- **All skills standardized on `$ARGUMENTS`** — 24 skills across 10 plugins dropped positional `$0`/`$1` interpolation (which only populates for typed slash commands and leaks literally when the model invokes a skill). `shared/create-skill` `1.3.2` now teaches `$ARGUMENTS`-only. Patch bumps: backend-dev/data-engineer/design/devops/pm/qa/test-builder 1.0.1, frontend-dev 1.1.1, security 1.0.2, tech-writer 2.0.1.

## [marketplace 2.0.0] — 2026-07-09

Consolidation release (context-budget lean-up). **Breaking**: two plugins removed.

### Breaking / Migration
- **`ui-designer` and `ux-researcher` removed** — merged into the new **`design` `1.0.0`** plugin. Migrate `.claude/settings.json`: replace `ui-designer@xari-plugins` / `ux-researcher@xari-plugins` with `design@xari-plugins`.
- **`tech-writer` `2.0.0`** — `adr-template` skill removed; its init/list/status modes now live in `architect/adr-writer`.

### Changed
- **`design` `1.0.0`** — 4 skills: `layout-review` (absorbs `responsive-audit`: mobile-first checks, breakpoint matrix, touch targets), `design-system`, `heuristic-eval`, `user-flow-analysis`.
- **`frontend-dev` `1.1.0`** — `accessibility-check` gains an `experience` mode (the former `ux-researcher/accessibility-audit`: screen-reader/keyboard/low-vision/motor/cognitive walkthroughs) alongside WCAG code compliance.
- **`architect` `1.1.0`** — `adr-writer` absorbs ADR infrastructure setup + list/status modes; one ADR skill instead of two.
- **`feature-bank` `1.1.0`** — SKILL.md trimmed 2,309 → 800 words via progressive disclosure; full backfill flow, spec format, and worked examples moved to `references/` (loaded only when needed). Frontmatter unchanged, so triggering is identical.
- **`shared` `1.3.1`** — `/xari-init` fleet list references `design` instead of `ui-designer`.
- README: core vs extended plugin tiers documented. Counts: 15 plugins / 43 skills. Closes XARI-73 (and XARI-54 via the ADR merge).

## [marketplace 1.4.0] — 2026-07-09

### Changed
- **`shared` `1.3.0`** — `conventions` is now language-agnostic (simplicity-first, error handling, commits, review checklist); TypeScript/React/Tailwind/Prisma specifics moved into the `nextjs-vercel` stack profile where they auto-load only in matching repos. New `expo-mobile` stack profile (Expo Router, secure storage, permissions, EAS) — mobile conventions no longer squat in a web profile. Closes XARI-72.

## [marketplace 1.3.1] — 2026-07-09

### Fixed
- **`security` `1.0.1`** — `security-scan` frontmatter normalized to house standard (quoted description, `user-invocable`, `argument-hint`; non-standard `origin` key removed) and its external `ecc-agentshield` dependency surfaced explicitly: not bundled, `npx` downloads on first run, fail-and-report if unavailable, version-pinning advised for CI. Closes XARI-52.

## [marketplace 1.3.0] — 2026-07-09

### Added
- **`shared` `1.2.0`** — new `/xari-onboard` command: onboard a project from any starting point (existing repo, existing vault note, or a bare idea) into the linked triangle **Linear project ↔ vault note ↔ repo**. Takes inventory first, creates only what's missing (knowledge → tracking → code), wires the cross-links idempotently, and degrades gracefully for users without an Obsidian vault or Linear connection.

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
