---
name: generic
description: "Generic stack context for projects without a specific stack profile — language-agnostic conventions"
user-invocable: false
---

# Stack Profile: Generic

Fallback conventions for projects that don't match a specific stack profile.

## Universal Conventions

### Code Organization
- Group by feature/domain, not by type (prefer `features/auth/` over `controllers/`)
- Keep public API surface small — don't export internals
- Colocate related files (test next to source, types next to implementation)

### Error Handling
- Handle errors explicitly — no empty catches, no silent failures
- Distinguish expected errors (validation, not found) from unexpected (null pointer, network)
- Log enough context to debug without exposing sensitive data

### Testing
- Unit tests for business logic
- Integration tests for component boundaries
- Aim for confidence, not coverage percentage
- Test behavior, not implementation

### Git
- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- One logical change per commit
- Commit message explains why, diff shows what
- Branch names: `feat/short-description`, `fix/short-description`

### Security
- Never commit secrets (use `.env` + `.gitignore`)
- Validate input at system boundaries
- Use parameterized queries (never string concatenation for SQL)
- Apply least privilege for all service accounts and API keys

### Documentation
- README with: what, why, how to run, how to deploy
- `.env.example` for all environment variables
- ADRs for significant technical decisions
- Inline comments only for non-obvious logic

### Dependencies
- Pin versions in lock files
- Review dependency updates for breaking changes
- Prefer well-maintained packages with active communities
- Remove unused dependencies

### Performance
- Measure before optimizing
- Profile bottlenecks, don't guess
- Cache at the right layer (CDN > app cache > DB query cache)
- Prefer pagination over loading everything
