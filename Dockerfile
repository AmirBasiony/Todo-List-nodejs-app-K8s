# ---------- STAGE 1: Builder ----------
    FROM node:18-slim AS builder

    WORKDIR /app
    
    # Copy only package files first and install production dependencies
    COPY package*.json ./
    # Install only production dependenciess
    RUN npm install --omit=dev
    
    # Copy the rest of the app
    COPY . .
    
    
    # ---------- STAGE 2: Runtime ----------
    FROM node:18-alpine AS runtime
    
    # Create a non-root user
    RUN addgroup -S appuser && adduser -S -G appuser appuser
    
    # Set working directory
    WORKDIR /app
    
    # Copy only what's needed from builder
    COPY --from=builder /app/package*.json ./
    COPY --from=builder /app/node_modules ./node_modules
    COPY --from=builder /app/views ./views
    COPY --from=builder /app/assets ./assets
    COPY --from=builder /app/config ./config
    COPY --from=builder /app/controllers ./controllers
    COPY --from=builder /app/models ./models
    COPY --from=builder /app/routes ./routes
    COPY --from=builder /app/index.js ./
    
    # Create /app/data and set ownership in a single layer
    RUN mkdir -p /app/data && chown -R appuser:appuser /app
    
    # Switch to non-root user
    USER appuser
    
    # Expose the app port
    EXPOSE 4000
    
    # Start the app
    CMD ["npm", "start"]