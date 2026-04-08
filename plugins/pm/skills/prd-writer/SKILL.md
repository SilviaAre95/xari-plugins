---
name: prd-writer
description: "Generate a Product Requirements Document from a feature idea — problem, solution, scope, success metrics"
user-invocable: true
argument-hint: "<feature-name> [audience: engineering|stakeholders|both]"
---

# PRD Writer

Feature: **$0**

Audience: **$1** (default: both)

## Steps

1. **Understand the context** — If a codebase exists, read relevant code to understand current capabilities. Use the feature description to understand the gap.

2. **Define the problem**:
   - What's the user pain point?
   - What's the business motivation?
   - What evidence exists (user feedback, metrics, competitive analysis)?

3. **Define the solution**:
   - High-level description of what we're building
   - Key user flows (happy path + error cases)
   - What's explicitly NOT in scope

4. **Write the PRD**:

```markdown
# PRD: <Feature Name>

**Author**: <name>
**Date**: <date>
**Status**: Draft | In Review | Approved

## Problem Statement

<2-3 sentences: what's broken or missing, who's affected, why it matters>

## Goals

1. <Primary goal — what success looks like>
2. <Secondary goal>

## Non-Goals

- <What we're explicitly NOT doing>
- <Adjacent features we're deferring>

## User Stories

### Primary User: <persona>
- As a <persona>, I want to <action>, so that <benefit>

### Secondary User: <persona>
- As a <persona>, I want to <action>, so that <benefit>

## Proposed Solution

### Overview
<1 paragraph description of the approach>

### Key Flows

#### Flow 1: <name>
1. User does X
2. System responds with Y
3. User sees Z

#### Flow 2: <name>
...

### Technical Considerations
- <Architecture impact>
- <Data model changes>
- <Third-party dependencies>
- <Performance requirements>

## Success Metrics

| Metric | Current | Target | How to Measure |
|--------|---------|--------|----------------|
| <metric> | <baseline> | <goal> | <instrumentation> |

## Scope & Timeline

### Phase 1 (MVP)
- <feature 1>
- <feature 2>

### Phase 2 (Enhancement)
- <feature 3>

### Out of Scope
- <deferred item>

## Open Questions

1. <Question that needs stakeholder input>
2. <Technical question that needs investigation>

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| <risk> | low/med/high | low/med/high | <plan> |
```

5. **Tailor for audience**:
   - **Engineering**: include technical considerations, data model, API surface
   - **Stakeholders**: focus on business value, metrics, timeline
   - **Both**: full document with clear sections for each audience

## Constraints

- Keep it under 2 pages for MVP features, 4 pages for large features
- Every goal must have a measurable success metric
- Non-goals are as important as goals — be explicit about scope
- Open questions should have owners and deadlines
- Don't write implementation details — that's the engineering spec, not the PRD
