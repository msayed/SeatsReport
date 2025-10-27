FROM node:20-bookworm-slim AS build
WORKDIR /app

ARG VITE_API_BASE=http://localhost:8081
ENV VITE_API_BASE=${VITE_API_BASE}

COPY package*.json ./

RUN npm config set strict-ssl false \
    && npm config set registry "https://registry.npmjs.org/" \
    && npm ci

COPY . .
RUN npm run build


# ---------- Nginx serve ----------
FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
