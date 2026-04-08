---
name: integration-tests
description: "Generate integration tests that verify component interactions — API routes, database queries, service layers"
user-invocable: true
argument-hint: "<feature-or-endpoint> [framework: vitest|jest]"
---

# Integration Test Generator

Generate integration tests for: **$0**

Framework: **$1** (default: vitest)

## Steps

1. **Identify the integration boundary** — What components are being tested together?
   - API route + database
   - Service layer + external API
   - Multiple services collaborating

2. **Set up test infrastructure**:
   - Database: use a test database (not mocks) — Prisma with a test schema
   - External APIs: use MSW (Mock Service Worker) or similar for HTTP mocking
   - Auth: create test fixtures for authenticated/unauthenticated states

3. **Design test scenarios**:
   - **Full flow** — request in, response out, verify database state
   - **Error propagation** — verify errors at one layer surface correctly at another
   - **Data integrity** — verify relations, cascades, constraints
   - **Concurrent access** — if relevant, test race conditions

4. **Write tests**:

```typescript
import { describe, it, expect, beforeAll, afterAll, beforeEach } from "vitest";
import { prisma } from "@/lib/prisma";
import { createTestUser, cleanupTestData } from "./helpers";

describe("POST /api/orders", () => {
  let testUser: User;

  beforeAll(async () => {
    testUser = await createTestUser();
  });

  afterAll(async () => {
    await cleanupTestData();
  });

  beforeEach(async () => {
    await prisma.order.deleteMany({ where: { userId: testUser.id } });
  });

  it("creates an order and updates inventory", async () => {
    const response = await fetch("/api/orders", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${testUser.token}`,
      },
      body: JSON.stringify({ productId: "prod_1", quantity: 2 }),
    });

    expect(response.status).toBe(201);

    const order = await prisma.order.findFirst({
      where: { userId: testUser.id },
    });
    expect(order).toBeDefined();
    expect(order?.quantity).toBe(2);

    const product = await prisma.product.findUnique({
      where: { id: "prod_1" },
    });
    expect(product?.stock).toBe(initialStock - 2);
  });

  it("returns 400 when quantity exceeds stock", async () => {
    const response = await fetch("/api/orders", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${testUser.token}`,
      },
      body: JSON.stringify({ productId: "prod_1", quantity: 99999 }),
    });

    expect(response.status).toBe(400);
    const body = await response.json();
    expect(body.code).toBe("INSUFFICIENT_STOCK");
  });
});
```

5. **Add test helpers** — Create reusable fixtures:
   - `createTestUser()` — seed a user with auth token
   - `cleanupTestData()` — tear down test data
   - `seedDatabase()` — populate required reference data

## Output Format

- Test files in `__tests__/integration/` or alongside the feature
- Include test helpers/fixtures as separate files
- Include setup instructions if new dependencies are needed

## Constraints

- Use real database, not mocks — that's the whole point
- Clean up test data in `afterAll`/`afterEach` — don't leave state between tests
- Tests should be runnable independently and in any order
- Keep test data minimal — only what's needed for the assertion
- Don't test framework behavior (e.g., don't test that Next.js routing works)
