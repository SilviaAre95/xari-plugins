---
name: task-breakdown
description: "Break a feature or epic into implementable tasks with estimates, dependencies, and suggested order"
user-invocable: true
argument-hint: "<feature-or-epic> [granularity: high-level|detailed]"
---

# Task Breakdown

Break down the feature or epic: **$ARGUMENTS** (granularity defaults to detailed)

## Steps

1. **Understand the scope** — Read user stories, PRDs, or feature descriptions. If code exists, read the relevant areas to understand current state and what needs to change.

2. **Identify work streams**:
   - **Backend**: API endpoints, database changes, business logic
   - **Frontend**: components, pages, forms, state management
   - **Infrastructure**: deploy config, environment variables, CI changes
   - **Testing**: unit, integration, e2e tests
   - **Documentation**: README updates, API docs, ADRs

3. **Break into tasks** — Each task should be:
   - Completable by one person in 1-3 days
   - Independently mergeable (or clearly part of a sequence)
   - Testable on its own

4. **Map dependencies** — Which tasks block others?
   - Database schema must exist before API endpoints
   - API endpoints must exist before frontend integration
   - But: frontend components can be built with mocks in parallel

5. **Suggest implementation order** — Optimize for:
   - Unblocking parallel work early
   - Getting a vertical slice working end-to-end first
   - Reducing risk (hard/uncertain tasks first)

## Output Format

```markdown
## Task Breakdown: <feature>

### Summary
- **Total tasks**: N
- **Estimated effort**: X days (1 developer)
- **Parallelizable**: Y (with 2 developers, ~Z days)

### Critical Path
`[Schema] → [API] → [Frontend Integration] → [E2E Tests]`

### Tasks

#### Phase 1: Foundation (unblocks everything)

- [ ] **T-001**: <task title>
  - **Stream**: backend | frontend | infra | testing
  - **Estimate**: S (< 1 day) | M (1-2 days) | L (2-3 days) | XL (3+ days, should be split)
  - **Depends on**: — (none)
  - **Details**: <what specifically needs to happen>

- [ ] **T-002**: <task title>
  - **Stream**: backend
  - **Estimate**: M
  - **Depends on**: T-001
  - **Details**: <specifics>

#### Phase 2: Core Implementation (can parallelize)
...

#### Phase 3: Polish & Testing
...

### Parallel Work Opportunities
- Developer A: T-001 → T-003 → T-005
- Developer B: T-002 → T-004 → T-006

### Risks
- <risk>: <mitigation>
```

## Constraints

- Tasks should be small enough to review in one PR
- XL tasks (3+ days) should be split further
- Always include testing tasks — they're not optional
- Don't create tasks for trivial work (e.g., "create file" — that's part of the implementation task)
- Include infra/config tasks that are easy to forget (env vars, migrations, CI updates)
