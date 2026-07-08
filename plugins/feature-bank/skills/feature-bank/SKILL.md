---
name: feature-bank
description: Prevent agent drift and silent feature mutation by enforcing a source-of-truth feature bank. Trigger this skill WHENEVER you are about to edit, create, or delete code in /src, /app, /lib, /api, /components, /pages, or similar code directories — no matter how small the change. Also trigger on requests like "add a feature", "implement X", "remove Y", "refactor Z", "change how X works", "populate the feature bank", "backfill features", or when the user describes product behavior. The skill runs a hard preflight check against /docs/features/ before any code is written, blocks scope creep via explicit non_goals, requires a diff-first approval flow for intentional spec changes, and runs a postflight to update metadata and changelog. For existing codebases with no feature bank, it runs an interactive Backfill flow to reverse-engineer a V0 from the code. Do NOT skip this skill to "move faster"; skipping is the drift it is designed to prevent.
---

# Feature Bank

Source-of-truth feature specs that prevent agents from silently adding, removing, or mutating product features.

## Mental model

- **This skill is prescriptive, not descriptive.** It says what the product *must* and *must not* do. Compare to `project-docs` which describes how the system is built.
- **Two gates bracket every code change**: preflight (before) and postflight (after).
- **Drift has two shapes**: adding something not spec'd (scope creep) and changing something spec'd without flagging it (silent mutation). Both are caught here.

## Folder layout

```
/docs/features/
  INDEX.md                    ← table of contents, always read first
  <feature-id>.md             ← full spec (frontmatter + prose)
  <feature-id>.CHANGELOG.md   ← append-only history
```

Feature IDs are kebab-case, domain-prefixed: `auth-login`, `billing-invoice`, `search-filters`.

## The three gates

### Gate 1 — Preflight (MANDATORY before writing code)

Before you edit a single line of code:

1. **Read `/docs/features/INDEX.md`.** If it does not exist, run the Bootstrap flow (see below).
2. **Identify affected features** by mapping the code you're about to touch to feature IDs. If unclear, ask the user which feature(s) this change belongs to.
3. **Load each affected feature file** (`/docs/features/<id>.md`) fully — frontmatter and body.
4. **State out loud** to the user, in one short block:
   - Which feature(s) this change touches (IDs)
   - What behavior you intend to implement/change
   - Which `acceptance_criteria` it satisfies
   - Confirmation that nothing in `non_goals` is being violated
5. **Scan `non_goals` across all features in INDEX.md** for keywords matching your planned change. If any hit → STOP and invoke the Escape Hatch.
6. **Deviation check**: if what the user is asking for differs from what the spec says → STOP and invoke the Escape Hatch. Do NOT silently "fix" the spec by writing code that matches the new request.

Only after all six steps pass may you edit code.

### Gate 2 — Escape Hatch (diff-first spec change)

Triggered when preflight detects a mismatch between the user's request and the existing spec, OR when the user explicitly wants to change a feature.

1. Do **not** edit code yet.
2. Produce a **unified diff** of the proposed change to the feature file. Format:

   ```diff
   --- a/docs/features/auth-login.md
   +++ b/docs/features/auth-login.md
   @@ acceptance_criteria @@
   -  - Session persists 30 days
   +  - Session persists 14 days
   +  - User can extend session to 30 days via "remember me"
   ```

3. Show the diff to the user with a one-line summary of the behavioral impact.
4. **Wait for explicit approval** ("yes", "approved", "go", etc.) in the chat. Do not assume.
5. Once approved: apply the diff to the feature file, bump `last_modified`, append a changelog entry (see Gate 3), THEN proceed to code.

If the user rejects or modifies the diff, iterate on the spec — do not write code against a spec the user hasn't signed off on.

### Gate 3 — Postflight (MANDATORY after writing code)

After code changes are complete:

1. **Update frontmatter** of every touched feature file:
   - `last_modified: <today's date>`
   - `status` if it changed (e.g., `proposed` → `in-progress`, `in-progress` → `implemented`)
2. **Append to `<feature-id>.CHANGELOG.md`** (create if missing):

   ```markdown
   ## 2026-04-16
   - **Changed**: login session duration reduced from 30 → 14 days
   - **Added**: "remember me" extension flow
   - **Files touched**: src/auth/session.ts, src/auth/login.tsx
   - **Approved via**: diff-first escape hatch
   ```

3. **Re-verify acceptance criteria**: quickly restate each criterion and confirm the code change either satisfies it or was explicitly updated in the spec.
4. **Report to user**: which features were updated, which files changed, link to the changelog entry.

## Scaffolding: creating a new feature

When the user describes something new ("I want users to be able to export reports as CSV"):

1. **Do not jump to code.** First, generate a feature file from `templates/feature.md`.
2. **Choose an ID** following the domain-prefix convention. Confirm with user if ambiguous.
3. **Fill the template.** The critical fields:
   - `acceptance_criteria`: concrete, testable behaviors (not implementation details)
   - **`non_goals`: explicitly list what this feature will NOT do.** This is the single most important anti-drift field. Push the user on this. Examples: "NOT export as PDF", "NOT support scheduled exports", "NOT include deleted records". If the user says "I don't know what non-goals to list", suggest 3-5 plausible ones and ask them to confirm or reject each.
   - `depends_on`: other feature IDs this relies on
4. **Add an entry to `INDEX.md`** with ID, title, status=`proposed`, one-line summary, top 2 non_goals.
5. **Create `<feature-id>.CHANGELOG.md`** with an initial entry.
6. **Show the user the new feature file** and ask for confirmation before moving to implementation.

## Bootstrap: when /docs/features/ doesn't exist

On first use in a repo:

1. Create `/docs/features/` directory.
2. Create `INDEX.md` from `templates/INDEX.md`.
3. **Detect context**: is this an empty/new project, or an existing codebase with real code in `/src`, `/app`, etc.?
   - **New project** → tell the user: "No feature bank yet. I'll scaffold the feature you're asking for now." → proceed to Scaffolding flow.
   - **Existing codebase** → tell the user: "No feature bank yet, and I see existing code. Before I touch anything, I strongly recommend running the Backfill flow to reverse-engineer a V0 feature bank from what's already built. This takes ~15–45 min of back-and-forth but prevents every future change from drifting against an empty spec. Want to start the backfill now, or scaffold only the current request?" → if user says backfill, run the Backfill flow below. If user declines, proceed to Scaffolding for the current request only (and remind them the bank will be incomplete).

## Backfill: reverse-engineering a V0 from existing code

The goal is a complete-enough V0 that subsequent preflight checks are meaningful. This flow is **fully interactive** — no batched file dumps, no unilateral agent decisions on features. Four phases.

### Phase 1 — Sizing pass (agent → user, read-only)

Before proposing any features, assess the project:

1. Read `README`, `package.json` / `pyproject.toml` / equivalent, top-level folder structure, and route definitions (e.g., `app/routes.ts`, `urls.py`, Next.js `app/` directory, Express routers).
2. Skim — do NOT deep-read — the main entry points, models/schemas, and any obvious feature folders.
3. Produce a **sizing summary** in chat:
   - Rough LOC and number of top-level modules
   - Domains detected (e.g., "auth, billing, dashboard, reports, admin")
   - **Proposed feature count with rationale**: "Based on ~8k LOC across 5 domains, I propose targeting ~15–20 top-level features. Coarser (e.g., 8 features) loses resolution; finer (e.g., 40) makes preflight noisy."
4. **Ask the user**: "Does this target count work, or do you want coarser/finer?" Wait for confirmation before proceeding.

### Phase 2 — Interactive inventory (one-line-per-feature review loop)

Produce a **flat list of proposed feature IDs and one-line descriptions only**. Do NOT write any files yet.

Format:

```
Proposed V0 inventory (18 features):

 1. auth-login          — Email + password login with session persistence
 2. auth-signup         — New user registration with email verification
 3. auth-password-reset — Request and complete password reset via email
 4. billing-subscription — Monthly/annual subscription management
 5. billing-invoice     — View and download past invoices
 ...
18. admin-user-search   — Admin can search and view user accounts
```

Ask the user to review by annotating each line with one of:

- **keep** — the feature is correct as stated
- **merge with N** — combine this with feature number N
- **split into X, Y** — this is actually multiple features
- **drop** — not really a product feature (e.g., it's infrastructure)
- **rename to <new-id>** — ID or description is off
- **add**: <id> — <description> — a feature the agent missed

Go through the list **interactively** — accept user annotations in whatever format feels natural (numbered list, back-and-forth chat, etc.). Iterate until the user says "inventory looks good."

Then show the **final confirmed inventory** and ask: "Confirmed? Moving to Phase 3."

### Phase 3 — Per-feature scaffolding (one feature at a time)

For each confirmed feature in the inventory, in order:

1. **Deep-read the code** that implements this feature (files, routes, components, models relevant to it).
2. Draft the feature file with:
   - `status: implemented` (default, since the code exists) or `in-progress` if obviously partial
   - `created_at`: today's date (backfill date, not original build date — note this in the changelog)
   - `acceptance_criteria`: **purely behavioral, no file refs.** Describe what a user can observe or do. Examples: "User can log in with email and password", "Failed login shows an inline error", "Session persists for 30 days". NOT "Code in auth.ts handles JWT signing" — that's implementation.
   - `non_goals`: **LEAVE EMPTY initially** — non_goals come from the user, not the code.
3. **Present the draft in chat** (not written to disk yet) with this structure:

   ```
   Feature 3/18: auth-password-reset

   Proposed acceptance criteria (from code):
     - User can request a password reset by entering their email
     - Reset link is emailed and valid for 1 hour
     - Clicking the link opens a form to set a new password
     - After reset, user is automatically logged in

   Proposed non_goals (I'll ask you to confirm/reject):
     - NOT support SMS-based reset codes (not in the code)
     - NOT support security questions (not in the code)
     - NOT allow admin-initiated password resets on behalf of users
     - NOT notify user of successful reset via email

   For each non_goal: confirm, reject, or edit. Also add any missing ones.
   ```

4. **Wait for user response on non_goals.** Iterate until user confirms.
5. Once confirmed, **write the feature file and changelog file** to disk. Changelog initial entry:

   ```markdown
   ## YYYY-MM-DD
   - **Backfilled from existing code** as part of V0 feature bank
   - **Status**: implemented (inferred from code presence)
   - **Acceptance criteria**: extracted behaviorally from code
   - **Non-goals**: confirmed interactively with user
   - **Source commit**: <git sha if available>
   ```

6. Update `INDEX.md` with a new row.
7. Move to the next feature.

**Pacing**: every 5 features, pause and ask "Want to continue, take a break, or adjust anything?" Backfill is tiring for the user — don't power through 20 features without check-ins.

### Phase 4 — V0 wrap-up

Once all features are scaffolded:

1. Summarize in chat: "V0 feature bank complete. 18 features, all status=implemented. INDEX.md populated. Each feature has a changelog with the backfill entry."
2. **Flag any uncertainties**: features where the code was ambiguous, non_goals the user seemed unsure about, anything that warrants a future second pass.
3. Remind the user: "From now on, all code changes in /src, /app, etc. will preflight against this bank. If a preflight surfaces drift between code and spec, we'll use the escape hatch to decide which is right."
4. Suggest committing the `/docs/features/` folder as a single atomic commit titled something like `docs: backfill V0 feature bank from existing codebase`.

### Backfill anti-patterns

- ❌ Writing all feature files in one batch without per-feature user confirmation on non_goals.
- ❌ Extracting acceptance criteria that mention implementation (files, classes, functions). Criteria must be behavioral.
- ❌ Inferring non_goals from code silence. Non_goals are user-stated product intent; the code can't tell you what the user chose NOT to build.
- ❌ Treating the V0 as final. It's a starting point — the first real preflight will surface gaps.
- ❌ Skipping the sizing phase and going straight to inventory. Without a target count, agents overshoot.


## Feature file template

See `templates/feature.md`. Required frontmatter fields:

```yaml
id: <kebab-case-id>
title: <short human title>
status: proposed | in-progress | implemented | deprecated
created_at: YYYY-MM-DD
last_modified: YYYY-MM-DD
owner: <name or team>
depends_on: [<other-feature-ids>]
acceptance_criteria:
  - <testable behavior 1>
  - <testable behavior 2>
non_goals:
  - <thing this feature will NOT do>
  - <another exclusion>
```

Body sections (markdown, kept short):
- `## Summary` — one paragraph, what and why
- `## Behavior` — user-facing behavior in prose
- `## Out of scope` — narrative expansion of non_goals
- `## Open questions` — unresolved decisions (empty once `implemented`)

## INDEX.md format

See `templates/INDEX.md`. It's a compact table so agents can load it cheaply and scan non_goals fast.

## Anti-patterns (do not do these)

- ❌ Skipping preflight because "the change is tiny". Tiny changes are where drift hides.
- ❌ Writing code first and updating the feature file after to match. This is drift.
- ❌ Rewriting the feature body during postflight. Use the CHANGELOG for history; amend the body only via the escape hatch.
- ❌ Letting `non_goals` be empty. An empty non_goals list means the feature has no boundaries and every future change will scope-creep.
- ❌ Using vague acceptance criteria like "works well" or "is fast". Criteria must be checkable.
- ❌ Merging feature-bank contents into `/docs/architecture/`. Loose coupling only — different skills own different folders.

## When NOT to use this skill

- Pure refactors that change no behavior (internal variable renames, file moves). Still note in a commit but no gate needed.
- Build config, CI, dependency bumps — these touch code but don't change features.
- Experimental spikes in `/spike/` or `/scratch/` folders. Keep those outside feature bank.

If in doubt, run the gates. The cost of a 30-second preflight is tiny compared to shipping drifted behavior.
