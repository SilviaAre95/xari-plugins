---
name: sql-optimizer
description: "Analyze and optimize SQL queries — identify performance issues, suggest rewrites, and explain execution plans"
user-invocable: true
argument-hint: "<sql-query-or-file> [dialect: postgres|mysql|bigquery]"
---

# SQL Optimizer

Optimize the SQL for: **$ARGUMENTS**

## Steps

1. **Parse the query** — Read the SQL and understand:
   - What data is being requested
   - Join structure and cardinality
   - Filter conditions and their selectivity
   - Aggregations and groupings
   - Subqueries and CTEs

2. **Identify performance issues**:

   | Issue | Symptom | Fix |
   |-------|---------|-----|
   | Full table scan | No WHERE clause index match | Add index or rewrite filter |
   | SELECT * | Fetching unused columns | Select only needed columns |
   | Correlated subquery | Subquery runs per row | Rewrite as JOIN or CTE |
   | Implicit type cast | Filter on wrong type | Cast explicitly or fix schema |
   | Missing JOIN index | Slow JOIN on unindexed column | Add index on join column |
   | Unnecessary DISTINCT | Masking a join issue | Fix the join instead |
   | ORDER BY + LIMIT without index | Sort on full result set | Add composite index |
   | N+1 in application | Multiple queries in loop | Use JOIN or IN clause |

3. **Rewrite the query** — Produce an optimized version with:
   - Clear CTEs instead of nested subqueries
   - Proper index utilization
   - Minimal data fetched
   - Comments explaining non-obvious choices

4. **Suggest schema changes** if needed:
   - Indexes that would help this query
   - Materialized views for expensive aggregations
   - Partitioning for large table scans

5. **Estimate impact** — Qualitative assessment:
   - "This eliminates a full table scan on a ~1M row table"
   - "Reduces JOIN cardinality from N*M to N"

## Output Format

```markdown
## Query Analysis

### Original Query
```sql
<original>
```

### Issues Found
1. **<Issue>**: <explanation>
2. **<Issue>**: <explanation>

### Optimized Query
```sql
<rewritten query with comments>
```

### Recommended Indexes
```sql
CREATE INDEX idx_name ON table (col1, col2);
```

### Expected Impact
- <Before>: <estimated behavior>
- <After>: <estimated improvement>
```

## Constraints

- Preserve query semantics — the optimized query must return the same results
- Prefer readability over micro-optimization — CTEs over nested subqueries
- Consider write impact of new indexes (don't index write-heavy tables recklessly)
- Be dialect-aware: Postgres, MySQL, and BigQuery have different optimization strategies
- Don't suggest changes that require application-level rewrites unless the SQL alone can't fix it
