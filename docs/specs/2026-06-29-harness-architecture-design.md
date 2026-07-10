# Harness Architecture — Tiered Autonomy + Build-Test-Fix Loop

**Date:** 2026-06-29
**Status:** Approved (design)
**Author:** Silvia Arellano
**Repo:** wayworks

## Problem

Development today is: start chat → target something → brainstorm/spec/implement → subagent-driven kickoff → a long sequence of "yes, yes, no, yes" permission clicks. When present, this is fast. When absent, it stalls — the work is blocked on a human clicking approve.

Goal: make development feel like *kicking off an AI workflow* that runs uninterrupted, with **tiers of authorization** so safe work flows freely while genuinely risky actions still stop for a human. Plus a **build-test-fix loop** that iterates to a green tree on its own.

The system must be **reusable across all projects** and **public-safe** (it ships through the `wayworks` marketplace).

## Decisions (locked during brainstorming)

| Decision | Choice |
|----------|--------|
| Autonomy model | **Tiered by workflow**: explore / build / ship |
| Hard gates (always prompt) | Production deploys · Secrets & env files · External sends |
| Destructive git/fs | **Not** gated by user choice. Only universal catastrophic denies kept (`rm -rf *`, `sudo *`). Force-push / hard-reset auto-run in build tier — deliberate. |
| Execution surface | Interactive TUI, tuned to almost never stop |
| Tier mechanism | **Native permission modes** via Shift+Tab (Approach A) |
| Loop mechanism | **`Stop` hook** gate, opt-in per task |
| Green gate | `npm run lint && npm run build && npm test` (per-project configurable; crema-connect = these three) |
| Circuit breaker | Stop after **5** failed attempts, then summarize what's stuck |

## Key Constraint That Shapes Placement

A Claude Code plugin can ship **hooks, commands, agents, skills** — but it **cannot** ship permission grants (`allow`/`ask`/`deny`). Permissions are a trust boundary that lives only in `settings.json` (user / project / local); a plugin silently granting permissions would be a security hole.

Therefore the harness splits into two homes:

| Piece | Distributable via plugin? | Home |
|-------|---------------------------|------|
| `/loop-build` command | ✅ | `harness` plugin |
| Stop-hook loop script | ✅ | `harness` plugin |
| PreToolUse auto-approve-reads hook | ✅ | `harness` plugin |
| `/harness-init` (writes settings *with approval*) | ✅ | `harness` plugin |
| Permission policy (floor + allow + ask gates) | ❌ trust boundary | `settings.json` (global + per-project) |

The plugin legitimately bridges the permission gap via `/harness-init`, which **edits `settings.json` interactively (with user approval)** rather than granting silently.

## Architecture — Five Components

### 1. Policy floor — committed, applies in *every* tier (even bypass)
Lives in `~/.claude/settings.json` (`permissions.deny`). `deny` outranks everything; nothing crosses it.

Fixes to current state:
- The global `allowedCommands` array is a **no-op** (not a real settings key) — its intent moves into real `permissions.allow` (component 3).
- Current deny patterns are regex-shaped (`Bash(rm -rf /.*)`) and mis-match. Claude Code uses prefix/glob matching, not regex.

Corrected floor (illustrative):
```jsonc
"deny": [
  "Bash(sudo *)",
  "Bash(rm -rf *)",
  "Bash(rm -rf /*)",
  "Write(.git/**)",
  "Write(.env)",
  "Write(.env.*)"
]
```

### 2. Hard gates → `permissions.ask` (always prompt, even in build/bypass)
`ask` outranks `allow`, so these prompt regardless of tier. The three non-negotiables:
```jsonc
"ask": [
  "Bash(railway up*)",          // prod deploy
  "Bash(vercel * --prod*)",     // prod deploy
  "Bash(vercel --prod*)",
  "Read(.env)",                 // secrets
  "Read(.env.*)",
  "Bash(railway variables set*)"
  // external sends (Resend / comment-posting MCP tools) — gated by tool name where applicable
]
```
> Note: MCP "external send" tools (email, comment posting) are gated by leaving them out of `allow`; in `default`/ship tier they prompt naturally. Where an explicit pattern exists, it is added to `ask`.

### 3. Generous `allow` — the tedium-killer
Committed to each **project's** `.claude/settings.json` (so it travels via git, unlike the current git-ignored `settings.local.json`). Reads/searches/builds/tests/lint/local-git/read-only-railway-vercel.

```jsonc
"allow": [
  "Bash(npm run *)", "Bash(npm install*)", "Bash(npm test*)",
  "Bash(git add *)", "Bash(git commit *)", "Bash(git status*)",
  "Bash(git diff*)", "Bash(git push *)", "Bash(git log*)",
  "Bash(railway status*)", "Bash(railway logs*)", "Bash(railway variables)",
  "Bash(vercel ls*)", "Bash(vercel inspect*)",
  "Read(*)", "Grep(*)", "Glob(*)"
]
```
Universal-safe entries (reads, greps, local git) can also live in `~/.claude/settings.json`.

### 4. Tiers via native permission modes (Shift+Tab)
No custom files for switching — the four built-in modes map onto the tiers:

| Tier | Mode | Behavior |
|------|------|----------|
| explore | `plan` | Read/search freely; cannot edit or run side-effecting commands |
| build | `acceptEdits` | Auto-accepts edits **and** auto-runs the `allow` list (the "yes yes yes" killer) |
| ship | `default` | Interactive; only the hard gates and unlisted ops prompt |
| escape hatch | `bypassPermissions` | Full auto for true walk-away (floor `deny` still applies) |

One supporting hook (component 5b) auto-approves read-only ops in *every* tier so exploration never stalls.

### 5. The build-test-fix loop — `Stop` hook (opt-in per task)

**5a. Loop gate (`Stop` hook).**
Fires when Claude tries to end its turn. Behavior:
1. If sentinel `.cc-loop-active` is absent in the project → allow stop (loop is opt-in; casual chats/edits are never hijacked).
2. If `stop_hook_active` is already set → allow stop (prevents recursive re-entry).
3. Read the gate command from per-project config (`.cc-verify` file, fallback to `npm run lint && npm run build && npm test`).
4. Run the gate.
   - Exit 0 → remove sentinel, allow stop (truly green). ✅
   - Exit ≠0 → increment attempt counter in state file. If attempts ≥ 5 → remove sentinel, allow stop, emit summary of what is still failing. Else → block stop, return failure output so Claude fixes and continues.

State files (in project root or a scratch dir, git-ignored):
- `.cc-loop-active` — sentinel; presence = loop armed.
- `.cc-loop-state` — attempt counter.
- `.cc-verify` — optional per-project gate command override.

**5b. Auto-approve reads (`PreToolUse` hook).**
For read-only tools (`Read`, `Grep`, `Glob`, and known read-only Bash like `cat`/`ls`/`git status`), return approve so exploration never prompts in any tier.

**Kickoff:** `/loop-build <task>` writes `.cc-loop-active`, resets the counter, and frames the task ("implement X; the loop will drive build-test-fix to green"). Green or breaker disarms it.

## Plugin Structure (`plugins/harness`)

```
plugins/harness/
  .claude-plugin/plugin.json
  commands/
    loop-build.md          # arms sentinel + frames task
    harness-init.md         # writes recommended permission block into a project's settings.json (with approval) + creates .cc-verify
  hooks/
    hooks.json              # registers Stop + PreToolUse hooks
    scripts/
      loop-gate.sh          # the build-test-fix Stop hook (uses ${CLAUDE_PLUGIN_ROOT})
      auto-approve-reads.sh # PreToolUse approve read-only ops
  README.md                 # docs + the permission policy users must add (since the plugin can't grant it)
```
Registered in `.claude-plugin/marketplace.json` (new entry: `harness`, category `workflow`/`meta`).

## How It Feels Day to Day

```
explore:  Shift+Tab → plan.         "map the matching service"   → never stops, read-only
build:    Shift+Tab → acceptEdits.  /loop-build "add X"          → edits+tests+fixes until green, then done
ship:     Shift+Tab → default.      "deploy to prod"             → runs free BUT pauses at the 3 hard gates
```

## Error Handling & Safety

- **Loop runaway** → circuit breaker (5 attempts) + `stop_hook_active` guard + sentinel opt-in.
- **Sentinel left armed** → harmless; next green gate removes it. `/harness-init` documents manual removal.
- **Plugin can't grant perms** → `/harness-init` edits settings with explicit approval; nothing silent.
- **Public-safe** → no secrets, no machine-specific paths in committed files; README examples are generic.
- **Floor is absolute** → `deny` applies even in `bypassPermissions`.

## Testing Strategy

- **loop-gate.sh** — unit test the decision table: no sentinel → allow; `stop_hook_active` → allow; gate pass → allow + sentinel removed; gate fail < 5 → block; gate fail ≥ 5 → allow + summary. Drive via fixture env/JSON on stdin.
- **auto-approve-reads.sh** — read-only tool → approve; write/exec tool → no decision (defer to normal flow).
- **End-to-end** — in a scratch repo: `/loop-build` with a deliberately failing test, confirm it iterates then breaks at 5; fix the test, confirm it reaches green and disarms.
- **Permission policy** — verify `deny` > `ask` > `allow` precedence with representative patterns (prod deploy prompts even when `npm run *` is allowed).

## Out of Scope (YAGNI)

- Named launcher profiles (Approach B) and hook-driven dynamic per-path policy (Approach C).
- Headless/background and scheduled execution surfaces — design targets interactive TUI; revisit later if desired.
- Time/token budget breaker — attempt-count breaker only for now.

## Rollout

1. Build `harness` plugin in this repo (branch `feat/harness-plugin`).
2. Fix global `~/.claude/settings.json` (remove dead `allowedCommands`, correct deny patterns, add universal allow/ask).
3. Run `/harness-init` in crema-connect to seed its committed `.claude/settings.json` + `.cc-verify`.
4. Bump marketplace version; verify install from cache.
