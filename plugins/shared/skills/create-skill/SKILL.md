---
name: create-skill
description: "Generate a new SKILL.md file with proper frontmatter, structure, and $ARGUMENTS support"
user-invocable: true
argument-hint: "<skill-name> <plugin-name> [description]"
---

# Create a New Skill

Create a new skill called `$0` in the `$1` plugin.

## Instructions

1. Create the directory: `plugins/$1/skills/$0/`
2. Create `plugins/$1/skills/$0/SKILL.md` using the template below
3. If a description was provided, use it: `$2`

## SKILL.md Template

Use this exact structure for the new skill file:

```markdown
---
name: <skill-name>
description: "<One line: what it does and when Claude should use it. Max 250 chars.>"
user-invocable: true
argument-hint: "<placeholder args the user passes, e.g. [target] [options]>"
---

# <Skill Title>

<Clear, imperative instructions for Claude. Write as if briefing a senior engineer.>

## When to use

<1-3 bullet points describing trigger conditions>

## Inputs

- `$ARGUMENTS` — full argument string from the user
- `$0` — first argument (usually the target)
- `$1` — second argument (usually an option or modifier)

## Steps

1. <Step one>
2. <Step two>
3. <Step three>

## Output format

<What the skill should produce: code, markdown doc, structured analysis, etc.>

## Constraints

- <Guard rails, things to avoid, scope limits>
```

## Frontmatter Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Kebab-case identifier |
| `description` | Yes | When Claude should invoke this (max 250 chars) |
| `user-invocable` | No | `true` (default) = user can call via `/skill-name` |
| `disable-model-invocation` | No | `true` = only user can trigger, Claude won't auto-invoke |
| `argument-hint` | No | Shown in autocomplete, e.g. `[file] [--verbose]` |
| `allowed-tools` | No | Space-separated tool names Claude can use without prompts |
| `model` | No | Force a specific model: `sonnet`, `opus`, `haiku` |
| `effort` | No | `low`, `medium`, `high`, `max` |
| `context` | No | `fork` = run in isolated subagent |
| `paths` | No | Glob patterns for auto-loading |

## Tips

- Keep descriptions under 250 characters — they're used for skill matching
- Use `$ARGUMENTS` for dynamic input; `$0`, `$1` for positional args
- Use `disable-model-invocation: true` for destructive or opinionated skills
- Add a `## Constraints` section to prevent scope creep
- Reference files with `${CLAUDE_SKILL_DIR}` for co-located templates
