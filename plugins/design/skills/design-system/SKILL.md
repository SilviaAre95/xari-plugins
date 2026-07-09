---
name: design-system
description: "Audit or scaffold a design system — tokens, component inventory, Tailwind config, and usage consistency"
user-invocable: true
argument-hint: "<action: audit|scaffold|extend> [focus: colors|typography|spacing|components]"
---

# Design System

Perform the requested design-system action (audit, scaffold, or extend) for: **$ARGUMENTS** (focus defaults to all)

## Audit Mode

1. **Extract current tokens** from `tailwind.config.ts`:
   - Colors (brand, semantic, neutrals)
   - Typography (font families, sizes, weights, line heights)
   - Spacing scale (any custom additions)
   - Border radius, shadows, breakpoints

2. **Inventory component patterns** — Scan the codebase for:
   - Button variants (how many styles exist?)
   - Card/container patterns
   - Form input styles
   - Navigation patterns
   - Modal/dialog implementations

3. **Check consistency**:
   - Are there multiple ways the same pattern is implemented?
   - Are components using theme tokens or hardcoded values?
   - Are there one-off styles that should be tokens?

4. **Report findings**:

```markdown
## Design System Audit

### Tokens
| Category | Defined | Used Consistently | Issues |
|----------|---------|-------------------|--------|
| Colors   | 12      | 8/12              | 4 raw hex values found |
| Typography | 5     | 3/5               | 2 arbitrary sizes |

### Component Inventory
| Pattern | Variants | Consistent | Location |
|---------|----------|------------|----------|
| Button  | 4        | yes/no     | <files>  |

### Recommendations
1. <consolidation opportunity>
```

## Scaffold Mode

Generate a minimal design system:

1. **Tailwind config** with semantic color tokens:
   - `primary`, `secondary`, `accent`, `destructive`
   - `background`, `foreground`, `muted`, `border`
   - Dark mode variants

2. **Base component set**:
   - Button (default, outline, ghost, destructive, sizes)
   - Input (text, with error state)
   - Card (header, content, footer)
   - Badge (variants)

3. **`cn()` utility** — clsx + tailwind-merge helper

## Extend Mode

Add new tokens or components to an existing system:
- Read the current `tailwind.config.ts` and component patterns
- Add the new element following existing conventions
- Update any documentation

## Constraints

- Tailwind CSS only — no CSS-in-JS, no CSS modules
- shadcn/ui patterns are fine if the project uses them
- Don't over-abstract — a design system for a 5-page app needs 5 components, not 50
- Tokens should have semantic names, not palette names (`text-primary` not `text-blue-600`)
