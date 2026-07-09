---
name: code-audit
description: "Security audit of application code — OWASP Top 10, injection vectors, auth flaws, data exposure"
user-invocable: true
argument-hint: "<file-or-directory> [focus: auth|injection|data|all]"
---

# Security Code Audit

Audit: **$ARGUMENTS** (focus defaults to all)

## Steps

### 1. Injection Vulnerabilities
- **SQL Injection**: raw SQL with string concatenation/interpolation? (Prisma's parameterized queries are safe; raw queries are not)
- **XSS**: user input rendered as HTML without sanitization? `dangerouslySetInnerHTML`?
- **Command Injection**: user input passed to `exec`, `spawn`, `eval`?
- **Path Traversal**: user input in file paths without sanitization? (`../../../etc/passwd`)
- **SSRF**: user-controlled URLs in server-side fetch/requests?

### 2. Authentication & Authorization
- Are all protected routes checking auth?
- Is session management secure (httpOnly, secure, sameSite cookies)?
- Are passwords hashed with bcrypt/argon2 (not MD5/SHA)?
- Is there rate limiting on login endpoints?
- Are JWTs validated properly (algorithm, expiry, issuer)?
- Is there proper RBAC — not just "is authenticated" but "has permission"?

### 3. Data Exposure
- Are API responses leaking sensitive fields (password hash, internal IDs, PII)?
- Are error messages exposing internal details (stack traces, SQL queries)?
- Are logs capturing sensitive data (passwords, tokens, credit cards)?
- Is PII encrypted at rest?
- Are database queries returning `SELECT *` instead of specific fields?

### 4. Configuration & Secrets
- Are secrets in environment variables (not hardcoded)?
- Is `.env` in `.gitignore`?
- Are there any API keys, tokens, or passwords in the codebase?
- Is CORS configured restrictively (not `*`)?
- Are security headers set (CSP, X-Frame-Options, HSTS)?

### 5. Dependencies
- Are there known vulnerable dependencies? (`npm audit`)
- Are dependencies pinned to specific versions?
- Are there unnecessary dependencies with broad system access?

## Output Format

```markdown
## Security Audit: <target>

### Risk Summary
- **Critical**: X (exploit possible)
- **High**: Y (vulnerability exists, exploit requires effort)
- **Medium**: Z (defense-in-depth gap)
- **Low**: W (hardening opportunity)

### Critical Findings
1. **<vulnerability type>** — <file:line>
   - **Risk**: <what an attacker can do>
   - **Fix**: <specific code change>
   - **Verify**: <how to test the fix>

### High Findings
...

### Hardening Recommendations
1. <recommendation>
```

## Constraints

- Prioritize by exploitability, not theoretical severity
- Provide specific fixes with code, not just "sanitize input"
- Check the actual data flow, not just pattern matching
- Don't flag framework-handled security (e.g., Prisma's SQL parameterization)
- If you find a critical vulnerability, flag it clearly at the top
