---
name: conventions
description: "Apply xari coding conventions: TypeScript-first, minimal abstractions, conventional commits, Tailwind + Prisma stack preferences"
user-invocable: true
argument-hint: "[language-or-framework]"
---

# Xari Coding Conventions

Apply these conventions to all code you write or review. If the user specifies a language or framework, tailor accordingly: `$ARGUMENTS`

## General Principles

- **Simplicity first** — minimal changes, find root causes, no hacky fixes
- **No over-engineering** — if the simple fix is correct, use it
- **No speculative abstractions** — three similar lines > a premature abstraction
- **Delete dead code** — no `_unused` vars, no `// removed` comments, no re-exports for backwards compat

## TypeScript / JavaScript

- Strict TypeScript everywhere — no `any` unless truly unavoidable (document why)
- Prefer `const` over `let`, never use `var`
- Named exports over default exports
- Use early returns to reduce nesting
- Zod for runtime validation at system boundaries
- No barrel files (`index.ts` re-exports) unless the package explicitly needs a public API

## React / Next.js

- Server Components by default, `"use client"` only when needed
- React Hook Form + Zod for forms
- Tailwind CSS for styling — no CSS modules, no styled-components
- Colocate components with their route when single-use
- Shared components in `src/components/`

## Backend / API

- Prisma for database access
- Zod schemas for request validation
- Return early on errors, happy path at the end
- Use proper HTTP status codes
- Always handle the error case explicitly — no silent catches

## Mobile (Expo / React Native)

- Expo Router for navigation
- expo-secure-store for sensitive data
- Handle permissions gracefully with user-facing messages
- Test on both iOS and Android when possible

## Git & Commits

- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Commit messages explain *why*, not *what*
- One logical change per commit

## Code Review Checklist

When reviewing code, check for:
1. Security: no secrets in code, proper input validation, no injection vectors
2. Error handling: explicit, not silent
3. Types: strict, no `any` leaks
4. Simplicity: could this be simpler?
5. Tests: are edge cases covered?
