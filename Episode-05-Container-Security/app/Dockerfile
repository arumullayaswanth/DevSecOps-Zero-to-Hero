# Stage 1: Install dependencies
FROM node:25 AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev

# Stage 2: Production image
FROM gcr.io/distroless/nodejs20-debian12
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Switch to user
USER nonroot
EXPOSE 3000
CMD ["server.js"]