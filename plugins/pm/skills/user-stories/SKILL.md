---
name: user-stories
description: "Generate user stories with acceptance criteria from a feature description or existing code"
user-invocable: true
argument-hint: "<feature-description> [format: standard|gherkin]"
---

# User Story Generator

Write user stories for the feature: **$ARGUMENTS** (format defaults to standard)

## Steps

1. **Understand the feature** — If a codebase exists, read the relevant code to understand current state. If it's a new feature, work from the description.

2. **Identify personas** — Who uses this feature?
   - Primary user (the main beneficiary)
   - Secondary users (admin, support, other roles)
   - System actors (cron jobs, webhooks, integrations)

3. **Write user stories** — For each meaningful interaction:

### Standard format
```
As a <persona>,
I want to <action>,
so that <benefit>.
```

### Acceptance criteria
```
Given <precondition>,
When <action>,
Then <expected result>.
```

4. **Categorize stories**:
   - **Must have**: core functionality, the feature doesn't work without these
   - **Should have**: expected behavior, users would notice if missing
   - **Could have**: nice to have, can be deferred
   - **Won't have** (this iteration): explicitly out of scope

5. **Add technical notes** where relevant:
   - API endpoints needed
   - Database changes
   - Third-party integrations
   - Performance considerations

6. **Deliver where the project lives** (detect, never assume):
   - **Tracker**: if a tracker MCP is connected (e.g. Linear tools are available), create each story as an issue in the feature's project (story as title, acceptance criteria in the description, MVP stories prioritized) and reply with the issue keys. Confirm with the user before creating more than 10 issues.
   - **Second brain**: if this project's CLAUDE.md names a vault or notes location, save the story set as a note linked from the project's main note.
   - **Neither connected**: print the stories as markdown, exactly as below. Never error or apologize for missing integrations.

## Output Format

```markdown
## User Stories: <feature>

### Personas
- **<Persona 1>**: <description>
- **<Persona 2>**: <description>

---

### Must Have

#### US-001: <title>
**As a** <persona>,
**I want to** <action>,
**so that** <benefit>.

**Acceptance Criteria**:
- [ ] Given <condition>, when <action>, then <result>
- [ ] Given <condition>, when <action>, then <result>

**Technical Notes**: <API, DB, or integration details>

**Estimate**: S / M / L / XL

---

### Should Have
...

### Could Have
...

### Out of Scope
- <explicitly excluded item>
```

## Constraints

- Stories should be independent (no story depends on another being done first)
- Stories should be testable — every acceptance criterion is verifiable
- Stories should be small enough to complete in one sprint
- Don't write stories for implementation details ("set up database table") — write for user value
- Include at least one edge case or error scenario per story
