---
name: adr-writer
description: "Generate an Architecture Decision Record (ADR) documenting a technical decision with context, options, and consequences"
user-invocable: true
argument-hint: "<decision-title> [status: proposed|accepted|deprecated]"
---

# ADR Writer

Write an Architecture Decision Record for: **$0**

Status: **$1** (default: proposed)

## Steps

1. **Read the codebase context** — Check existing ADRs if a `docs/adr/` or `docs/decisions/` directory exists. Follow the existing numbering scheme.

2. **Gather context** — Understand what problem is being solved and what forces are at play (technical constraints, business requirements, team capacity).

3. **Document options** — List at least 2 alternatives that were considered. For each, note the key tradeoff.

4. **Write the ADR** — Use the template below.

5. **Save the file** — Write to `docs/adr/NNNN-<kebab-case-title>.md` using the next available number.

## Output Format

Write the ADR as a markdown file:

```markdown
# ADR-NNNN: <Title>

**Status**: <proposed | accepted | deprecated | superseded by ADR-XXXX>
**Date**: <YYYY-MM-DD>
**Deciders**: <who was involved>

## Context

<What is the issue that we're seeing that is motivating this decision or change?>

## Decision Drivers

- <driver 1>
- <driver 2>
- <driver 3>

## Options Considered

### Option 1: <name>
<Description>
- **Pros**: <list>
- **Cons**: <list>

### Option 2: <name>
<Description>
- **Pros**: <list>
- **Cons**: <list>

## Decision

<What is the change that we're proposing and/or doing?>

## Consequences

### Positive
- <consequence>

### Negative
- <consequence>

### Risks
- <risk and mitigation>
```

## Constraints

- Follow existing ADR numbering if a directory exists
- Keep it concise — ADRs are reference docs, not essays
- The decision section should be 1-3 sentences
- Always include at least one negative consequence (every decision has tradeoffs)
