---
name: bug-review
description: "Analyze code changes or bug reports to identify root cause, verify fix completeness, and check for regressions"
user-invocable: true
argument-hint: "<file-or-pr-or-description> [mode: diagnose|verify-fix]"
---

# Bug Review

Review: **$ARGUMENTS** (mode defaults to diagnose)

## Diagnose Mode

1. **Reproduce the conditions** — Understand what triggers the bug:
   - What input or sequence of actions causes it?
   - Is it environment-specific (OS, browser, Node version)?
   - Is it timing-dependent (race condition, async ordering)?

2. **Trace the execution path** — Read the code flow from entry point to failure:
   - Follow the data through each function call
   - Identify where the actual behavior diverges from expected
   - Check recent changes that touched this code path (`git log -p`)

3. **Identify root cause** — Distinguish symptom from cause:
   - Is the bug in this code, or in a dependency it trusts?
   - Is it a logic error, a state management issue, or a data integrity problem?
   - Could this same root cause manifest elsewhere?

4. **Propose fix** — Suggest a minimal fix that:
   - Addresses the root cause, not just the symptom
   - Doesn't introduce new edge cases
   - Includes a test that would have caught this

## Verify-Fix Mode

1. **Read the fix** — Understand what changed and why.

2. **Check completeness**:
   - Does it fix the root cause or just the symptom?
   - Does it handle all the edge cases discovered during diagnosis?
   - Are there other call sites that have the same bug?

3. **Check for regressions**:
   - Does the fix change behavior for any existing valid inputs?
   - Does it break any existing tests?
   - Does it change the API contract?

4. **Check test coverage**:
   - Is there a test that reproduces the original bug?
   - Does the test fail without the fix and pass with it?
   - Are edge cases from the bug also tested?

## Output Format

```markdown
## Bug Review: <target>

### Root Cause
<1-3 sentences explaining the fundamental issue>

### Impact
- **Severity**: critical | high | medium | low
- **Blast radius**: <what's affected>
- **Frequency**: <how often this triggers>

### Fix
<Code diff or description of the fix>

### Regression Risk
- <potential regression 1>
- <potential regression 2>

### Test Case
```typescript
it("reproduces the bug scenario", () => {
  // Setup that triggers the bug
  // Assert correct behavior
});
```

### Related Code
- <other locations with the same pattern>
```

## Constraints

- Always identify root cause before suggesting fixes
- The fix should be minimal — don't refactor surrounding code
- Check if the same pattern exists elsewhere in the codebase
- A fix without a regression test is incomplete
