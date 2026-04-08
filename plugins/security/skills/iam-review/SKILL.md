---
name: iam-review
description: "Review identity and access management — auth flows, RBAC, session management, and permission boundaries"
user-invocable: true
argument-hint: "<scope: auth-flow|rbac|sessions|api-keys|all>"
---

# IAM Review

Review scope: **$ARGUMENTS**

## Steps

### 1. Authentication Flow
- How do users authenticate? (email/password, OAuth, magic link, API key)
- Is the auth library properly configured? (NextAuth, Passport, custom)
- Is password hashing using bcrypt/argon2 with proper cost factor?
- Is there rate limiting on auth endpoints? (login, register, password reset)
- Are password reset tokens single-use and time-limited?
- Is MFA available for sensitive operations?

### 2. Session Management
- Where are sessions stored? (JWT, database, Redis)
- Are cookies configured securely?
  - `httpOnly: true` (prevents XSS token theft)
  - `secure: true` (HTTPS only)
  - `sameSite: 'lax'` or `'strict'` (CSRF protection)
- What's the session lifetime? (should be hours, not weeks)
- Can users invalidate sessions? (logout, revoke all sessions)
- Is there session fixation protection?

### 3. Authorization (RBAC)
- Are roles well-defined and documented?
- Is authorization checked at every protected endpoint (not just the UI)?
- Are there IDOR vulnerabilities? (user A accessing user B's resource by changing ID)
- Is there a consistent authorization middleware/pattern?
- Are admin endpoints properly protected?
- Is the principle of least privilege applied?

### 4. API Key Management
- Are API keys hashed in the database (not stored in plain text)?
- Can keys be rotated without downtime?
- Do keys have scoped permissions (not full access)?
- Are keys transmitted securely (header, not URL query param)?
- Is there key expiration?

### 5. Token Security
- JWTs: is the algorithm enforced (not `alg: none`)?
- JWTs: is the secret strong and rotatable?
- JWTs: are claims validated (exp, iss, aud)?
- Refresh tokens: stored securely, rotated on use?
- CSRF tokens: present for state-changing operations?

## Output Format

```markdown
## IAM Review: <scope>

### Risk Summary
| Area | Risk Level | Key Issue |
|------|-----------|-----------|
| Auth flow | low/medium/high | <summary> |
| Sessions | low/medium/high | <summary> |
| RBAC | low/medium/high | <summary> |

### Critical Findings
1. **<finding>**: <risk + fix>

### Recommendations
1. **<recommendation>**: <rationale>

### Auth Flow Diagram
```
[Client] → POST /auth/login (email, password)
         ← Set-Cookie: session=<token> (httpOnly, secure, sameSite)
         → GET /api/resource (Cookie: session=<token>)
         ← 200 OK (authorized) | 403 Forbidden (wrong role)
```
```

## Constraints

- Check the actual implementation, not just the auth library documentation
- IDOR checks are critical — verify that every data access filters by the authenticated user
- Don't recommend MFA for every app — match security level to risk
- Focus on the most likely attack vectors for this type of application
