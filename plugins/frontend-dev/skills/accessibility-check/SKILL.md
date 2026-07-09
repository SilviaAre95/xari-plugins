---
name: accessibility-check
description: "Audit accessibility — WCAG 2.1 AA code compliance (semantic HTML, ARIA, keyboard, contrast) plus UX experience mode evaluating real usability for people with disabilities"
user-invocable: true
argument-hint: "<file-dir-or-flow> [mode: code|experience|full] [level: A|AA|AAA]"
---

# Accessibility Check

Audit: **$ARGUMENTS** — mode defaults to `code` (WCAG compliance on files); use `experience` for a UX-focused pass on a flow, `full` for both.

## Code Mode (WCAG compliance)

1. **Semantic HTML**: `div` soup → `nav`/`main`/`section`/etc.; `div` with click handler → `button`/`a`; heading hierarchy; `ul`/`ol` for lists; `table` with `th`/`scope`/`caption` for data.
2. **ARIA**: unlabeled interactive elements → `aria-label`; dynamic updates → `aria-live`; expandables → `aria-expanded`; modals → `role="dialog"` + `aria-modal` + focus trap; flag redundant ARIA (`role="button"` on `<button>`).
3. **Keyboard**: everything Tab-reachable, logical order (no positive `tabIndex`), Escape closes overlays, arrow keys in composite widgets, visible focus indicators (no bare `outline-none`), skip link.
4. **Color/contrast**: text ≥ 4.5:1 (AA) / 7:1 (AAA), large text ≥ 3:1; information never by color alone; focus indicators contrast.
5. **Media**: `alt` on all images (`alt=""` decorative), captions/transcripts.
6. **Forms**: visible `label` per input (not placeholder-only), errors via `aria-describedby` and announced, required ≠ color-only.

## Experience Mode (real-world usability, beyond compliance)

Walk the flow as five users and score each 1–5 with critical blockers:
- **Screen reader**: logical content order without visuals; decorative elements hidden; dynamic updates announced; forms navigable blind.
- **Keyboard-only**: every action completable; no traps (modals, infinite scroll); expected patterns in custom widgets.
- **Low vision**: survives 200% zoom without horizontal scroll; works in high-contrast mode; icons legible small.
- **Motor impairment**: targets ≥ 44px with spacing; no unavoidable time limits; drag-and-drop has keyboard path; nothing requires precise hovering.
- **Cognitive**: clear language; instructions visible (not tooltip/placeholder-only); errors explain what to do; primary actions visually distinct.

## Output Format

Code mode: WCAG criterion table (Pass/Fail + details) → Critical issues (`file:line` + fix) → Warnings → automated-testing recs (`eslint-plugin-jsx-a11y`, `axe-core` in CI).
Experience mode: per-disability score table with critical blockers → **Blockers** (prevents completion) → **Barriers** (significantly harder) → **Improvements** → testing recs (VoiceOver/NVDA, mouse unplugged, 200%/400% zoom).

## Constraints

- Prioritize by real user impact, not WCAG criterion number — blockers before barriers before improvements
- Provide code fixes, not descriptions of problems
- Don't flag what assistive tech handles automatically, or decorative images with `alt=""`
- Consider intersections (low vision + motor) and the component's context (library vs page)
