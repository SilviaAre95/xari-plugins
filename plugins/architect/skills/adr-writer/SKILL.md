---
name: adr-writer
description: "Write and manage Architecture Decision Records — generate an ADR for a decision, scaffold the docs/adr/ infrastructure on first use, list or summarize existing ADRs"
user-invocable: true
argument-hint: "<decision-title> | init | list | status"
---

# ADR Writer

Input: **$ARGUMENTS** — a decision title writes an ADR; `init`, `list`, or `status` manage the ADR infrastructure.

## Writing an ADR (default)

1. **Read context** — if `docs/adr/` (or `docs/decisions/`) exists, follow its numbering and conventions. If it doesn't exist, run Init first (below), then continue.
2. **Gather forces** — what problem is being solved; technical constraints, business requirements, team capacity.
3. **Document options** — at least 2 alternatives with their key tradeoff.
4. **Write** to `docs/adr/NNNN-<kebab-case-title>.md` (next available 4-digit number) using the template, and add a row to the index in `docs/adr/README.md`.

```markdown
# ADR-NNNN: <Title>

**Status**: <proposed | accepted | deprecated | superseded by ADR-XXXX>
**Date**: <YYYY-MM-DD>
**Deciders**: <who was involved>

## Context
<What issue motivates this decision?>

## Decision Drivers
- <driver>

## Options Considered
### Option 1: <name>
<description> — **Pros**: <list> / **Cons**: <list>
### Option 2: <name>
<description> — **Pros**: <list> / **Cons**: <list>

## Decision
<The change we're making — 1-3 sentences.>

## Consequences
### Positive
- <consequence>
### Negative
- <consequence>
### Risks
- <risk and mitigation>
```

## Init

Scaffold once per repo: `docs/adr/` directory, `TEMPLATE.md` (the template above), an index `docs/adr/README.md` (table: ADR | Title | Status | Date), and `0001-use-adrs.md` documenting the decision to use ADRs.

## List / Status

- `list`: scan `docs/adr/`, regenerate the index table, flag "proposed" ADRs older than 30 days.
- `status`: totals by status, recent (30 days), stale proposals.

## Constraints

- 4-digit numbering (0001, 0002, …) for sort order
- ADRs are immutable — never edit an existing ADR's content; supersede it with a new one
- Keep the decision section to 1-3 sentences; ADRs are reference docs, not essays
- Always include at least one negative consequence (every decision has tradeoffs)
- Keep `docs/adr/README.md` in sync whenever an ADR is added
