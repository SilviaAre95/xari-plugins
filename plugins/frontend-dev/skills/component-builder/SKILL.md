---
name: component-builder
description: "Scaffold React/Next.js components with proper types, props, accessibility, and Tailwind styling"
user-invocable: true
argument-hint: "<component-name> [type: page|layout|ui|form]"
---

# Component Builder

Build a React component: **$0**

Type: **$1** (default: ui)

## Steps

1. **Determine component type and location**:
   - `page` → route-level component in `app/` directory
   - `layout` → layout wrapper in `app/` directory
   - `ui` → reusable component in `src/components/`
   - `form` → form component with React Hook Form + Zod

2. **Decide server vs client**:
   - Default to Server Component
   - Use `"use client"` only if the component needs: event handlers, useState/useEffect, browser APIs, or third-party client libraries
   - If a component is mostly static with one interactive part, extract the interactive part into a small client component

3. **Design the props interface**:

```typescript
interface ComponentNameProps {
  // Required props first
  title: string;
  // Optional props with defaults
  variant?: "default" | "outline" | "ghost";
  size?: "sm" | "md" | "lg";
  // Event handlers
  onAction?: () => void;
  // Children if needed
  children?: React.ReactNode;
}
```

4. **Build the component**:
   - Tailwind CSS for all styling — no CSS modules or styled-components
   - Use `cn()` utility (clsx + tailwind-merge) for conditional classes
   - Forward refs where appropriate (`forwardRef`)
   - Destructure props with defaults in the function signature

5. **Add accessibility**:
   - Semantic HTML elements (`button`, `nav`, `main`, `section`, `article`)
   - ARIA attributes where semantic HTML isn't sufficient
   - Keyboard navigation for interactive elements
   - Focus management for modals/dialogs
   - Color contrast compliance (4.5:1 minimum for text)

6. **Handle loading and error states** if the component fetches data.

## Output Format

Produce the component file with:
- TypeScript interface for props
- The component implementation
- Export statement (named export, not default)

If it's a form component, also produce the Zod schema file.

## Constraints

- Named exports only — no `export default`
- Tailwind only — no inline styles, no CSS modules
- No `any` types
- No barrel files unless the component is part of a published package
- Keep components under 150 lines — extract sub-components if larger
- Don't add storybook files or test files unless explicitly asked
