---
name: db-schema
description: "Design or review Prisma database schemas with relations, indexes, and migration strategy"
user-invocable: true
argument-hint: "<feature-or-model> [review|create]"
---

# Database Schema Design

Design or review the database schema for: **$ARGUMENTS** (mode defaults to create)

## Steps

### Create Mode

1. **Identify entities** — What data models does this feature need? Map relationships (1:1, 1:N, M:N).

2. **Design the Prisma schema** — For each model:
   - Fields with types (`String`, `Int`, `DateTime`, `Json`, `Enum`)
   - Relations with `@relation` directives
   - Indexes with `@@index` for query patterns
   - Unique constraints with `@unique` or `@@unique`
   - Soft delete (`deletedAt DateTime?`) if appropriate

3. **Consider edge cases**:
   - What happens when a parent record is deleted? (cascade, set null, restrict)
   - Do you need audit fields? (`createdAt`, `updatedAt`, `createdBy`)
   - Is there data that should be an enum vs a lookup table?

4. **Migration strategy** — If modifying existing schema:
   - Can the migration run with zero downtime?
   - Does it need a backfill?
   - What's the rollback plan?

### Review Mode

1. Read the existing `prisma/schema.prisma`
2. Check for: missing indexes, N+1 query risks, inconsistent naming, missing relations, orphan risk
3. Suggest improvements

## Output Format

```prisma
model Example {
  id        String   @id @default(cuid())
  name      String
  email     String   @unique
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([email])
}
```

Include migration notes if modifying existing schema:

```markdown
## Migration Notes
- **Breaking**: <yes/no>
- **Backfill needed**: <yes/no — describe>
- **Rollback**: <strategy>
```

## Constraints

- Use `cuid()` for IDs by default
- Always add `createdAt` and `updatedAt`
- Name models in PascalCase, fields in camelCase
- Add `@@index` for any field used in WHERE clauses or JOINs
- Prefer enums over magic strings
- Don't use `Json` type unless the shape is truly dynamic
