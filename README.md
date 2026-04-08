# xari-plugins

Opinionated Claude Code plugins for full-stack engineering workflows. 13 plugins, 38 skills, 5 sub-agents, and 4 stack profiles.

## Install

### From GitHub (marketplace)

```bash
claude plugin marketplace add SilviaAre95/xari-plugins
```

Then install individual plugins:

```bash
claude plugin install shared@xari-plugins
claude plugin install architect@xari-plugins
claude plugin install backend-dev@xari-plugins
claude plugin install frontend-dev@xari-plugins
claude plugin install test-builder@xari-plugins
claude plugin install qa@xari-plugins
claude plugin install data-engineer@xari-plugins
claude plugin install devops@xari-plugins
claude plugin install security@xari-plugins
claude plugin install ui-designer@xari-plugins
claude plugin install ux-researcher@xari-plugins
claude plugin install tech-writer@xari-plugins
claude plugin install pm@xari-plugins
```

### Local development

```bash
git clone https://github.com/SilviaAre95/xari-plugins.git
cd xari-plugins

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
| `/conventions` | Apply xari coding style — TypeScript-first, minimal abstractions, conventional commits |
| `/create-skill` | Generate a new SKILL.md with proper frontmatter and structure |

**Stack profiles** (auto-loaded based on project files):
- `nextjs-vercel` — Next.js App Router + Vercel deployment conventions
- `python-gcp` — FastAPI/Flask + GCP (Cloud Run, BigQuery, Pub/Sub)
- `terraform` — IaC module structure, state management, provider conventions
- `generic` — Language-agnostic fallback conventions

### architect

System design and architecture decisions. Includes `design-reviewer` and `security-reviewer` sub-agents.

| Skill | Description |
|-------|-------------|
| `/system-design` | Design system architecture — components, data flow, infra |
| `/tradeoff-analysis` | Compare options with structured pros/cons/recommendation |
| `/adr-writer` | Generate Architecture Decision Records |

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
| `/accessibility-check` | WCAG 2.1 AA audit — semantic HTML, ARIA, keyboard, contrast |

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

### ui-designer

Layout, design systems, and responsive behavior.

| Skill | Description |
|-------|-------------|
| `/layout-review` | Review visual hierarchy, spacing, alignment, responsiveness |
| `/design-system` | Audit, scaffold, or extend a Tailwind design system |
| `/responsive-audit` | Audit responsive behavior across breakpoints |

### ux-researcher

Usability evaluation and user experience analysis.

| Skill | Description |
|-------|-------------|
| `/heuristic-eval` | Nielsen's 10 heuristics evaluation with severity ratings |
| `/user-flow-analysis` | Map user flows, identify friction and drop-off risks |
| `/accessibility-audit` | UX-focused a11y audit beyond compliance checklists |

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

### tech-writer

Documentation generation.

| Skill | Description |
|-------|-------------|
| `/readme-gen` | Generate README by analyzing project code and config |
| `/api-docs` | Generate API docs from route handlers (markdown or OpenAPI) |
| `/adr-template` | Set up ADR infrastructure — directory, template, index |

### pm

Product management and planning.

| Skill | Description |
|-------|-------------|
| `/user-stories` | Generate user stories with acceptance criteria |
| `/task-breakdown` | Break features into tasks with estimates and dependencies |
| `/prd-writer` | Generate PRDs with problem, solution, scope, metrics |

## Per-project setup

### Settings templates

Drop one of these into your project's `.claude/settings.json`:

**Full-stack web app** (Next.js):
```json
{
  "plugins": [
    "shared@xari-plugins",
    "architect@xari-plugins",
    "backend-dev@xari-plugins",
    "frontend-dev@xari-plugins",
    "test-builder@xari-plugins",
    "security@xari-plugins"
  ]
}
```

**Backend API service**:
```json
{
  "plugins": [
    "shared@xari-plugins",
    "architect@xari-plugins",
    "backend-dev@xari-plugins",
    "test-builder@xari-plugins",
    "data-engineer@xari-plugins",
    "devops@xari-plugins",
    "security@xari-plugins"
  ]
}
```

**Data platform**:
```json
{
  "plugins": [
    "shared@xari-plugins",
    "data-engineer@xari-plugins",
    "devops@xari-plugins",
    "security@xari-plugins"
  ]
}
```

**Infrastructure / Terraform**:
```json
{
  "plugins": [
    "shared@xari-plugins",
    "devops@xari-plugins",
    "security@xari-plugins"
  ]
}
```

**Planning & design** (no code):
```json
{
  "plugins": [
    "architect@xari-plugins",
    "pm@xari-plugins",
    "tech-writer@xari-plugins"
  ]
}
```

### Install with scope

```bash
# Project scope (committed, shared with team)
claude plugin install architect@xari-plugins --scope project

# Local scope (gitignored, personal)
claude plugin install architect@xari-plugins --scope local
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
xari-plugins/
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
│   ├── ui-designer/      # Layout, design system, responsive
│   ├── ux-researcher/    # Heuristics, user flows, a11y audit
│   ├── devops/           # Docker, CI/CD, infra
│   ├── security/         # Code audit, deps, IAM
│   ├── tech-writer/      # README, API docs, ADR templates
│   └── pm/               # User stories, tasks, PRDs
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/
│       │   └── <skill-name>/
│       │       └── SKILL.md
│       └── agents/         # (plugins with sub-agents)
│           └── <agent-name>.md
└── README.md
```
