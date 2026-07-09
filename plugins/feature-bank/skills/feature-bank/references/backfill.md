# Bootstrap and Backfill

## Bootstrap: when /docs/features/ doesn't exist

On first use in a repo:

1. Create `/docs/features/` directory.
2. Create `INDEX.md` from `templates/INDEX.md`.
3. **Detect context**: is this an empty/new project, or an existing codebase with real code in `/src`, `/app`, etc.?
   - **New project** → tell the user: "No feature bank yet. I'll scaffold the feature you're asking for now." → proceed to the Scaffolding flow in SKILL.md.
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

## Backfill anti-patterns

- ❌ Writing all feature files in one batch without per-feature user confirmation on non_goals.
- ❌ Extracting acceptance criteria that mention implementation (files, classes, functions). Criteria must be behavioral.
- ❌ Inferring non_goals from code silence. Non_goals are user-stated product intent; the code can't tell you what the user chose NOT to build.
- ❌ Treating the V0 as final. It's a starting point — the first real preflight will surface gaps.
- ❌ Skipping the sizing phase and going straight to inventory. Without a target count, agents overshoot.
