FROM node:20-slim

# Install the Debian security fixes published since the base image was built
RUN apt-get update \
 && apt-get upgrade -y \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
# npm is only needed to install the dependencies: remove it so its own
# bundled packages do not ship (and get flagged by the scanner) in the image
RUN npm ci --omit=dev \
 && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx

COPY . .

RUN groupadd --gid 1001 nodejs \
 && useradd  --uid 1001 --gid nodejs --shell /bin/bash --create-home nodeuser \
 && mkdir -p /app/uploads \
 && chown -R nodeuser:nodejs /app/uploads

USER nodeuser

EXPOSE 3000

CMD ["node", "src/server.js"]