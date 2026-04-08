---
name: nextjs-vercel
description: "Stack context for Next.js + Vercel projects — App Router, RSC, Prisma, Tailwind, and Vercel deployment conventions"
user-invocable: false
paths: "next.config.*,app/**/page.tsx,app/**/layout.tsx,vercel.json"
---

# Stack Profile: Next.js + Vercel

This profile is automatically loaded when working in a Next.js project deployed to Vercel.

## Architecture Conventions

- **Next.js 14+** with App Router (not Pages Router)
- **React Server Components** by default; `"use client"` only when needed
- **Prisma** for database access with PostgreSQL
- **Tailwind CSS** for styling
- **NextAuth** or similar for authentication
- **Zod** for validation at system boundaries

## File Structure

```
app/
├── (auth)/           # Route groups for layout scoping
│   ├── login/
│   └── register/
├── api/              # API routes
│   └── resource/
│       └── route.ts  # GET, POST, PUT, DELETE handlers
├── layout.tsx        # Root layout
└── page.tsx          # Home page
src/
├── components/       # Shared React components
├── lib/              # Utilities, config, Prisma client
└── server/           # Server-only code (services, auth)
prisma/
└── schema.prisma
```

## Key Patterns

- Route handlers export named functions: `export async function GET(request: Request)`
- Server actions for mutations: `"use server"` in action files
- Metadata API for SEO: `export const metadata = { ... }` or `generateMetadata()`
- Loading UI: `loading.tsx` for Suspense boundaries
- Error UI: `error.tsx` for error boundaries
- Middleware: `middleware.ts` at project root for auth/redirects

## Vercel-Specific

- Environment variables: set in Vercel dashboard, not `.env` in production
- Edge functions: use `export const runtime = 'edge'` sparingly
- ISR: `revalidate` export for static pages that update
- Image optimization: use `next/image`, Vercel handles the CDN
- Analytics: `@vercel/analytics` for web vitals
- Cron: `vercel.json` crons for scheduled tasks

## Database

- Use Prisma with connection pooling (PgBouncer or Prisma Accelerate)
- `DATABASE_URL` with `?pgbouncer=true&connection_limit=1` for serverless
- Run migrations in CI, not at deploy time

## Performance

- Minimize client JavaScript — keep `"use client"` components small
- Use `Suspense` boundaries for streaming
- Prefetch navigation with `<Link>` (automatic in App Router)
- Avoid waterfalls: parallel data fetching with `Promise.all`
