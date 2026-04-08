---
name: edge-case-finder
description: "Identify edge cases, boundary conditions, and failure modes in code that tests should cover"
user-invocable: true
argument-hint: "<file-or-function> [scope: inputs|state|concurrency|all]"
---

# Edge Case Finder

Find edge cases in: **$0**

Scope: **$1** (default: all)

## Steps

1. **Read the code** — understand the function/module's purpose, inputs, outputs, and dependencies.

2. **Analyze input boundaries**:
   - Empty/null/undefined inputs
   - Single-element collections
   - Maximum-length strings, arrays at capacity
   - Negative numbers, zero, MAX_SAFE_INTEGER
   - Unicode, emoji, RTL text, zero-width characters
   - SQL injection strings, XSS payloads, path traversal
   - Extremely long inputs (DoS potential)

3. **Analyze state transitions**:
   - Initial state (first-time use, empty database)
   - Race conditions (concurrent calls to the same resource)
   - State after error (is cleanup handled? partial writes?)
   - Stale state (cached data that's been updated elsewhere)
   - State overflow (counters wrapping, queues full)

4. **Analyze external dependencies**:
   - Network timeout/failure during operation
   - Database connection pool exhaustion
   - Partial response from external API
   - Clock skew (timezone, DST, leap seconds)
   - File system full, permission denied

5. **Analyze business logic boundaries**:
   - Off-by-one in pagination, date ranges, loops
   - Timezone handling (UTC vs local, DST boundaries)
   - Currency rounding ($0.005 → $0.00 or $0.01?)
   - Locale differences (decimal separator, date format)
   - Permission boundaries (user A accessing user B's data)

6. **Prioritize by impact**:
   - **Critical**: data corruption, security vulnerability, money miscalculation
   - **High**: silent failure, incorrect result returned as correct
   - **Medium**: poor UX, confusing error message
   - **Low**: cosmetic, unlikely to occur

## Output Format

```markdown
## Edge Cases: <target>

### Critical
| # | Edge Case | Input/Condition | Expected Behavior | Current Behavior |
|---|-----------|----------------|-------------------|-----------------|
| 1 | <case>    | <trigger>      | <what should happen> | <what actually happens or "untested"> |

### High Priority
| # | Edge Case | Input/Condition | Expected Behavior |
|---|-----------|----------------|-------------------|
| 1 | <case>    | <trigger>      | <what should happen> |

### Medium / Low
...

### Recommended Test Cases
```typescript
// Test case 1: <description>
it("<edge case description>", () => {
  expect(fn(edgeCaseInput)).toEqual(expected);
});
```
```

## Constraints

- Focus on edge cases that could actually happen in production, not theoretical impossibilities
- For each edge case, suggest a concrete test case
- Don't just list categories — identify specific inputs and conditions for this code
- Prioritize by impact, not by how interesting the edge case is
