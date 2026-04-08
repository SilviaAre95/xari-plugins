---
name: layout-review
description: "Review page layouts for visual hierarchy, spacing consistency, alignment, and responsive behavior"
user-invocable: true
argument-hint: "<page-or-component> [breakpoint: mobile|tablet|desktop|all]"
---

# Layout Review

Review layout for: **$0**

Breakpoint focus: **$1** (default: all)

## Steps

1. **Analyze visual hierarchy**:
   - Is the most important content visually prominent?
   - Do headings follow a logical h1 → h2 → h3 hierarchy?
   - Is there a clear primary action on each screen?
   - Are secondary actions visually subordinate?

2. **Check spacing system**:
   - Is spacing consistent with the Tailwind scale? (4, 8, 12, 16, 24, 32, 48, 64)
   - Are related elements grouped with tighter spacing?
   - Are unrelated sections separated with larger spacing?
   - Is vertical rhythm maintained (consistent line heights and margins)?

3. **Check alignment**:
   - Are elements on a consistent grid?
   - Is text alignment appropriate (left for body, center for short headings/CTAs)?
   - Are form labels aligned consistently (top-aligned preferred)?
   - Do icons align with text baselines?

4. **Check responsive behavior**:
   - **Mobile (< 640px)**: single column, stacked elements, full-width buttons
   - **Tablet (640-1024px)**: 2-column where appropriate, sidebar collapsible
   - **Desktop (> 1024px)**: full layout, sidebar visible, multi-column grids
   - Do elements reflow gracefully or just shrink?
   - Are touch targets ≥ 44px on mobile?
   - Does horizontal scrolling occur unintentionally?

5. **Check content overflow**:
   - Long text: does it truncate, wrap, or break layout?
   - Long names/emails: `truncate` class or `break-words`?
   - Empty states: what does the layout look like with no data?
   - Loading states: do skeletons match the content dimensions?

## Output Format

```markdown
## Layout Review: <target>

### Hierarchy
- **Score**: clear | mostly clear | unclear
- <issues>

### Spacing
- **Consistency**: consistent | mostly | inconsistent
- <issues with specific classes to fix>

### Responsive
| Breakpoint | Status | Issues |
|------------|--------|--------|
| Mobile     | pass/fail | <issues> |
| Tablet     | pass/fail | <issues> |
| Desktop    | pass/fail | <issues> |

### Fixes
1. **<element>**: change `<current classes>` → `<fixed classes>`
```

## Constraints

- Provide specific Tailwind class changes, not abstract advice
- Review against the existing design system/theme, not arbitrary preferences
- Focus on layout structure, not content or copy
- If no design spec exists, apply standard web layout conventions
