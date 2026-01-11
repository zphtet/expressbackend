# Use Node.js LTS version
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci

# Generate Prisma Client
FROM base AS prisma-generate
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY prisma ./prisma
COPY package.json ./
RUN npx prisma generate

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 expressuser

# Copy necessary files
COPY --from=deps /app/node_modules ./node_modules
COPY --from=prisma-generate /app/generated ./generated
COPY package.json ./
COPY tsconfig.json ./
COPY src ./src
COPY lib ./lib
COPY prisma ./prisma

# Change ownership
RUN chown -R expressuser:nodejs /app
USER expressuser

# Expose port
EXPOSE 3005

# Run the application
CMD ["npx", "tsx", "src/server.ts"]
