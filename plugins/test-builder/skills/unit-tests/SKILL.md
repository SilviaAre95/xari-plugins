---
name: unit-tests
description: "Generate unit tests for functions, classes, or modules — isolated, fast, with edge cases and mocks"
user-invocable: true
argument-hint: "<file-or-function> [framework: vitest|jest]"
---

# Unit Test Generator

Generate unit tests for: **$ARGUMENTS** (framework defaults to vitest)

## Steps

1. **Read the target code** — Understand the function/class signature, dependencies, return types, and side effects.

2. **Identify test cases** — For each public function or method:
   - **Happy path** — expected inputs produce expected outputs
   - **Edge cases** — empty inputs, boundary values, null/undefined
   - **Error cases** — invalid inputs, thrown exceptions
   - **Type boundaries** — test with types at the edges of what's accepted

3. **Design mocks** — Identify external dependencies:
   - Database calls → mock the Prisma client
   - API calls → mock fetch/axios
   - File system → mock fs
   - Time-dependent → mock Date.now / timers
   - Only mock what's necessary — prefer real implementations when possible

4. **Write tests** — Follow this structure:

```typescript
import { describe, it, expect, vi } from "vitest";
import { targetFunction } from "./target";

describe("targetFunction", () => {
  // Group by behavior, not by method
  describe("when given valid input", () => {
    it("returns the expected result", () => {
      const result = targetFunction("valid");
      expect(result).toEqual(expected);
    });
  });

  describe("when given invalid input", () => {
    it("throws a ValidationError", () => {
      expect(() => targetFunction("")).toThrow(ValidationError);
    });
  });

  describe("edge cases", () => {
    it("handles empty arrays", () => {
      expect(targetFunction([])).toEqual([]);
    });
  });
});
```

5. **Verify** — Run the tests and ensure they pass.

## Output Format

- One test file per source file: `<name>.test.ts` colocated or in `__tests__/`
- Follow existing project test conventions if they exist
- Include setup/teardown if needed

## Constraints

- Tests should be independent — no shared mutable state
- One assertion per test when practical (multiple assertions OK if testing one behavior)
- Descriptive test names: `it("returns null when user is not found")` not `it("test 1")`
- Don't test implementation details — test behavior and outputs
- Don't mock what you don't own unless you also have integration tests
- Keep tests fast — no real I/O in unit tests
