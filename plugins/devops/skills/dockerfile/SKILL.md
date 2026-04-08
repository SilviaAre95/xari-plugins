---
name: dockerfile
description: "Generate or review Dockerfiles with multi-stage builds, security hardening, and optimized layer caching"
user-invocable: true
argument-hint: "<app-type: node|python|go|rust> [mode: create|review]"
---

# Dockerfile

App type: **$0**

Mode: **$1** (default: create)

## Create Mode

1. **Analyze the project** — Read `package.json`, `requirements.txt`, `go.mod`, or `Cargo.toml` to understand dependencies and build steps.

2. **Generate a multi-stage Dockerfile**:

```dockerfile
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production=false

# Stage 2: Build
FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Production
FROM node:20-alpine AS production
WORKDIR /app
ENV NODE_ENV=production

# Non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup
USER appuser

COPY --from=build --chown=appuser:appgroup /app/dist ./dist
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=build --chown=appuser:appgroup /app/package.json ./

EXPOSE 3000
CMD ["node", "dist/server.js"]
```

3. **Generate `.dockerignore`**:

```
node_modules
.git
.env*
*.md
.next
dist
coverage
```

## Review Mode

Check for:

1. **Layer caching** — Are frequently changing layers at the bottom?
2. **Image size** — Using alpine/slim base? Multi-stage build? No dev dependencies in production?
3. **Security**:
   - Running as non-root user?
   - No secrets in build args or ENV?
   - Base image pinned to specific version (not `latest`)?
   - No unnecessary packages installed?
4. **Build reproducibility** — `npm ci` not `npm install`? Lock files copied?
5. **Health check** — `HEALTHCHECK` instruction present?

## Output Format

Produce:
- `Dockerfile` — production-ready, multi-stage
- `.dockerignore` — exclude build artifacts, secrets, dev files
- Build and run commands in comments

## Constraints

- Always use multi-stage builds
- Always run as non-root user in production stage
- Pin base image versions (e.g., `node:20.11-alpine`, not `node:latest`)
- Never copy `.env` files or secrets into the image
- Optimize layer order for cache efficiency (deps first, code last)
- Include `HEALTHCHECK` for production images
