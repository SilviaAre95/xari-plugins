# xari-plugins

Opinionated Claude Code plugins for full-stack engineering workflows.

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
claude plugin install test-builder@xari-plugins
claude plugin install data-engineer@xari-plugins
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

Coding conventions and meta-skills.

| Skill | Description |
|-------|-------------|
| `/conventions` | Apply xari coding style — TypeScript-first, minimal abstractions, conventional commits |
| `/create-skill` | Generate a new SKILL.md with proper frontmatter and structure |

### architect

System design and architecture decisions.

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

### test-builder

Test generation across all layers.

| Skill | Description |
|-------|-------------|
| `/unit-tests` | Generate isolated unit tests with edge cases and mocks |
| `/integration-tests` | Generate integration tests with real database |
| `/e2e-tests` | Generate Playwright/Cypress end-to-end tests |

### data-engineer

Data pipeline and SQL workflows.

| Skill | Description |
|-------|-------------|
| `/pipeline-design` | Design ETL/ELT pipelines with monitoring |
| `/schema-review` | Review schemas for normalization, indexes, naming |
| `/sql-optimizer` | Analyze and optimize SQL queries |

## Per-project setup

Add plugins to a specific project by installing with project scope:

```bash
# In your project directory
claude plugin install architect@xari-plugins --scope project
claude plugin install backend-dev@xari-plugins --scope project
```

This writes to `.claude/settings.json` which you can commit to share with your team.

For personal use without committing:

```bash
claude plugin install architect@xari-plugins --scope local
```

This writes to `.claude/settings.local.json` (gitignored).

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
│   ├── shared/
│   ├── architect/
│   ├── backend-dev/
│   ├── test-builder/
│   └── data-engineer/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
│           └── <skill-name>/
│               └── SKILL.md
└── README.md
```
