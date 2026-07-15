---
description: Set up the harness in this project — permission policy, verify gate, gitignore
allowed-tools: Read, Edit, Write, Bash(cat:*), Bash(ls:*)
---

Set up the harness in the current project. Make each change visible and ask before overwriting existing values.

1. **Verify gate** — if `.cc-verify` does not exist, create it containing the project's green-gate command. Default for a Node/npm repo:
   ```
   npm run lint && npm run build && npm test
   ```
   If the project is not Node, infer the correct command (e.g. `pytest`, `cargo test`) and confirm with the user.

2. **Git-ignore loop state** — ensure `.gitignore` contains these lines (append if missing):
   ```
   .cc-loop-active
   .cc-loop-state
   .cc-loop.log
   .cc-loop-dev-active
   .cc-loop-dev-state
   .cc-dev-reviews-passed
   .cc-loop-dev.log
   .cc-deploy-active
   .cc-deploy-state
   .cc-deploy.log
   .cc-loop-gate.lock*
   ```
   `.cc-verify` is project config (not transient state) and **should be committed** so a fresh clone retains the correct gate command. Do NOT add it to `.gitignore`.

3. **Dev loop config** — if `.cc-dev.yaml` does not exist at the project root, copy it from the plugin's `templates/.cc-dev.yaml`. This is committed config (like `.cc-verify`) — do NOT add it to `.gitignore`.

4. **Deploy loop config** — if `.cc-deploy.yaml` does not exist at the project root, generate it by **detecting where this repo deploys**, then confirm the detected target with the user before writing:
   - **Railway** — `railway.json`, `railway.toml`, or a linked Railway project present → copy `templates/.cc-deploy.railway.yaml`.
   - **Vercel** — `vercel.json` or a `.vercel/` directory present → copy `templates/.cc-deploy.vercel.yaml`.
   - **Neither detected** → copy the neutral `templates/.cc-deploy.yaml`. Its `deploy`/`verify`/`rollback` commands are guarded placeholders that exit non-zero on purpose, so the loop refuses to run until the user fills them in. Tell the user the deploy loop cannot run until they set these for wherever the repo actually deploys.

   Whichever variant you copy, land it as `.cc-deploy.yaml` at the project root and replace its example domain/commands with the project's real ones where you can infer them. This is committed config (like `.cc-verify`) — do NOT add it to `.gitignore`.

5. **Project allow list** — merge the `permissions.allow` block from the harness permission policy into this project's `.claude/settings.json` (create the file if absent). Do NOT duplicate entries already present. The canonical block is:
   ```json
   "allow": [
     "Bash(npm run *)", "Bash(npm install*)", "Bash(npm test*)",
     "Bash(git add *)", "Bash(git commit *)", "Bash(git status*)",
     "Bash(git diff*)", "Bash(git log*)", "Bash(git push *)",
     "Read(*)", "Grep(*)", "Glob(*)"
   ]
   ```
   Add project-specific deploy-tool reads (e.g. `Bash(railway status*)`) only if that tooling is present.

6. **Remind the user** that the universal floor (`deny`) and hard gates (`ask`) belong in `~/.claude/settings.json` (global), not the project — point them to `docs/reference/permission-policy.md` in the wayworks repo, and note that this command intentionally does not edit global settings.

Report a summary of exactly which files you changed.
