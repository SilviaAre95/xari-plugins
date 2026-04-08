---
name: python-gcp
description: "Stack context for Python + GCP projects — FastAPI/Flask, BigQuery, Cloud Run, Pub/Sub, and GCP conventions"
user-invocable: false
paths: "requirements.txt,pyproject.toml,Dockerfile,cloudbuild.yaml,*.py"
---

# Stack Profile: Python + GCP

This profile is automatically loaded when working in a Python project targeting GCP.

## Architecture Conventions

- **FastAPI** or **Flask** for HTTP services
- **SQLAlchemy** or **Prisma** for database access
- **Pydantic** for data validation and serialization
- **pytest** for testing
- **Poetry** or **pip** for dependency management
- **Docker** for containerization, **Cloud Run** for deployment

## Project Structure

```
src/
├── api/              # Route handlers
│   ├── __init__.py
│   └── routes/
├── core/             # Config, settings, dependencies
├── models/           # SQLAlchemy/Pydantic models
├── services/         # Business logic
├── repositories/     # Database access layer
└── main.py           # Application entrypoint
tests/
├── unit/
├── integration/
└── conftest.py
```

## GCP Services

- **Cloud Run**: stateless HTTP services, auto-scaling to zero
- **BigQuery**: analytics warehouse, columnar storage, SQL interface
- **Cloud SQL**: managed PostgreSQL for transactional data
- **Pub/Sub**: async messaging between services
- **Cloud Storage**: file/object storage (GCS)
- **Secret Manager**: secrets, not environment variables for sensitive values
- **Cloud Build**: CI/CD with `cloudbuild.yaml`
- **Cloud Scheduler**: cron jobs triggering Cloud Run or Pub/Sub

## Key Patterns

- Use Pydantic `BaseSettings` for environment variable management
- Structured logging with `google-cloud-logging` or `structlog`
- Health check endpoint at `/health` or `/`
- Dependency injection with FastAPI's `Depends()`
- Async where beneficial (I/O-bound operations), sync is fine for CPU-bound

## BigQuery Conventions

- Use `STRUCT` and `ARRAY` types for nested data
- Partition tables by date (`_PARTITIONTIME` or custom field)
- Cluster by frequently filtered columns
- Use `MERGE` for upserts, not `DELETE` + `INSERT`
- Cost control: always use `WHERE` on partition column

## Deployment

- `Dockerfile` with multi-stage build
- `cloudbuild.yaml` for CI/CD pipeline
- Environment-specific configs via Secret Manager
- Cloud Run service with min-instances=0 (cost), max-instances for load
