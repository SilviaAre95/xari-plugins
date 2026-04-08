---
name: schema-review
description: "Review database or data warehouse schemas for normalization, performance, naming, and query patterns"
user-invocable: true
argument-hint: "<schema-file-or-table> [check: all|naming|indexes|normalization]"
---

# Schema Review

Review the schema for: **$0**

Focus area: **$1** (default: all)

## Steps

1. **Read the schema** — Load the schema file (Prisma, SQL DDL, BigQuery JSON, etc.)

2. **Check naming conventions**:
   - Tables: plural, snake_case (`user_sessions`, not `UserSession` or `session`)
   - Columns: snake_case, descriptive (`created_at`, not `ts` or `createdAt`)
   - Foreign keys: `<referenced_table_singular>_id` (e.g., `user_id`)
   - Indexes: `idx_<table>_<columns>` (e.g., `idx_orders_user_id_created_at`)
   - Flag inconsistencies with existing naming patterns

3. **Check normalization**:
   - Are there repeated groups of columns? (1NF violation)
   - Are there columns that depend on non-key columns? (2NF/3NF violation)
   - Is denormalization intentional and documented? (acceptable for read-heavy analytics)

4. **Check indexes**:
   - Every foreign key should have an index
   - Columns in WHERE clauses should have indexes
   - Composite indexes should match query patterns (leftmost prefix rule)
   - Flag missing indexes and unnecessary indexes (write overhead)

5. **Check data types**:
   - Are types appropriate? (e.g., `DECIMAL` for money, not `FLOAT`)
   - Are string lengths reasonable?
   - Are nullable columns intentionally nullable?
   - Are enums used where appropriate?

6. **Check query patterns**:
   - Will common queries require full table scans?
   - Are there N+1 query risks in the relation design?
   - Are partition keys chosen for the expected query patterns? (BigQuery/DW)

## Output Format

```markdown
## Schema Review: <target>

### Summary
- **Issues found**: X critical, Y warnings, Z suggestions
- **Overall**: <healthy | needs attention | significant issues>

### Critical Issues
1. **<Issue>**: <description + fix>

### Warnings
1. **<Issue>**: <description + recommendation>

### Suggestions
1. **<Improvement>**: <description + rationale>

### Naming Inconsistencies
| Current | Suggested | Reason |
|---------|-----------|--------|
| ...     | ...       | ...    |
```

## Constraints

- Respect existing conventions even if they differ from ideal — consistency > perfection
- Flag breaking changes separately from non-breaking suggestions
- Don't suggest normalization changes for intentionally denormalized analytics tables
- Consider the query volume — an unnecessary index on a 100-row table isn't worth flagging
