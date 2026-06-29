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

## Setup

1. Enable the plugin (it's in the `xari-plugins` marketplace).
2. Run `/harness-init` in each project to create `.cc-verify`, git-ignore loop
   state, and seed the project allow list.
3. Add the **permission policy** to your settings — a plugin cannot grant
   permissions. See `docs/reference/permission-policy.md`: the floor (`deny`) and
   hard gates (`ask`) go in `~/.claude/settings.json`.

## State files (git-ignored)

`.cc-loop-active` sentinel · `.cc-loop-state` counter · `.cc-verify` gate override · `.cc-loop.log` last gate output.
