# ==========================================
# Stage 1: Build frontend assets with Vite
# ==========================================
FROM node:20-alpine AS frontend
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build || true

# ==========================================
# Stage 2: Install Composer dependencies
# ==========================================
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-scripts


# ==========================================
# Stage 3: Production runtime with PHP 8.3
# ==========================================
FROM php:8.3-cli-bookworm

# Install required PHP extensions for Laravel & PostgreSQL / MySQL / SQLite
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    pdo_pgsql \
    pdo_mysql \
    pdo_sqlite \
    bcmath \
    ctype \
    curl \
    dom \
    fileinfo \
    filter \
    hash \
    mbstring \
    openssl \
    pcre \
    session \
    tokenizer \
    xml \
    zip \
    intl \
    opcache \
    gd \
    redis

WORKDIR /app

# Copy application source code
COPY . .
COPY --from=vendor /app/vendor ./vendor
COPY --from=frontend /app/public/build ./public/build

# Copy frontend distribution assets to public if present
RUN if [ -d "/app/frontend/dist" ]; then \
        cp -rn /app/frontend/dist/* /app/public/ 2>/dev/null || true; \
    fi

# Set permissions for storage and bootstrap cache
RUN mkdir -p /app/storage/framework/cache/data \
             /app/storage/framework/sessions \
             /app/storage/framework/views \
             /app/storage/logs \
             /app/bootstrap/cache \
    && chown -R www-data:www-data /app/storage /app/bootstrap/cache \
    && chmod -R 775 /app/storage /app/bootstrap/cache

# Environment defaults
ENV PORT=8000
ENV APP_ENV=production
ENV APP_DEBUG=false

EXPOSE 8000

# Entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["sh", "-c", "php artisan serve --host=0.0.0.0 --port=${PORT:-8000}"]

