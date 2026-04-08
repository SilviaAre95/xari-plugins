---
name: regression-check
description: "Analyze code changes for potential regressions — check affected paths, downstream consumers, and test coverage gaps"
user-invocable: true
argument-hint: "<file-or-pr> [depth: shallow|deep]"
---

# Regression Check

Check for regressions in: **$0**

Depth: **$1** (default: deep)

## Steps

1. **Map the change surface** — Identify what was modified:
   - Which files changed?
   - Which functions/exports were modified?
   - Did any public interfaces change (function signatures, types, API responses)?

2. **Trace downstream consumers** — For each changed export/interface:
   - Who imports this module? (`grep` for import statements)
   - Who calls these functions? (find all call sites)
   - Are there any dynamic consumers (string-based imports, reflection)?

3. **Classify risk per consumer**:
   - **Breaking**: signature changed, return type changed, thrown error changed
   - **Behavioral**: same interface but different output for some inputs
   - **Safe**: internal-only change, consumers unaffected

4. **Check test coverage**:
   - Are the changed code paths covered by existing tests?
   - Do existing tests assert on the specific behaviors that changed?
   - Are downstream consumers tested with integration tests?
   - Run existing tests — do they still pass?

5. **Identify coverage gaps**:
   - Consumers with no tests at all
   - Tests that pass but don't assert on the changed behavior
   - Missing edge case tests for new code paths

6. **Check non-obvious regressions**:
   - Performance: did the change add a loop, remove a cache, increase query count?
   - Security: did the change modify auth, validation, or data access?
   - Ordering: does the change affect sort order, event sequence, or render order?
   - Side effects: does the change add/remove writes, notifications, or logging?

## Output Format

```markdown
## Regression Check: <target>

### Change Summary
- **Files changed**: N
- **Public interfaces modified**: <list>
- **Risk level**: low | medium | high

### Affected Consumers
| Consumer | Risk | Test Coverage | Action Needed |
|----------|------|---------------|---------------|
| <file>   | breaking/behavioral/safe | covered/partial/none | <action> |

### Coverage Gaps
1. **<gap>**: <what's not tested + suggested test>

### Non-obvious Risks
1. **<risk>**: <explanation>

### Recommended Actions
- [ ] <action 1>
- [ ] <action 2>
```

## Constraints

- Trace actual import chains, don't guess at consumers
- Run existing tests if possible — don't just check if they exist
- Distinguish "no test coverage" from "tests exist but don't cover this path"
- For deep mode, follow the chain at least 2 levels (consumer's consumers)
