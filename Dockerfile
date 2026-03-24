# syntax=docker/dockerfile:1

###############################################################################
# Frontend (React / CRA) -> build + nginx runtime (no extra files needed)
###############################################################################

FROM node:20-alpine AS frontend-build

WORKDIR /app

# Install dependencies first for better layer caching
COPY package.json package-lock.json ./
RUN npm ci

# Build only after dependencies are cached
COPY public ./public
COPY src ./src

# CRA uses REACT_APP_* variables at build time.
ARG REACT_APP_API_BASE_URL=http://localhost:8000/
ENV REACT_APP_API_BASE_URL=$REACT_APP_API_BASE_URL

# Build production bundle
RUN npm run build

FROM nginxinc/nginx-unprivileged:alpine AS frontend

# Serve the compiled React app.
COPY --from=frontend-build /app/build /usr/share/nginx/html

# SPA-friendly nginx config (BrowserRouter requires history fallback).
RUN rm -f /etc/nginx/conf.d/default.conf && \
    printf '%s\n' \
      'server {' \
      '  listen 8080;' \
      '  server_name _;' \
      '  root /usr/share/nginx/html;' \
      '  index index.html;' \
      '  location / {' \
      '    try_files $uri $uri/ /index.html;' \
      '  }' \
      '}' \
      > /etc/nginx/conf.d/default.conf

EXPOSE 8080

###############################################################################
# Backend (Django + DRF) -> gunicorn runtime
###############################################################################

FROM python:3.12-slim AS backend

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Install Python deps first for better layer caching
COPY backend/mohamed/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source
COPY backend/mohamed ./backend

# Create runtime directories and run as non-root
RUN adduser --disabled-password --gecos '' appuser && \
    mkdir -p /app/backend/media /app/backend/staticfiles && \
    chown -R appuser:appuser /app/backend

WORKDIR /app/backend
USER appuser

# Pre-collect static assets (served by WhiteNoise at runtime)
RUN python manage.py collectstatic --noinput

EXPOSE 8000

# Production startup:
# 1) wait for postgres (if enabled),
# 2) run migrations,
# 3) start gunicorn.
CMD ["sh", "-c", "\
if [ \"${USE_POSTGRES:-false}\" = \"true\" ] || [ \"${USE_POSTGRES:-false}\" = \"1\" ]; then \
  echo \"Waiting for Postgres...\"; \
  success=0; i=0; \
  while [ $i -lt 60 ]; do \
    python -c 'import os, socket; host=os.environ.get(\"POSTGRES_HOST\",\"db\"); port=int(os.environ.get(\"POSTGRES_PORT\",\"5432\")); s=socket.create_connection((host,port),timeout=2); s.close()' && success=1 && break; \
    i=$((i+1)); \
    sleep 2; \
  done; \
  if [ $success -ne 1 ]; then echo \"Postgres not reachable\"; exit 1; fi; \
fi; \
python manage.py migrate --noinput; \
gunicorn --bind 0.0.0.0:8000 --workers 3 --threads 2 --timeout 120 setting.wsgi:application
"]

