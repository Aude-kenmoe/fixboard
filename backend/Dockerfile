FROM node:20-slim

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

# ── Security: run as non-root ─────────────────────────────────────────────────
# Creates a dedicated user so a compromised process cannot write to the host.
RUN groupadd --gid 1001 nodejs \
 && useradd  --uid 1001 --gid nodejs --shell /bin/bash --create-home nodeuser \
 && mkdir -p /app/uploads \
 && chown -R nodeuser:nodejs /app/uploads

USER nodeuser

EXPOSE 3000

CMD ["node", "src/server.js"]
