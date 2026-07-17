# wayworks

An open-source way of work for AI-assisted building — Claude Code plugins with second-brain (Obsidian) support and tracker (Linear) integration. 14 plugins, 43 skills (5 of them stack profiles), 6 commands, and 5 sub-agents.

- `/wayworks-init` — bootstrap a repo: plugin fleet, CLAUDE.md header, verify gate
- `/wayworks-onboard` — link a project's triangle: repo ↔ second brain ↔ tracker

**Core** (enable everywhere): `shared`, `harness`, `security`, `test-builder`, `feature-bank`. **Extended** (enable per stack): everything else — `/wayworks-init` picks the right set for a repo.

## How it's used

**One-time setup**
1. Install the marketplace and the core plugins (below), or let `/wayworks-init` do it per repo.
2. *Recommended*: point your global `~/.claude/CLAUDE.md` at your Obsidian vault (one line: where it lives and that repo CLAUDE.md files reference notes inside it). The vault is the knowledge layer — project notes, PRDs, decisions — and what `/wayworks-onboard` links against.
3. *Optional*: connect a tracker. Linear (via the claude.ai connector) gets the deepest integration; GitHub Issues or a backlog inside your vault work too — the commands adapt to what you have.

**Per project**
- `/wayworks-onboard <name-or-idea>` — takes inventory (repo? vault note? tracker project?), creates only what's missing, and wires the links between all three. Works from a bare idea (vault note + tracker only) up to a fully existing project (links only).
- `/wayworks-init` — inside a repo: detects the stack, enables the right plugin fleet in committed `.claude/settings.json` (so your whole team gets it on clone), scaffolds the CLAUDE.md config header, and hands off to `/harness-init` for the verify gate.

**Daily**
- Front half of a feature: superpowers `brainstorming` → spec → `writing-plans`, then hand the plan to the loop: `/loop-dev --plan docs/superpowers/plans/<plan>.md`
- `/loop-build` — build-test-fix until the verify gate is green
- `/loop-dev` — full feature loop: spec preflight → plan → build → parallel review/security/bug (+ optional design) subagents → dev test → docs postflight → PR + CI watch
- `/loop-deploy` — deploy → watch → verify prod → fix/redeploy or roll back → sync repo docs, vault log, and Linear
- `feature-bank` guards scope on every code edit; review/test/security skills on demand; browser verification via Claude's built-in browser tooling or `chrome-devtools-mcp`.

**Adapts to your setup**: no vault → knowledge lives in `docs/`; no Linear → pick Obsidian checkboxes, GitHub Issues, or `docs/BACKLOG.md`. Obsidian + Linear is the recommended pairing, not a requirement.

## Install

### From GitHub (marketplace)

```bash
claude plugin marketplace add SilviaAre95/wayworks
```

Then install individual plugins:

```bash
claude plugin install shared@wayworks
claude plugin install architect@wayworks
claude plugin install backend-dev@wayworks
claude plugin install frontend-dev@wayworks
claude plugin install test-builder@wayworks
claude plugin install qa@wayworks
claude plugin install data-engineer@wayworks
claude plugin install devops@wayworks
claude plugin install security@wayworks
claude plugin install design@wayworks
claude plugin install tech-writer@wayworks
claude plugin install pm@wayworks
claude plugin install harness@wayworks
claude plugin install feature-bank@wayworks
```

Or bootstrap a repo with the whole fleet in one step: install `shared`, then run `/wayworks-init` inside the repo.

### Local development

```bash
git clone https://github.com/SilviaAre95/wayworks.git
cd wayworks

# Load a single plugin
claude --plugin-dir ./plugins/architect

# Load multiple plugins
claude --plugin-dir ./plugins/shared --plugin-dir ./plugins/architect --plugin-dir ./plugins/backend-dev
```

## Plugins

### shared

Coding conventions, meta-skills, and stack profiles.

| Skill | Description |
|-------|-------------|
| `/conventions` | Apply wayworks working conventions — simplicity-first, explicit errors, conventional commits (language-agnostic) |
| `/create-skill` | Generate a new SKILL.md with proper frontmatter and structure |
| `/wayworks-init` | Bootstrap a repo as a wayworks workspace — plugin fleet in `.claude/settings.json`, CLAUDE.md header, harness handoff |
| `/wayworks-onboard` | Onboard a project from any starting point — create + link Linear project ↔ vault note ↔ repo, adapting to what exists |

**Stack profiles** (auto-loaded based on project files — this is where language/stack opinions live):
- `nextjs-vercel` — Next.js App Router + TypeScript style + Tailwind/Prisma + Vercel conventions
- `expo-mobile` — Expo Router, secure storage, permissions, EAS build/release
- `python-gcp` — FastAPI/Flask + GCP (Cloud Run, BigQuery, Pub/Sub)
- `terraform` — IaC module structure, state management, provider conventions
- `generic` — Language-agnostic fallback conventions

### architect

System design and architecture decisions. Includes `design-reviewer` and `security-reviewer` sub-agents.

| Skill | Description |
|-------|-------------|
| `/system-design` | Design system architecture — components, data flow, infra |
| `/tradeoff-analysis` | Compare options with structured pros/cons/recommendation |
| `/adr-writer` | Write + manage ADRs — generates records, scaffolds docs/adr/, list/status modes |

### backend-dev

API and database development patterns.

| Skill | Description |
|-------|-------------|
| `/api-design` | Design REST/GraphQL endpoints with schemas and validation |
| `/db-schema` | Design or review Prisma database schemas |
| `/error-handling` | Implement structured error handling patterns |

### frontend-dev

React/Next.js component development and review.

| Skill | Description |
|-------|-------------|
| `/component-builder` | Scaffold React components with types, a11y, and Tailwind |
| `/styling-review` | Review Tailwind usage, design consistency, and patterns |
| `/accessibility-check` | WCAG 2.1 AA code audit + UX experience mode (screen reader, keyboard, low vision, motor, cognitive) |

### test-builder

Test generation across all layers.

| Skill | Description |
|-------|-------------|
| `/unit-tests` | Generate isolated unit tests with edge cases and mocks |
| `/integration-tests` | Generate integration tests with real database |
| `/e2e-tests` | Generate Playwright/Cypress end-to-end tests |

### qa

Quality assurance and regression analysis. Includes `regression-scanner` sub-agent.

| Skill | Description |
|-------|-------------|
| `/edge-case-finder` | Identify edge cases, boundary conditions, and failure modes |
| `/bug-review` | Analyze bug reports, find root causes, verify fixes |
| `/regression-check` | Trace code changes for potential regressions |

### data-engineer

Data pipeline and SQL workflows.

| Skill | Description |
|-------|-------------|
| `/pipeline-design` | Design ETL/ELT pipelines with monitoring and error handling |
| `/schema-review` | Review schemas for normalization, indexes, naming |
| `/sql-optimizer` | Analyze and optimize SQL queries |
| `/pipeline-verify` | Run a pipeline against a bounded sample in dev; assert schema, row accounting, idempotency, clean logs |

### design

Design review — layout, design systems, usability, and user flows (merger of the former ui-designer + ux-researcher plugins).

| Skill | Description |
|-------|-------------|
| `/layout-review` | Visual hierarchy, spacing, alignment + responsive breakpoints and touch targets |
| `/design-system` | Audit, scaffold, or extend a Tailwind design system |
| `/heuristic-eval` | Nielsen's 10 heuristics evaluation with severity ratings |
| `/user-flow-analysis` | Map user flows, identify friction and drop-off risks |

### devops

Infrastructure, containers, and CI/CD. Includes `deploy-checker` sub-agent.

| Skill | Description |
|-------|-------------|
| `/dockerfile` | Generate or review multi-stage Dockerfiles |
| `/ci-pipeline` | Generate CI/CD configs (GitHub Actions, Railway, Vercel) |
| `/infra-review` | Review Docker, CI, deploy, env vars, production readiness |

### security

Code and infrastructure security. Includes `vuln-scanner` sub-agent.

| Skill | Description |
|-------|-------------|
| `/code-audit` | OWASP Top 10 code audit — injection, auth, data exposure |
| `/dependency-check` | Audit dependencies for CVEs, outdated packages, bloat |
| `/iam-review` | Review auth flows, RBAC, sessions, API key management |
| `security-scan` | Supply-chain scan of agent configs (requires external `ecc-agentshield` via npx) |

### tech-writer

Documentation generation.

| Skill | Description |
|-------|-------------|
| `/readme-gen` | Generate README by analyzing project code and config |
| `/api-docs` | Generate API docs from route handlers (markdown or OpenAPI) |

### pm

Product management and planning.

| Skill | Description |
|-------|-------------|
| `/user-stories` | Generate user stories with acceptance criteria |
| `/task-breakdown` | Break features into tasks with estimates and dependencies |
| `/prd-writer` | Generate PRDs with problem, solution, scope, metrics |

### harness

Tiered autonomy + verification loops for hands-off AI workflows. Ships hooks (auto-approve reads, `Stop`-gate loop enforcement), templates, and its own test suite. See [plugins/harness/README.md](plugins/harness/README.md).

| Command | Description |
|---------|-------------|
| `/harness-init` | Set up the harness in a project — verify gate (`.cc-verify`), loop configs, gitignore |
| `/loop-build` | Build-test-fix loop that runs until the verify gate is green |
| `/loop-dev` | Staged dev loop: spec preflight → plan (`--plan <path>`) → build → review subagents → dev test → docs postflight → PR + CI watch |
| `/loop-deploy` | Prod deploy loop: deploy → watch → verify → fix/redeploy until healthy, rollback on exhaustion; knowledge sync on success |

### feature-bank

Source-of-truth feature specs with preflight/postflight gates that stop agent drift.

| Skill | Description |
|-------|-------------|
| `/feature-bank` | Enforce `/docs/features/` specs before any code change; interactive backfill for existing codebases |

## Per-project setup

### Settings template

The easiest path is `/wayworks-init`, which writes this for you. Manually, drop into your project's `.claude/settings.json` (committed, so the whole team gets the same fleet on clone):

```json
{
  "extraKnownMarketplaces": {
    "wayworks": { "source": { "source": "github", "repo": "SilviaAre95/wayworks" } }
  },
  "enabledPlugins": {
    "shared@wayworks": true,
    "harness@wayworks": true,
    "security@wayworks": true,
    "test-builder@wayworks": true,
    "feature-bank@wayworks": true,
    "superpowers@claude-plugins-official": true
  }
}
```

Then add the stack-specific set:

- **Full-stack web app**: + `architect`, `backend-dev`, `frontend-dev`, `design`
- **Backend API service**: + `architect`, `backend-dev`, `data-engineer`, `devops`
- **Data platform**: + `data-engineer`, `devops`
- **Infrastructure / Terraform**: + `devops`
- **Planning & design** (no code): `architect`, `pm`, `tech-writer` only

### Install with scope

```bash
# Project scope (committed, shared with team)
claude plugin install architect@wayworks --scope project

# Local scope (gitignored, personal)
claude plugin install architect@wayworks --scope local
```

## Sub-agents

Some plugins include sub-agents for multi-step workflows:

| Plugin | Agent | Purpose |
|--------|-------|---------|
| architect | `design-reviewer` | Reviews system designs for security, scalability, ops |
| architect | `security-reviewer` | Focused security review of architecture decisions |
| qa | `regression-scanner` | Traces code changes through dependency graph |
| devops | `deploy-checker` | Pre-deployment validation (build, lint, env, migrations) |
| security | `vuln-scanner` | OWASP Top 10 vulnerability scanning |

## Adding new skills

Use the `create-skill` meta-skill:

```
/create-skill my-new-skill architect "Design microservice boundaries"
```

Or see [plugins/shared/skills/create-skill/SKILL.md](plugins/shared/skills/create-skill/SKILL.md) for the full template reference.

## Structure

```
wayworks/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── shared/           # Conventions, meta-skills, stack profiles
│   ├── architect/        # System design, tradeoffs, ADRs
│   ├── backend-dev/      # API, database, error handling
│   ├── frontend-dev/     # Components, styling, a11y
│   ├── test-builder/     # Unit, integration, e2e tests
│   ├── qa/               # Edge cases, bugs, regressions
│   ├── data-engineer/    # Pipelines, schemas, SQL
│   ├── design/           # Layout+responsive, design system, heuristics, user flows
│   ├── devops/           # Docker, CI/CD, infra
│   ├── security/         # Code audit, deps, IAM
│   ├── tech-writer/      # README, API docs, ADR templates
│   ├── pm/               # User stories, tasks, PRDs
│   ├── harness/          # Autonomy tiers, verify loops, hooks, templates, tests
│   └── feature-bank/     # Feature-spec governance + check-bank.sh validator
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/         # (or commands/ for harness + shared)
│       │   └── <skill-name>/
│       │       └── SKILL.md
│       └── agents/         # (plugins with sub-agents)
│           └── <agent-name>.md
├── CHANGELOG.md
├── CLAUDE.md             # Release rule: version bump + CHANGELOG on any plugins/ change
└── README.md
```
