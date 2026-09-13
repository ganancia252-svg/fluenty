# Builda o front e prepara o servidor completo do Fluenta.
FROM node:20-bookworm-slim AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Imagem de produção menor: o servidor serve a API e o dist/ do Vite.
FROM node:20-bookworm-slim AS production
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=10000
ENV DATA_DIR=/data

COPY package*.json ./
RUN npm ci --omit=dev && mkdir -p /data
COPY server ./server
COPY dist ./dist

EXPOSE 10000
CMD ["node", "server/index.js"]
