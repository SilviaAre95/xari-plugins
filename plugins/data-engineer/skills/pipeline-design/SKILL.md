---
name: pipeline-design
description: "Design data pipelines — ETL/ELT flows, scheduling, error handling, and monitoring strategy"
user-invocable: true
argument-hint: "<data-source> to <destination> [batch|streaming]"
---

# Pipeline Design

Design a data pipeline for: **$ARGUMENTS**

## Steps

1. **Define the data contract**:
   - Source: what system, format, volume, frequency
   - Destination: what system, expected schema, SLAs
   - Transformation: what changes between source and destination

2. **Choose architecture**:
   - **Batch** — scheduled, processes historical data, good for reports/analytics
   - **Streaming** — real-time, event-driven, good for live dashboards/alerts
   - **Hybrid** — batch for backfill, streaming for incremental

3. **Design the pipeline stages**:

```
[Source] → [Extract] → [Transform] → [Validate] → [Load] → [Destination]
                                          ↓
                                   [Dead Letter Queue]
```

   For each stage:
   - Input/output schema
   - Error handling (retry, skip, dead letter)
   - Idempotency strategy (how to handle re-runs)

4. **Define scheduling & orchestration**:
   - Cron schedule or trigger mechanism
   - Dependencies between pipelines
   - Backfill strategy
   - Tool: Airflow, Prefect, Cloud Scheduler, cron

5. **Monitoring & alerting**:
   - Row counts in vs out (detect data loss)
   - Schema drift detection
   - Freshness checks (is data arriving on time?)
   - Alert channels and escalation

## Output Format

```markdown
## Pipeline: <source> → <destination>

### Overview
- **Type**: batch | streaming | hybrid
- **Frequency**: every X hours | real-time | on trigger
- **Volume**: ~N rows/day, ~X GB/month
- **SLA**: data available within X hours of source update

### Stages

| Stage | Input | Output | Error Strategy |
|-------|-------|--------|---------------|
| Extract | <source format> | raw JSON/CSV | retry 3x, alert |
| Transform | raw | cleaned + typed | skip bad rows → DLQ |
| Validate | cleaned | validated | reject → DLQ |
| Load | validated | <destination table> | upsert, idempotent |

### Schema
<Source and destination schemas with field mappings>

### Error Handling
- **Retries**: <strategy>
- **Dead Letter Queue**: <where bad records go>
- **Alerting**: <when and how>

### Monitoring
- <metric 1>: <threshold + alert>
- <metric 2>: <threshold + alert>
```

## Constraints

- Every pipeline must be idempotent — safe to re-run
- Always include a dead letter queue for unprocessable records
- Never silently drop data — log and alert
- Prefer append + deduplicate over destructive updates
- Include a backfill strategy from day one
