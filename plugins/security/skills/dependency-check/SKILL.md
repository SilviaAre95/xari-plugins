---
name: dependency-check
description: "Audit project dependencies for known vulnerabilities, outdated packages, and unnecessary bloat"
user-invocable: true
argument-hint: "<package-manager: npm|pip|go> [mode: audit|update|cleanup]"
---

# Dependency Check

Check dependencies per: **$ARGUMENTS** (package manager defaults to npm, mode defaults to audit)

## Audit Mode

1. **Check for known vulnerabilities**:
   - Run `npm audit` (or equivalent) and parse results
   - Categorize by severity (critical, high, moderate, low)
   - Check if fixes are available (patch, minor, major version bump)
   - Identify transitive vs direct dependency vulnerabilities

2. **Check for outdated packages**:
   - Compare current versions to latest
   - Flag major version bumps separately (breaking changes)
   - Identify packages that are no longer maintained (no commits in 12+ months)
   - Check if alternatives exist for unmaintained packages

3. **Check for unnecessary dependencies**:
   - Dependencies that are imported but never used
   - Dependencies that duplicate functionality (`lodash` + `underscore`)
   - Dependencies that could be replaced with native APIs (`moment` → `Intl.DateTimeFormat`)
   - Dev dependencies in production bundle

4. **Check supply chain risks**:
   - Packages with very few maintainers
   - Packages with recent ownership transfers
   - Packages with suspicious postinstall scripts
   - Lock file integrity (is `package-lock.json` committed?)

## Update Mode

1. Run audit first
2. Apply safe updates (patch and minor versions)
3. List major version updates separately with breaking change notes
4. Verify build and tests pass after updates

## Cleanup Mode

1. Find unused dependencies
2. Find duplicated functionality
3. Suggest removals with rationale

## Output Format

```markdown
## Dependency Audit: <project>

### Vulnerabilities
| Package | Severity | Current | Fixed In | Direct/Transitive |
|---------|----------|---------|----------|-------------------|
| <pkg>   | critical | 1.2.3   | 1.2.4    | direct            |

### Outdated
| Package | Current | Latest | Type | Breaking Changes |
|---------|---------|--------|------|-----------------|
| <pkg>   | 2.0.0   | 3.1.0  | major | yes — see changelog |

### Cleanup Candidates
| Package | Reason | Replacement |
|---------|--------|-------------|
| moment  | unmaintained, 300KB | date-fns or native Intl |

### Recommended Actions
1. `npm update <pkg>` — fix critical vulnerability
2. `npm uninstall <pkg>` — unused dependency
```

## Constraints

- Never auto-update major versions without reviewing breaking changes
- Flag supply chain risks explicitly
- Check that `package-lock.json` is committed and up to date
- Don't suggest removing dependencies you're not sure are unused — check import references
