---
name: accessibility-audit
description: "Comprehensive UX-focused accessibility audit — goes beyond code compliance to evaluate the actual user experience for people with disabilities"
user-invocable: true
argument-hint: "<page-or-flow> [disability-focus: visual|motor|cognitive|all]"
---

# Accessibility Audit (UX-Focused)

Audit: **$0**

Focus: **$1** (default: all)

## Steps

This audit goes beyond WCAG compliance checklists to evaluate real-world usability.

### 1. Screen Reader Experience
- Navigate the page with an imagined screen reader — is the content order logical?
- Are decorative elements hidden from assistive tech? (`aria-hidden`, `role="presentation"`)
- Do dynamic updates announce themselves? (`aria-live`)
- Are form flows navigable without visual context?
- Is the page comprehensible without any visual styling?

### 2. Keyboard-Only Experience
- Can every action be completed without a mouse?
- Is the focus order logical (follows visual layout)?
- Are focus indicators visible and clear?
- Can users escape traps (modals, dropdowns, infinite scroll)?
- Do custom components implement expected keyboard patterns? (e.g., arrow keys in tabs)

### 3. Low Vision Experience
- Does the layout survive 200% zoom without horizontal scroll?
- Is text resizable without breaking layout?
- Do colors pass contrast requirements in both themes?
- Are icons and graphics legible at small sizes?
- Does the UI work with high-contrast mode?

### 4. Motor Impairment Experience
- Are click targets large enough (≥ 44px)?
- Is adequate spacing between interactive elements?
- Are there time-limited interactions that need extending?
- Can drag-and-drop actions be completed with keyboard?
- Are hover-based interactions accessible without precise mouse control?

### 5. Cognitive Load Assessment
- Is language clear and concise?
- Are instructions visible (not just in tooltips or placeholders)?
- Are error messages explanatory, not just "invalid input"?
- Is there too much information on one screen?
- Are important actions visually distinct from secondary actions?

## Output Format

```markdown
## Accessibility Audit: <target>

### Experience Summary
| Disability | Usability Score (1-5) | Critical Blockers |
|-----------|----------------------|-------------------|
| Screen reader | 3 | Form fields unlabeled |
| Keyboard only | 4 | Modal has no focus trap |
| Low vision | 2 | Fails at 200% zoom |
| Motor impairment | 4 | — |
| Cognitive | 3 | Error messages unclear |

### Blockers (prevents task completion)
1. **<issue>**: <who it blocks + fix>

### Barriers (makes task significantly harder)
1. **<issue>**: <who it affects + fix>

### Improvements (nice to have)
1. **<issue>**: <recommendation>

### Testing Recommendations
- Screen reader: test with VoiceOver (macOS) or NVDA (Windows)
- Keyboard: unplug mouse, navigate entire flow
- Zoom: test at 200% and 400%
- Automated: add `axe-core` to CI
```

## Constraints

- Prioritize by user impact, not WCAG criterion number
- Blockers > barriers > improvements — always fix blockers first
- Consider the intersection of disabilities (e.g., low vision + motor impairment)
- Don't flag issues that assistive technology handles automatically
- Be specific about who is affected and how
