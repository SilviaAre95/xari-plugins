# Spec File Formats

## Feature IDs

Kebab-case, domain-prefixed: `auth-login`, `billing-invoice`, `search-filters`.

## Feature file template

See `templates/feature.md`. Required frontmatter fields:

```yaml
id: <kebab-case-id>
title: <short human title>
status: proposed | in-progress | implemented | deprecated
created_at: YYYY-MM-DD
last_modified: YYYY-MM-DD
owner: <name or team>
depends_on: [<other-feature-ids>]
acceptance_criteria:
  - <testable behavior 1>
  - <testable behavior 2>
non_goals:
  - <thing this feature will NOT do>
  - <another exclusion>
```

Body sections (markdown, kept short):

- `## Summary` — one paragraph, what and why
- `## Behavior` — user-facing behavior in prose
- `## Out of scope` — narrative expansion of non_goals
- `## Open questions` — unresolved decisions (empty once `implemented`)

## INDEX.md format

See `templates/INDEX.md`. It's a compact table so agents can load it cheaply and scan non_goals fast. Each row: ID, title, status, one-line summary, top 2 non_goals.

## Changelog format

`<feature-id>.CHANGELOG.md` is append-only history. See `templates/CHANGELOG.md`. Postflight entry example:

```markdown
## 2026-04-16
- **Changed**: login session duration reduced from 30 → 14 days
- **Added**: "remember me" extension flow
- **Files touched**: src/auth/session.ts, src/auth/login.tsx
- **Approved via**: diff-first escape hatch
```

## Postflight metadata rules

On every touched feature file:

- `last_modified: <today's date>`
- `status` if it changed (e.g., `proposed` → `in-progress`, `in-progress` → `implemented`)
