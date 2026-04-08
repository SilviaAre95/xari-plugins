---
name: accessibility-check
description: "Audit React components for WCAG 2.1 AA compliance — semantic HTML, ARIA, keyboard nav, color contrast"
user-invocable: true
argument-hint: "<file-or-directory> [level: A|AA|AAA]"
---

# Accessibility Check

Audit accessibility for: **$0**

WCAG level: **$1** (default: AA)

## Steps

1. **Semantic HTML audit**:
   - `div` soup → replace with `nav`, `main`, `section`, `article`, `aside`, `header`, `footer`
   - `div` with click handler → should be `button` or `a`
   - `span` acting as heading → should be `h1`-`h6` with proper hierarchy
   - Lists of items → should use `ul`/`ol` + `li`
   - Tables of data → should use `table` with `th`, `scope`, `caption`

2. **ARIA audit**:
   - Interactive elements without labels → add `aria-label` or `aria-labelledby`
   - Dynamic content updates → add `aria-live` regions
   - Expandable sections → `aria-expanded`
   - Modal dialogs → `role="dialog"`, `aria-modal="true"`, focus trap
   - Custom widgets → proper ARIA roles matching WAI-ARIA patterns
   - Flag redundant ARIA (e.g., `role="button"` on a `<button>`)

3. **Keyboard navigation**:
   - All interactive elements reachable via Tab
   - Logical tab order (no positive `tabIndex` values)
   - Escape closes modals/dropdowns
   - Arrow keys navigate within composite widgets (tabs, menus, listboxes)
   - Visible focus indicators (no `outline-none` without replacement)
   - Skip navigation link for page-level content

4. **Color and contrast**:
   - Text contrast ratio ≥ 4.5:1 (AA) or ≥ 7:1 (AAA)
   - Large text (18px+) contrast ratio ≥ 3:1
   - Information not conveyed by color alone (add icons, patterns, or text)
   - Focus indicators have sufficient contrast

5. **Images and media**:
   - All `img` tags have `alt` text (or `alt=""` for decorative)
   - Complex images have extended descriptions
   - Video has captions, audio has transcripts

6. **Forms**:
   - Every input has a visible `label` (not just placeholder)
   - Error messages are associated with inputs (`aria-describedby`)
   - Required fields indicated with more than just color
   - Form validation errors announced to screen readers

## Output Format

```markdown
## Accessibility Audit: <target>

### WCAG <level> Compliance

| Criterion | Status | Issues |
|-----------|--------|--------|
| 1.1.1 Non-text Content | Pass/Fail | <details> |
| 1.3.1 Info and Relationships | Pass/Fail | <details> |
| 2.1.1 Keyboard | Pass/Fail | <details> |
| 2.4.7 Focus Visible | Pass/Fail | <details> |
| 4.1.2 Name, Role, Value | Pass/Fail | <details> |

### Critical Issues (must fix)
1. **<file:line>**: <issue + fix>

### Warnings (should fix)
1. **<file:line>**: <issue + recommendation>

### Automated Testing Recommendations
- Add `eslint-plugin-jsx-a11y` to lint config
- Run `axe-core` in integration tests
```

## Constraints

- Focus on issues that affect real users, not theoretical compliance
- Provide code fixes, not just descriptions of problems
- Don't flag decorative images missing alt text if they have `alt=""`
- Consider the component in context — a component library has different needs than a page
