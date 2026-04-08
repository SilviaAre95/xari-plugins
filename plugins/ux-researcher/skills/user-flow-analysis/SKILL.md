---
name: user-flow-analysis
description: "Map and analyze user flows through the application — identify friction points, drop-off risks, and optimization opportunities"
user-invocable: true
argument-hint: "<flow-name: signup|checkout|onboarding|...> [persona]"
---

# User Flow Analysis

Analyze the flow: **$0**

User persona: **$1** (default: general user)

## Steps

1. **Map the current flow** — Read the route structure and component hierarchy to reconstruct the user journey:
   - Entry point (how does the user arrive?)
   - Each step/screen in sequence
   - Decision points (branching paths)
   - Exit points (success, abandon, error)

2. **Count friction points per step**:
   - Form fields to fill
   - Decisions to make
   - Clicks required
   - External dependencies (email verification, payment provider)
   - Waiting time (loading, processing)

3. **Identify drop-off risks**:
   - Steps with too many required fields
   - Unclear calls to action
   - Missing progress indicators
   - Points where users might get confused about what to do next
   - Forced account creation before value delivery

4. **Analyze happy path efficiency**:
   - What's the minimum number of steps to complete the flow?
   - Are there unnecessary steps that could be deferred or removed?
   - Can steps be combined without overwhelming the user?
   - Is the default path the most common use case?

5. **Check error recovery**:
   - What happens when a step fails?
   - Can users resume after a failure, or do they restart?
   - Are error messages actionable?
   - Is form data preserved on back navigation?

## Output Format

```markdown
## User Flow Analysis: <flow-name>

### Flow Map
```
[Entry] → [Step 1: <name>] → [Step 2: <name>] → [Decision: <condition>]
                                                       ↓              ↓
                                                  [Path A]       [Path B]
                                                       ↓              ↓
                                                  [Success]      [Step 3]
                                                                      ↓
                                                                 [Success]
```

### Step Analysis
| Step | Actions Required | Friction Score (1-5) | Drop-off Risk |
|------|-----------------|---------------------|---------------|
| 1    | <actions>       | 2                   | low           |
| 2    | <actions>       | 4                   | high          |

### Friction Points
1. **Step N — <issue>**: <description + recommendation>

### Optimization Opportunities
1. **<opportunity>**: <current state → proposed state + expected impact>

### Recommended Metrics
- Track: <conversion rate at each step>
- Alert on: <drop-off rate exceeding threshold>
```

## Constraints

- Base analysis on actual code (routes, components, forms), not assumptions
- Distinguish between essential friction (security verification) and unnecessary friction
- Consider both new users and returning users
- Don't suggest removing steps that are legally or security-required
