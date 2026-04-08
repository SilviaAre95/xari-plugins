---
name: styling-review
description: "Review Tailwind CSS usage, design consistency, and styling patterns across components"
user-invocable: true
argument-hint: "<file-or-directory> [focus: consistency|performance|cleanup]"
---

# Styling Review

Review styling for: **$0**

Focus: **$1** (default: all)

## Steps

1. **Scan for anti-patterns**:
   - Inline styles (`style={{}}`) — should be Tailwind classes
   - CSS modules or styled-components mixed with Tailwind
   - Hardcoded colors instead of theme tokens (`text-[#333]` → `text-gray-700`)
   - Arbitrary values (`w-[347px]`) where standard values work (`w-80`)
   - Duplicate class combinations that should be extracted

2. **Check consistency**:
   - Spacing scale: are components using consistent spacing? (`p-4` everywhere, not `p-4` and `p-[15px]`)
   - Typography: consistent font sizes and weights across similar elements
   - Color usage: semantic colors (`text-primary`, `bg-destructive`) vs raw palette
   - Border radius: consistent rounding (`rounded-lg` everywhere, not mixed)
   - Shadow usage: consistent elevation system

3. **Check responsive design**:
   - Mobile-first approach (base styles = mobile, `sm:` `md:` `lg:` for larger)
   - No missing breakpoint coverage for layout-critical elements
   - Text sizes scale appropriately
   - Touch targets are at least 44x44px on mobile

4. **Check dark mode** (if applicable):
   - All colors have `dark:` variants
   - No hardcoded white/black that breaks in dark mode
   - Images and icons have dark mode alternatives

5. **Performance check**:
   - No unused Tailwind classes (check with `tailwind-merge` usage)
   - Complex animations use `will-change` or `transform` for GPU acceleration
   - Large class strings could use `cn()` for readability

## Output Format

```markdown
## Styling Review: <target>

### Summary
- **Issues**: X critical, Y warnings
- **Consistency score**: <good | needs work | inconsistent>

### Anti-patterns
1. **<file:line>**: <issue + fix>

### Consistency Issues
1. **<pattern>**: <inconsistency + recommendation>

### Quick Wins
1. <easy improvement>
```

## Constraints

- Don't suggest switching away from Tailwind
- Respect existing design tokens and theme configuration
- Flag issues by severity — don't bury critical problems in style nits
- If `tailwind.config` extends the theme, check against those custom values
