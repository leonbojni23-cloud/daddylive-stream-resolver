# syntax=docker/dockerfile:1

# ---- Build stage: install dev deps (TypeScript), compile to dist/ ----
# Zero runtime deps, so node_modules exists only in this stage.
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
# Avoid BuildKit cache-mount syntax so Railway's Dockerfile parser accepts this.
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ---- Runtime stage: Node + compiled JS only ----
FROM node:22-alpine AS runtime
ENV NODE_ENV=production PORT=3000
WORKDIR /app
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "dist/api/index.js"]
