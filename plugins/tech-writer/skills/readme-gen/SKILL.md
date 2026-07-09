---
name: readme-gen
description: "Generate a comprehensive README.md by analyzing the project's code, config, and structure"
user-invocable: true
argument-hint: "[style: minimal|standard|detailed]"
---

# README Generator

Generate the README in the requested style: **$ARGUMENTS** (defaults to standard)

## Steps

1. **Analyze the project**:
   - Read `package.json` / `pyproject.toml` / `go.mod` for project metadata
   - Read existing README if present (preserve custom sections)
   - Scan directory structure for architecture insights
   - Check for existing docs (API docs, guides, ADRs)
   - Identify the tech stack from dependencies

2. **Generate sections based on style**:

### Minimal
- Project name + one-line description
- Quick start (install + run)
- License

### Standard (default)
- Project name + description
- Tech stack badges
- Prerequisites
- Installation
- Development (run, test, lint)
- Project structure (key directories only)
- Environment variables (from `.env.example`)
- Deployment
- Contributing
- License

### Detailed
- Everything in Standard, plus:
- Architecture overview
- API documentation summary
- Database schema overview
- CI/CD pipeline description
- Troubleshooting
- Changelog or link to releases

3. **Generate environment variable documentation**:
   - Read `.env.example` if it exists
   - Document each variable with description, required/optional, example value
   - Group by category (database, auth, external services)

4. **Write the README**:

```markdown
# Project Name

Brief description of what this project does.

## Tech Stack

- **Runtime**: Node.js 20
- **Framework**: Next.js 14 (App Router)
- **Database**: PostgreSQL + Prisma
- **Styling**: Tailwind CSS

## Getting Started

### Prerequisites

- Node.js >= 20
- PostgreSQL >= 15

### Installation

\`\`\`bash
git clone <repo-url>
cd <project>
npm install
cp .env.example .env
# Edit .env with your values
npx prisma db push
npm run dev
\`\`\`

## Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| DATABASE_URL | yes | PostgreSQL connection string | postgresql://... |

## Project Structure

\`\`\`
src/
├── app/          # Next.js routes
├── components/   # React components
├── lib/          # Utilities and config
└── server/       # API logic
\`\`\`
```

## Constraints

- Don't invent features — only document what exists in the code
- Keep language concise and scannable
- Use tables for structured data (env vars, scripts)
- Include actual commands, not placeholders
- If a section doesn't apply, skip it — don't add empty sections
