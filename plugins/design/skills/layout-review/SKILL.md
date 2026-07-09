---
name: layout-review
description: "Review page layouts for visual hierarchy, spacing, alignment, and responsive behavior across breakpoints — includes touch targets and mobile-first checks"
user-invocable: true
argument-hint: "<page-or-component> [breakpoint: mobile|tablet|desktop|all]"
---

# Layout Review

Review layout and responsive behavior for: **$ARGUMENTS** (breakpoint focus defaults to all)

## Steps

1. **Analyze visual hierarchy**:
   - Is the most important content visually prominent?
   - Do headings follow a logical h1 → h2 → h3 hierarchy?
   - Is there a clear primary action on each screen, with secondary actions visually subordinate?

2. **Check spacing and alignment**:
   - Spacing consistent with the Tailwind scale (4, 8, 12, 16, 24, 32, 48, 64)?
   - Related elements grouped tighter; unrelated sections separated wider; vertical rhythm maintained
   - Consistent grid; left-aligned body text; top-aligned form labels; icons on text baselines

3. **Check responsive behavior (mobile-first)**:
   - Base styles are the mobile layout; `sm:`/`md:`/`lg:`/`xl:` add complexity upward — flag desktop-first patterns (e.g. `flex-row` base with `max-sm:flex-col`)
   - Build a breakpoint matrix for each layout-affecting component (nav, grids, sidebars): behavior at base/sm/md/lg/xl
   - Common failures: horizontal overflow on mobile, fixed image dimensions (`w-[500px]` → `w-full max-w-lg`), wide tables without `overflow-x-auto`, modals not full-screen on mobile, missing mobile nav

4. **Check touch targets and containers**:
   - Interactive elements ≥ 44×44px on mobile with adequate spacing; hover-only interactions have touch alternatives
   - `max-w-*` on main content; `px-4` / `container mx-auto` horizontal padding; no uncomfortable stretch on ultra-wide

5. **Check content overflow states**:
   - Long text: `truncate` or `break-words`, not broken layout
   - Empty states and loading skeletons match content dimensions

## Output Format

```markdown
## Layout Review: <target>

### Hierarchy — clear | mostly clear | unclear
- <issues>

### Spacing & Alignment — consistent | mostly | inconsistent
- <issues with specific classes to fix>

### Responsive Matrix
| Component | base | sm | md | lg | xl | Issues |
|-----------|------|----|----|----|----|--------|

### Touch Target Violations
1. **<element>**: current <X>px, minimum 44px — add `min-h-11 min-w-11`

### Fixes
1. **<file:line>**: change `<current classes>` → `<fixed classes>`
```

## Constraints

- Provide specific Tailwind class changes, not abstract advice
- Review against the existing design system/theme, not arbitrary preferences
- Test against Tailwind's standard breakpoints unless custom ones are configured
- Mobile is the priority — if you can only fix one breakpoint, fix base/sm
