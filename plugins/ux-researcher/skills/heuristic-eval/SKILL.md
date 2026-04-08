---
name: heuristic-eval
description: "Evaluate a UI against Nielsen's 10 usability heuristics with severity ratings and fix recommendations"
user-invocable: true
argument-hint: "<page-or-flow> [heuristics: all|visibility|feedback|consistency|errors]"
---

# Heuristic Evaluation

Evaluate: **$0**

Focus: **$1** (default: all)

## Nielsen's 10 Heuristics

For each heuristic, audit the target code/UI and rate compliance:

### 1. Visibility of System Status
- Does the UI show loading states?
- Are progress indicators present for long operations?
- Does the user know what state they're in (active nav, form step)?

### 2. Match Between System and Real World
- Does the language match the user's mental model?
- Are icons intuitive or do they need labels?
- Is information organized in a natural, logical order?

### 3. User Control and Freedom
- Can users undo actions?
- Is there a clear "back" or "cancel" option?
- Can users exit flows without losing progress?

### 4. Consistency and Standards
- Do similar actions look and behave the same way?
- Do UI patterns follow platform conventions?
- Is terminology consistent across the app?

### 5. Error Prevention
- Are destructive actions confirmed?
- Do forms validate inline before submission?
- Are edge cases handled before the user hits them?

### 6. Recognition Rather Than Recall
- Is navigation visible, not hidden behind menus?
- Are recent items, saved searches, or suggestions available?
- Do form fields have helpful defaults or examples?

### 7. Flexibility and Efficiency of Use
- Are there shortcuts for power users?
- Can common tasks be completed in minimal steps?
- Does the UI support keyboard navigation?

### 8. Aesthetic and Minimalist Design
- Is there visual clutter that doesn't serve the user?
- Is every element on screen necessary?
- Is the information density appropriate for the context?

### 9. Help Users Recognize, Diagnose, and Recover from Errors
- Are error messages in plain language (not codes)?
- Do errors explain what went wrong and how to fix it?
- Are errors shown near the problem (not just at the top)?

### 10. Help and Documentation
- Is the UI self-explanatory, or does it need help text?
- Are tooltips or inline help available for complex features?
- Is there an onboarding flow for new users?

## Output Format

```markdown
## Heuristic Evaluation: <target>

### Summary
| Heuristic | Score (0-4) | Critical Issues |
|-----------|-------------|-----------------|
| 1. Visibility of System Status | 3 | loading states missing on 2 pages |
| 2. Match Real World | 4 | — |
| ... | ... | ... |

**Overall Score**: X/40

### Critical Issues (severity 3-4)
1. **H5 Error Prevention**: <file:line> — <issue + fix>

### Moderate Issues (severity 2)
1. **H3 User Control**: <issue + recommendation>

### Minor Issues (severity 0-1)
1. **H8 Minimalist Design**: <cosmetic suggestion>
```

**Severity scale**: 0 = not a problem, 1 = cosmetic, 2 = minor, 3 = major, 4 = catastrophic

## Constraints

- Evaluate based on the code/UI, not screenshots
- Provide actionable fixes, not just problem descriptions
- Be honest about severity — not everything is critical
- Consider the user context (admin tool vs consumer app have different standards)
