---
name: e2e-tests
description: "Generate end-to-end tests that verify complete user workflows through the UI — Playwright or Cypress"
user-invocable: true
argument-hint: "<user-flow> [framework: playwright|cypress]"
---

# E2E Test Generator

Generate end-to-end tests for: **$0**

Framework: **$1** (default: playwright)

## Steps

1. **Map the user flow** — Break the feature into discrete user actions:
   - Navigate to page
   - Fill form / click button / interact with element
   - Wait for response / navigation
   - Verify result (visible text, URL change, element state)

2. **Identify test scenarios**:
   - **Happy path** — complete flow with valid inputs
   - **Validation** — form errors, required fields
   - **Auth states** — logged in, logged out, wrong role
   - **Responsive** — mobile vs desktop if layout changes behavior

3. **Write tests**:

```typescript
import { test, expect } from "@playwright/test";

test.describe("Checkout Flow", () => {
  test.beforeEach(async ({ page }) => {
    // Seed test data or use API to set up state
    await page.goto("/products");
  });

  test("user can complete a purchase", async ({ page }) => {
    // Add item to cart
    await page.click('[data-testid="add-to-cart-btn"]');
    await expect(page.locator('[data-testid="cart-count"]')).toHaveText("1");

    // Go to checkout
    await page.click('[data-testid="checkout-btn"]');
    await expect(page).toHaveURL(/\/checkout/);

    // Fill shipping
    await page.fill('[name="address"]', "123 Test St");
    await page.fill('[name="city"]', "Test City");
    await page.click('[data-testid="continue-btn"]');

    // Confirm order
    await page.click('[data-testid="place-order-btn"]');
    await expect(page.locator("h1")).toHaveText("Order Confirmed");
  });

  test("shows validation errors for empty shipping form", async ({ page }) => {
    await page.click('[data-testid="add-to-cart-btn"]');
    await page.click('[data-testid="checkout-btn"]');
    await page.click('[data-testid="continue-btn"]');

    await expect(page.locator('[data-testid="address-error"]')).toBeVisible();
  });
});
```

4. **Add page objects** (if the flow is complex):

```typescript
class CheckoutPage {
  constructor(private page: Page) {}

  async fillShipping(address: string, city: string) {
    await this.page.fill('[name="address"]', address);
    await this.page.fill('[name="city"]', city);
  }

  async placeOrder() {
    await this.page.click('[data-testid="place-order-btn"]');
  }
}
```

5. **Configure test setup** — Auth state, test data seeding, cleanup.

## Output Format

- Test files in `e2e/` or `tests/e2e/` directory
- Page objects in `e2e/pages/` if needed
- Include any needed test fixtures or global setup

## Constraints

- Use `data-testid` attributes for selectors — never select by CSS class or text content that may change
- Tests must be independent — no shared state between tests
- Avoid `page.waitForTimeout()` — use `expect` with auto-waiting or `waitForSelector`
- Keep tests focused — one user flow per test, not the entire app
- Don't test API logic in E2E — that's what integration tests are for
- Always clean up test data (API calls in `afterAll` or database reset)
