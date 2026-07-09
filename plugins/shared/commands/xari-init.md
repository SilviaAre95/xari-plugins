---
description: Bootstrap this repo as a xari workspace — plugin fleet, CLAUDE.md header, harness handoff
allowed-tools: Read, Edit, Write, Bash(cat:*), Bash(ls:*), Bash(jq:*)
---

Turn the current repo into a xari-configured workspace. Make each change visible, merge with existing files, and never overwrite without asking.

1. **Detect the stack** — read `package.json`, `pyproject.toml`, `go.mod`, lockfiles, and framework configs. Summarize the detected stack in one line and confirm with the user.

2. **Plugin fleet** — merge into `.claude/settings.json` (create it if missing; preserve every existing key):
   ```json
   {
     "extraKnownMarketplaces": {
       "xari-plugins": { "source": { "source": "github", "repo": "SilviaAre95/xari-plugins" } }
     },
     "enabledPlugins": {
       "shared@xari-plugins": true,
       "harness@xari-plugins": true,
       "security@xari-plugins": true,
       "test-builder@xari-plugins": true,
       "feature-bank@xari-plugins": true,
       "superpowers@claude-plugins-official": true
     }
   }
   ```
   Then add stack-specific plugins: `frontend-dev` + `ui-designer` + `web-tester` for web frontends, `backend-dev` for API/DB code, `data-engineer` for pipelines, `devops` when there is CI/infra config. Ask before enabling anything you are unsure about.

3. **CLAUDE.md header** — if the repo has no `CLAUDE.md`, create one from this template; if it exists, offer to prepend the missing sections:
   ```markdown
   # <repo-name>

   <one-line purpose>

   ## Xari config
   - **Stack**: <detected stack, one line>
   - **Vault note**: <e.g. 02-Projects/<repo>.md — relative name only>
   - **Linear project**: <project name or "none">
   - **Verify**: <the green-gate command, same as .cc-verify>
   - **MCPs used**: <e.g. Supabase (project X), Stripe test mode, or "none">

   ## Constraints
   - <hard rules: "German-first UI", "never touch prod DB", ...>
   ```
   Fill what you detected; use `<ask user>` placeholders for the rest and ask for them in one batch. NEVER put absolute personal paths (vault location, home dirs) in this file — it is committed and shared; personal paths belong in the user's global `~/.claude/CLAUDE.md`.

4. **Harness handoff** — if `.cc-verify` does not exist, tell the user to run `/harness-init` to set up the verify gate and loop config, or offer to run it now.

## Constraints

- Merge JSON with existing content — replacing `.claude/settings.json` wholesale is forbidden.
- Declare only stable, unguessable facts in CLAUDE.md (pointers, commands, constraints). Do not inventory code structure — it rots.
- Report a final summary table: file → created/updated/skipped.
