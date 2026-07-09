---
name: expo-mobile
description: "Stack context for Expo / React Native projects — Expo Router, secure storage, permissions, and mobile-specific conventions"
user-invocable: false
paths: "app.json,app.config.*,expo-env.d.ts,**/expo-env.d.ts"
---

# Stack Profile: Expo / React Native

This profile is automatically loaded when working in an Expo project.

## Architecture Conventions

- **Expo Router** for navigation (file-based, like Next.js App Router)
- **expo-secure-store** for tokens and sensitive data — never AsyncStorage for secrets
- **Strict TypeScript**; Zod validation at API boundaries (shared schemas with the web app when in a monorepo)
- Shared logic lives in a shared workspace package, not duplicated per platform

## Mobile-Specific Patterns

- Handle permissions gracefully: request in context, explain why, degrade with a user-facing message when denied (camera, notifications, location)
- Design for offline-first where data allows; show explicit loading/stale states
- Deep links: define the scheme in `app.json` and test cold-start routing
- Push: expo-notifications tokens are per-device — store server-side keyed to the user

## Build & Release

- EAS Build for binaries; keep `app.json` versioning in sync with release tags
- Test on both iOS and Android before release — platform-specific bugs are the norm, not the exception
- Never commit signing credentials; EAS manages them
