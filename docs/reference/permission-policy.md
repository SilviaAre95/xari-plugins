# Harness Permission Policy (canonical)

A plugin cannot grant permissions — these go in `settings.json`. Precedence: `deny` > `ask` > `allow`.

## Universal floor — `~/.claude/settings.json` → `permissions.deny`
Applies in every tier, including `bypassPermissions`.

```json
"deny": [
  "Bash(sudo *)",
  "Bash(rm -rf *)",
  "Bash(rm -rf /*)",
  "Bash(rm -rf ~/*)",
  "Write(.git/**)",
  "Write(.env)",
  "Write(.env.*)"
]
```

## Hard gates — `permissions.ask` (always prompt, even in build/bypass)

```json
"ask": [
  "Bash(railway up*)",
  "Bash(vercel*--prod*)",
  "Bash(vercel --prod*)",
  "Read(.env)",
  "Read(.env.*)",
  "Bash(railway variables set*)"
]
```
External-send MCP tools (email/comment posting) are gated by omission from `allow`: in the `ship`/`default` tier they prompt naturally.

## Generous allow — project `.claude/settings.json` → `permissions.allow`

```json
"allow": [
  "Bash(npm run *)", "Bash(npm install*)", "Bash(npm test*)",
  "Bash(git add *)", "Bash(git commit *)", "Bash(git status*)",
  "Bash(git diff*)", "Bash(git log*)", "Bash(git push *)",
  "Bash(railway status*)", "Bash(railway logs*)", "Bash(railway variables)",
  "Bash(vercel ls*)", "Bash(vercel inspect*)",
  "Read(*)", "Grep(*)", "Glob(*)"
]
```
