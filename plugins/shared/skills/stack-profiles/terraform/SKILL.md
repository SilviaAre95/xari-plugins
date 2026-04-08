---
name: terraform
description: "Stack context for Terraform/IaC projects — module structure, state management, and GCP/AWS provider conventions"
user-invocable: false
paths: "*.tf,*.tfvars,terraform.lock.hcl,modules/**/*.tf"
---

# Stack Profile: Terraform

This profile is automatically loaded when working in a Terraform project.

## Project Structure

```
environments/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── backend.tf
├── staging/
└── prod/
modules/
├── networking/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── compute/
└── database/
```

## Conventions

### Naming
- Resources: `<provider>_<resource>` with descriptive names
- Variables: snake_case, descriptive (`database_instance_tier`, not `tier`)
- Outputs: match the resource attribute name
- Modules: singular noun (`networking`, not `networks`)

### State Management
- Remote state in GCS bucket or S3 with locking (DynamoDB for AWS)
- One state file per environment
- Never edit state manually — use `terraform state mv/rm`
- State bucket has versioning enabled

### Modules
- Keep modules small and focused (one concern per module)
- All variables have `description` and `type`
- Use `validation` blocks for variable constraints
- Outputs expose only what consumers need
- Pin module versions in `source` attribute

### Security
- No secrets in `.tf` files or `.tfvars`
- Use `sensitive = true` on secret variables and outputs
- IAM: least privilege — don't use `roles/editor` or `roles/owner`
- Enable audit logging on sensitive resources
- Use service accounts, not user accounts, for automation

## Key Patterns

```hcl
# Variables with validation
variable "environment" {
  type        = string
  description = "Deployment environment"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Resource with lifecycle
resource "google_sql_database_instance" "main" {
  name             = "${var.project}-${var.environment}-db"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = var.database_instance_tier
  }

  lifecycle {
    prevent_destroy = true  # Production databases
  }
}

# Data source for existing resources
data "google_project" "current" {}
```

## Workflow

1. `terraform init` — initialize providers and modules
2. `terraform plan -out=plan.tfplan` — always save the plan
3. `terraform apply plan.tfplan` — apply the saved plan
4. Never `terraform apply` without reviewing the plan
5. Use `terraform fmt` and `terraform validate` in CI
