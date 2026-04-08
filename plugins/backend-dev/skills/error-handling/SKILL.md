---
name: error-handling
description: "Design or implement error handling patterns — custom error classes, error boundaries, API error responses"
user-invocable: true
argument-hint: "<scope: api|service|component> [language]"
---

# Error Handling

Design error handling for: **$0** scope

Language/framework: **$1** (default: TypeScript)

## Steps

1. **Audit current state** — Read the existing error handling in the target scope. Identify:
   - Silent catches (`catch (e) {}` or `catch (e) { console.log(e) }`)
   - Inconsistent error shapes across endpoints
   - Missing error boundaries (React) or global handlers (API)
   - Leaked internal details in error responses

2. **Design error hierarchy** — Create a structured error system:

```typescript
// Base application error
class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500,
    public isOperational: boolean = true
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

// Specific errors
class ValidationError extends AppError {
  constructor(message: string, public fields?: Record<string, string>) {
    super(message, "VALIDATION_ERROR", 400);
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id?: string) {
    super(
      id ? `${resource} with id ${id} not found` : `${resource} not found`,
      "NOT_FOUND",
      404
    );
  }
}

class UnauthorizedError extends AppError {
  constructor(message = "Authentication required") {
    super(message, "UNAUTHORIZED", 401);
  }
}

class ForbiddenError extends AppError {
  constructor(message = "Insufficient permissions") {
    super(message, "FORBIDDEN", 403);
  }
}
```

3. **Implement error handler** — Based on scope:

   **API**: Global error handler middleware that catches `AppError` subclasses and returns consistent JSON responses. Log unexpected errors, return generic messages.

   **Service**: Translate external errors (Prisma, fetch, etc.) into `AppError` subclasses at service boundaries. Never let raw database errors reach the API layer.

   **Component** (React): Error boundaries with fallback UI. `useErrorHandler` hook for async errors.

4. **Add logging** — Structured error logging:
   - Operational errors: `warn` level
   - Programming errors: `error` level with stack trace
   - Never log sensitive data (passwords, tokens, PII)

## Output Format

Produce implementation code with:
- Error class definitions
- Error handler (middleware, boundary, or utility)
- Example usage showing how to throw and catch

## Constraints

- Never expose stack traces or internal details in production responses
- Always distinguish operational errors (expected) from programming errors (bugs)
- Use typed error codes, not string matching on messages
- Log enough context to debug without leaking sensitive data
- Prefer explicit error handling over generic try/catch wrappers
