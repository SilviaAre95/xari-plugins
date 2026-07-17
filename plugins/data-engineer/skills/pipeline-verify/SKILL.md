---
name: pipeline-verify
description: "Verify a data pipeline in a dev environment — run it against a bounded sample and assert schema, counts, idempotency, and clean logs. The data-platform counterpart of driving a web app in a browser."
user-invocable: true
argument-hint: "<pipeline-or-dag-name> [sample description]"
---

# Pipeline Verify

Verify in dev: **$ARGUMENTS**

Unit tests prove functions; this proves the pipeline. Run the real thing end-to-end against a bounded sample and observe what comes out.

## Steps

1. **Bound the input**: pick a sample slice — a fixed date partition, N rows, or a fixture dataset. State exactly what goes in (source, row count, date range) before running. Never run unbounded.

2. **Run the pipeline** end-to-end in the dev environment (local runner, dev project, staging warehouse). Capture logs and runtime.

3. **Assert the output**:
   - **Schema**: output matches the destination contract — column names, types, nullability. Flag any drift.
   - **Row accounting**: rows in vs rows out vs rows rejected must reconcile. `in != out + rejected` means silent loss — that is a failure, not a footnote.
   - **Quality**: null rates and duplicate rates on key columns within expected bounds; spot-check 3–5 records field-by-field against the source.
   - **DLQ**: empty, or every record in it explained.

4. **Prove idempotency**: run the pipeline a second time on the same input. Destination state must be unchanged (same counts, no duplicates). A pipeline that double-loads on re-run fails verification.

5. **Check the logs**: no unexplained errors or warnings; freshness/monitoring hooks fired if configured.

## Output Format

```markdown
## Pipeline verification: <name>

**Input**: <sample description, N rows, partition>
**Runtime**: <duration>

| Check | Result | Detail |
|-------|--------|--------|
| Schema conformance | ✅/❌ | <drift found or "matches contract"> |
| Row accounting | ✅/❌ | in N → out M, rejected K |
| Nulls/dupes on keys | ✅/❌ | <rates vs bounds> |
| Spot-check records | ✅/❌ | <n checked> |
| DLQ | ✅/❌ | <empty / explained> |
| Idempotency (2nd run) | ✅/❌ | <state unchanged?> |
| Logs | ✅/❌ | <clean / findings> |

**Verdict**: PASS / FAIL — <one line>
```

## Constraints

- Never run against production data or a production destination — dev/staging only.
- Always bound the input; an unbounded "test run" is a production run.
- Silent row loss is always FAIL, even when the output "looks right".
- Report the verdict honestly — a FAIL with detail beats a hedged PASS.
