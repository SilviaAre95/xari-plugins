# Worked Examples

## Escape hatch: unified diff of a spec change

Produce the diff against the feature file, never prose-only:

```diff
--- a/docs/features/auth-login.md
+++ b/docs/features/auth-login.md
@@ acceptance_criteria @@
-  - Session persists 30 days
+  - Session persists 14 days
+  - User can extend session to 30 days via "remember me"
```

Show it with a one-line summary of the behavioral impact, then wait for explicit approval ("yes", "approved", "go") before applying.

## Eliciting non_goals

`non_goals` is the single most important anti-drift field — it says what the feature will NOT do. Push the user on this. Example non_goals for a "export reports as CSV" feature:

- "NOT export as PDF"
- "NOT support scheduled exports"
- "NOT include deleted records"

If the user says "I don't know what non-goals to list", suggest 3–5 plausible ones and ask them to confirm or reject each.

## Acceptance criteria: behavioral, not implementation

- ✅ "User can log in with email and password"
- ✅ "Failed login shows an inline error"
- ✅ "Session persists for 30 days"
- ❌ "Code in auth.ts handles JWT signing" — implementation detail
- ❌ "Works well", "is fast" — not checkable

## Preflight statement block

Before coding, state in one short block: feature IDs touched, the behavior you intend to implement or change, which `acceptance_criteria` it satisfies, and confirmation that nothing in `non_goals` is violated.
