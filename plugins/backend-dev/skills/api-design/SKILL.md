---
name: api-design
description: "Design REST or GraphQL API endpoints with request/response schemas, validation, auth, and error handling"
user-invocable: true
argument-hint: "<resource-or-feature> [rest|graphql]"
---

# API Design

Design the API for: **$ARGUMENTS** (style defaults to REST)

## Steps

1. **Identify resources** — What entities does this API manage? Map out the nouns.

2. **Define endpoints** — For each resource:
   - HTTP method + path (REST) or queries/mutations (GraphQL)
   - Request body / query params with types
   - Response shape with types
   - Auth requirements (public, authenticated, role-based)

3. **Validation rules** — Define Zod schemas for request validation:
   - Required vs optional fields
   - Type constraints (string length, number ranges, enums)
   - Cross-field validation

4. **Error responses** — Define the error contract:
   - Consistent error shape across all endpoints
   - Proper HTTP status codes
   - Machine-readable error codes + human-readable messages

5. **Write implementation skeleton** — Produce the actual route handler code with:
   - Zod validation
   - Auth check
   - Business logic placeholder
   - Error handling
   - Response typing

## Output Format

For each endpoint, produce:

```markdown
## <METHOD> <path>

**Auth**: <public | authenticated | admin>
**Description**: <what it does>

### Request
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| ...   | ...  | ...      | ...        |

### Response (200)
```json
{ "shape": "example" }
```

### Errors
| Status | Code | When |
|--------|------|------|
| 400    | VALIDATION_ERROR | Invalid input |
| 401    | UNAUTHORIZED | Missing/invalid token |
| 404    | NOT_FOUND | Resource doesn't exist |
```

Then produce the implementation code (TypeScript, Next.js App Router by default).

## Constraints

- Use Zod for all request validation
- Always return proper HTTP status codes
- Never expose internal error details to clients
- Use consistent error response shape across all endpoints
- Prefer pagination for list endpoints (cursor-based over offset)
