# Feature Bank — Index

Source of truth for what this product **does** and **does not** do. Every code change affecting `/src`, `/app`, `/lib`, `/api`, `/components`, `/pages`, or equivalent must preflight against this bank.

## How to use

- Agents: read this file first. Load the relevant feature file(s) before editing code.
- Humans: add new features via the `feature-bank` skill scaffolder, not by hand-editing (unless you like inconsistency).
- Spec changes require the diff-first escape hatch. See the skill.

## Features

| ID | Title | Status | Summary | Top non-goals |
|----|-------|--------|---------|---------------|
| `example-feature` | Example feature | proposed | One-line description of what it does. | NOT X, NOT Y |

<!-- Append new rows above this comment. Keep the summary column ≤ 15 words. -->

## Deprecated

| ID | Title | Deprecated on | Replaced by |
|----|-------|---------------|-------------|
| | | | |

## Conventions

- **Feature IDs**: kebab-case, domain-prefixed (`auth-login`, `billing-invoice`, `search-filters`).
- **Status values**: `proposed` → `in-progress` → `implemented` → `deprecated`.
- **Non-goals**: if empty, the feature has no boundaries. Fix that.
