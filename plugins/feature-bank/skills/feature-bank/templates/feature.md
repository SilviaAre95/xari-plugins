---
id: <kebab-case-id>
title: <short human title>
status: proposed  # proposed | in-progress | implemented | deprecated
created_at: YYYY-MM-DD
last_modified: YYYY-MM-DD
owner: <name or team>
depends_on: []
acceptance_criteria:
  - <concrete, testable behavior>
  - <another testable behavior>
non_goals:
  - <thing this feature will NOT do>
  - <another explicit exclusion>
---

# <Feature title>

## Summary

One paragraph: what this feature is and why it exists. Focus on user-facing value, not implementation.

## Behavior

Describe the user-facing behavior in prose. What does the user see? What can they do? What happens on success, on failure, on edge cases? This is the behavioral contract — if code doesn't match what's written here, either the code is wrong or the spec needs an escape-hatch update.

## Out of scope

Expand on `non_goals` in narrative form. Why are these excluded? What would they require? Where (if anywhere) are they tracked for the future?

## Open questions

- [ ] <unresolved decision>
- [ ] <another open question>

(Empty this section before moving `status` to `implemented`.)

## Implementation notes (optional)

Free-form notes about *how* this is currently built — file pointers, libraries used, relevant modules. This section is informational, not contractual. The `acceptance_criteria` above are the contract; this section is a breadcrumb trail for navigating the code. Leave empty if not useful.
