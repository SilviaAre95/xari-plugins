---
name: responsive-audit
description: "Audit pages and components for responsive behavior across mobile, tablet, and desktop breakpoints"
user-invocable: true
argument-hint: "<file-or-directory> [breakpoints: sm|md|lg|xl|all]"
---

# Responsive Audit

Audit responsive behavior for: **$0**

Breakpoints: **$1** (default: all)

## Steps

1. **Check mobile-first approach**:
   - Base styles should be mobile layout
   - `sm:`, `md:`, `lg:`, `xl:` add complexity for larger screens
   - Flag desktop-first patterns (e.g., `flex-row` base with `max-sm:flex-col`)

2. **Check breakpoint coverage by component**:

   For each layout-affecting component, verify behavior at each breakpoint:

   | Element | Mobile (base) | sm (640px) | md (768px) | lg (1024px) | xl (1280px) |
   |---------|--------------|------------|------------|-------------|-------------|
   | Nav     | hamburger    | hamburger  | full       | full        | full        |
   | Grid    | 1 col        | 1 col      | 2 col      | 3 col       | 4 col       |
   | Sidebar | hidden       | hidden     | collapsible| visible     | visible     |

3. **Check common responsive issues**:
   - **Overflow**: horizontal scroll on mobile (check `overflow-x-hidden` on body)
   - **Text scaling**: headings too large on mobile, body text too small
   - **Images**: fixed dimensions that don't scale (`w-[500px]` → `w-full max-w-lg`)
   - **Tables**: wide tables not scrollable on mobile (wrap in `overflow-x-auto`)
   - **Modals**: full-screen on mobile, centered on desktop
   - **Forms**: inputs too narrow or too wide at various breakpoints
   - **Navigation**: missing mobile nav, or desktop nav showing on mobile

4. **Check touch targets**:
   - All interactive elements ≥ 44x44px on mobile
   - Adequate spacing between tap targets (no accidental taps)
   - Hover-only interactions have touch alternatives

5. **Check container constraints**:
   - Is there a `max-w-*` on the main content area?
   - Does content stretch uncomfortably on ultra-wide screens?
   - Are `px-4` or `container mx-auto` used for horizontal padding?

## Output Format

```markdown
## Responsive Audit: <target>

### Breakpoint Matrix
| Component | base | sm | md | lg | xl | Issues |
|-----------|------|----|----|----|----|--------|
| ...       | ...  | ...| ...| ...| ...| ...    |

### Critical Issues (broken layout)
1. **<file:line>**: <issue + fix>

### Warnings (suboptimal but functional)
1. **<file:line>**: <issue + recommendation>

### Touch Target Violations
1. **<element>**: current size <X>px, minimum 44px — add `min-h-11 min-w-11`
```

## Constraints

- Provide specific Tailwind class fixes, not abstract advice
- Test against Tailwind's standard breakpoints unless custom ones are configured
- Focus on functional layout issues, not aesthetic preferences
- Mobile is the priority — if you have to pick one breakpoint to fix, pick base/sm
