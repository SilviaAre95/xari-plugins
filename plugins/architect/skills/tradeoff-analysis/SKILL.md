---
name: tradeoff-analysis
description: "Compare architectural or technical options with a structured pros/cons/recommendation analysis"
user-invocable: true
argument-hint: "<option-a> vs <option-b> [context]"
---

# Tradeoff Analysis

Analyze the tradeoffs between: **$ARGUMENTS**

## Steps

1. **Frame the decision** — What exactly is being decided? What are the constraints (timeline, team size, existing tech, budget)?

2. **Define evaluation criteria** — Pick 4-6 criteria relevant to the decision. Common ones:
   - Complexity (implementation + maintenance)
   - Performance (latency, throughput)
   - Scalability (horizontal, vertical)
   - Developer experience (learning curve, tooling)
   - Cost (infra, licensing, engineering time)
   - Risk (maturity, vendor lock-in, failure modes)

3. **Evaluate each option** — For each criterion, rate and explain. Be specific — "faster" isn't useful, "~50ms p99 vs ~200ms p99" is.

4. **Identify hidden costs** — What will bite you in 6 months? Migration difficulty, operational burden, hiring constraints.

5. **Recommend** — Pick one. State the conditions under which you'd pick the other.

## Output Format

```markdown
## Tradeoff Analysis: <Option A> vs <Option B>

### Context
<What's being decided and why>

### Criteria Matrix

| Criteria     | <Option A>         | <Option B>         |
|-------------|--------------------|--------------------|
| Complexity  | <rating + detail>  | <rating + detail>  |
| Performance | <rating + detail>  | <rating + detail>  |
| ...         | ...                | ...                |

### Hidden Costs
- **<Option A>**: <what'll hurt later>
- **<Option B>**: <what'll hurt later>

### Recommendation
**Go with <Option X>** because <primary reason>.

Choose <Option Y> instead if: <conditions>.
```

## Constraints

- No fence-sitting — always make a recommendation
- Be honest about uncertainty; say "I don't have enough info to evaluate X" rather than guessing
- Ground claims in specifics, not vibes
- Consider the team's existing skills and stack
