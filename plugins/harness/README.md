# harness

Tiered autonomy + a build-test-fix loop, so development becomes "kick off a workflow and walk away."

## Tiers (switch with Shift+Tab)

| Tier | Permission mode | Behavior |
|------|-----------------|----------|
| explore | `plan` | read/search only |
| build | `acceptEdits` | auto-accept edits + auto-run your allow list |
| ship | `default` | interactive; only hard gates prompt |
| escape | `bypassPermissions` | full auto (floor `deny` still applies) |

## The loop

`/loop-build <task>` arms a `Stop` hook that runs your verify gate
(`.cc-verify`, default `npm run lint && npm run build && npm test`) and won't let
Claude stop until it's green — fixing and retrying up to 5 times, then summarizing.
Read-only tools are auto-approved in every tier so exploration never stalls.

### `/loop-dev <task> [--check-plan]`

Extends `/loop-build` into a full staged dev loop: spec preflight, plan, build,
then **review stages** (`code-review`, `security`, `bugs` by default) each run
as a dispatched subagent against the diff. Its `Stop` hook won't let Claude
finish until `.cc-verify` is green **and** `.cc-dev-reviews-passed` exists —
a failing `.cc-verify` clears the marker, so a broken build forces reviews to
re-run. Otherwise the marker is trust-based: the command instructs the agent
to create it only once reviews are clean and no further edits remain. On success it
pushes the branch and opens a PR (unless `open_pr: false`). Config — graders,
`max_retries`, diff `base`, `open_pr` — lives in `.cc-dev.yaml`. Pass
`--check-plan` to pause after the plan step for your approval before it builds.

## Setup

1. Enable the plugin (it's in the `xari-plugins` marketplace).
2. Run `/harness-init` in each project to create `.cc-verify`, git-ignore loop
   state, scaffold `.cc-dev.yaml`, and seed the project allow list.
3. Add the **permission policy** to your settings — a plugin cannot grant
   permissions. See `docs/reference/permission-policy.md`: the floor (`deny`) and
   hard gates (`ask`) go in `~/.claude/settings.json`.

## State files

**Git-ignored (transient):** `.cc-loop-active` sentinel · `.cc-loop-state` counter · `.cc-loop.log` last gate output · `.cc-loop-dev-active` sentinel · `.cc-loop-dev-state` counter · `.cc-dev-reviews-passed` marker · `.cc-loop-dev.log` last gate output.

**Committed (project config):** `.cc-verify` — the gate command run on every stop attempt; commit it so a fresh clone keeps the right gate and its contents are trusted (they're `eval`'d by the loop gate) · `.cc-dev.yaml` — `/loop-dev` config (graders, max_retries, base, open_pr).
