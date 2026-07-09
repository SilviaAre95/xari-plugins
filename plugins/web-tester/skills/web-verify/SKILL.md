---
name: web-verify
description: "Verify a live web app end-to-end — drive the critical user flow in a real browser, assert console and network are clean"
user-invocable: true
argument-hint: "<url-or-flow> [e.g. https://app.example.com login-flow]"
---

# Web Verify

Verify the live app or flow: **$ARGUMENTS**

Pick the browser tool that is available, in this order: Playwright MCP tools (from this plugin), Claude-in-Chrome tools, then `curl` as a last-resort smoke check (status codes only — say so in the report).

## Steps

1. **Define the critical path** — from the repo's CLAUDE.md, feature bank, or the user's argument, list the 3–7 steps a real user takes (e.g. load page → log in → perform core action → see result). Confirm with the user only if the flow is ambiguous.

2. **Drive the flow** — execute each step in the browser. At every step capture:
   - Navigation success (no error page, expected element visible)
   - Console: zero `error`-level messages (warnings: note, don't fail)
   - Network: no failed requests (4xx on app's own API, 5xx anywhere, CORS failures)

3. **Verify the result state** — assert the flow's end condition concretely (record created, redirect landed, UI reflects the change), not just "no errors happened".

4. **Screenshot evidence** — capture the final state and any failing step.

## Output Format

| Step | Action | Result | Console | Network |
|------|--------|--------|---------|---------|
| 1 | Load / | ✅ | clean | clean |
| 2 | Login | ❌ timeout | 1 error | POST /api/auth 500 |

Then: verdict (`PASS` / `FAIL`), the failing step's console/network detail verbatim, and the single most likely cause with the file to look at.

## Constraints

- Test against the URL the user gives; never assume localhost is the deploy target.
- Read-only flows by default — do not execute destructive or paid actions (delete, purchase, send) without explicit confirmation.
- Never enter real credentials from memory or files; ask the user for test credentials.
- Report what you observed, not what should happen — if a step could not be verified, mark it `UNVERIFIED`, not `PASS`.
