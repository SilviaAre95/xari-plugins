---
description: Arm the build-test-fix loop, then implement a task that runs to green
argument-hint: <task description>
allowed-tools: Bash(touch:*), Bash(echo:*)
---

Arm the loop for this project:

!`touch .cc-loop-active && echo 0 > .cc-loop-state && echo "loop armed"`

The build-test-fix loop is now **ARMED**. Implement the task below. When you think you are done, the `Stop` hook runs this project's verify gate (`.cc-verify` if present, else `npm run lint && npm run build && npm test`):

- Gate **passes** → you're allowed to finish.
- Gate **fails** → you'll be told the failures; fix them and continue. Do not stop until green.
- After **5** failed attempts a circuit breaker trips: stop fixing and summarize what's still broken.

Work in the `acceptEdits` tier (Shift+Tab) so edits and the allowlist run without prompts.

Task: $ARGUMENTS
