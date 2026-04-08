---
name: api-docs
description: "Generate API documentation by reading route handlers — endpoints, request/response schemas, auth requirements"
user-invocable: true
argument-hint: "<api-directory-or-file> [format: markdown|openapi]"
---

# API Documentation Generator

Target: **$0**

Format: **$1** (default: markdown)

## Steps

1. **Discover endpoints** — Scan route files:
   - Next.js App Router: `app/api/**/route.ts`
   - Express/Fastify: `routes/**/*.ts`
   - Read each handler to extract HTTP methods

2. **For each endpoint, extract**:
   - HTTP method and path
   - Request body schema (from Zod schemas or TypeScript types)
   - Query parameters
   - Path parameters
   - Response shape (from return statements or response types)
   - Auth requirements (middleware, decorators, session checks)
   - Error responses (from error handling code)

3. **Group endpoints** by resource or feature area

4. **Generate documentation**:

### Markdown format

```markdown
# API Reference

## Authentication

All endpoints except those marked "Public" require a valid session cookie or Bearer token.

---

## Users

### GET /api/users

Retrieve a list of users.

**Auth**: Admin only

**Query Parameters**:
| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| page | number | no | 1 | Page number |
| limit | number | no | 20 | Items per page |

**Response** `200 OK`:
\`\`\`json
{
  "users": [{ "id": "...", "name": "...", "email": "..." }],
  "total": 100,
  "page": 1
}
\`\`\`

**Errors**:
| Status | Code | Description |
|--------|------|-------------|
| 401 | UNAUTHORIZED | Missing or invalid session |
| 403 | FORBIDDEN | Not an admin |
```

### OpenAPI format

Generate a valid OpenAPI 3.0 YAML document with:
- Info block (title, version, description)
- Server URLs
- Paths with operations
- Component schemas (reusable request/response types)
- Security schemes

5. **Verify completeness** — Cross-reference discovered endpoints with the route file tree to ensure nothing was missed.

## Output Format

- Markdown: single `docs/api.md` file or per-resource files
- OpenAPI: `openapi.yaml` at project root

## Constraints

- Document what exists, don't invent endpoints
- Extract schemas from code (Zod, TypeScript types), don't guess
- Include error responses — they're as important as success responses
- Keep examples realistic (use plausible data, not "string" or "123")
- If auth middleware exists, check which endpoints use it
