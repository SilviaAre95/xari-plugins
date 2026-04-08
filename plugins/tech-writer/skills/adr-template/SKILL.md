---
name: adr-template
description: "Set up Architecture Decision Records infrastructure — directory, template, numbering, and index"
user-invocable: true
argument-hint: "[action: init|list|status]"
---

# ADR Template Manager

Action: **$0** (default: init)

## Init Mode

Set up the ADR infrastructure for the project:

1. **Create directory**: `docs/adr/`

2. **Create template**: `docs/adr/TEMPLATE.md`

```markdown
# ADR-NNNN: <Title>

**Status**: proposed | accepted | deprecated | superseded by ADR-XXXX
**Date**: YYYY-MM-DD
**Deciders**: <names>

## Context

What is the issue motivating this decision?

## Decision Drivers

- <driver 1>
- <driver 2>

## Options Considered

### Option 1: <name>
<description>
- **Pros**: ...
- **Cons**: ...

### Option 2: <name>
<description>
- **Pros**: ...
- **Cons**: ...

## Decision

What is the change we're making?

## Consequences

### Positive
- <consequence>

### Negative
- <consequence>

### Risks
- <risk and how we'll mitigate it>
```

3. **Create index**: `docs/adr/README.md`

```markdown
# Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-use-adrs.md) | Use ADRs to document decisions | accepted | <today> |
```

4. **Create first ADR**: `docs/adr/0001-use-adrs.md` — documenting the decision to use ADRs

## List Mode

Scan `docs/adr/` and produce an updated index table with:
- ADR number
- Title (from H1)
- Status (from frontmatter)
- Date
- Flag any ADRs with status "proposed" that are older than 30 days

## Status Mode

Show summary:
- Total ADRs
- By status (proposed, accepted, deprecated, superseded)
- Recent (last 30 days)
- Stale proposed ADRs

## Output Format

Produce the files directly. For list/status modes, output a markdown summary.

## Constraints

- Use 4-digit numbering (0001, 0002, ...) for sort order
- Never modify existing ADR content — ADRs are immutable records
- To change a decision, create a new ADR that supersedes the old one
- Keep the index in `docs/adr/README.md` up to date
