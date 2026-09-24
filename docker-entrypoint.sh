#!/bin/sh
set -e

echo "=== Starting Hospital SaaS Container ==="

# Ensure directories exist and have proper permissions
mkdir -p /app/storage/framework/cache/data
mkdir -p /app/storage/framework/sessions
mkdir -p /app/storage/framework/views
mkdir -p /app/storage/logs
mkdir -p /app/bootstrap/cache
chown -R www-data:www-data /app/storage /app/bootstrap/cache
chmod -R 775 /app/storage /app/bootstrap/cache

# SQLite support if used
if [ "${DB_CONNECTION}" = "sqlite" ] || [ -z "${DB_CONNECTION}" ] && [ -z "${DB_HOST}" ]; then
    mkdir -p /app/database
    touch /app/database/database.sqlite
    chown -R www-data:www-data /app/database
fi

# Ensure valid APP_KEY
if [ -z "$APP_KEY" ] || [ "${#APP_KEY}" -lt 10 ]; then
    export APP_KEY="base64:7KxWZwMdQC/ZhS9n1rlLSBHaXW+qfage2Ses1UaH+os="
fi

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force || echo "Notice: Migrations skipped or database not ready yet."

# Clear and cache configurations for optimal production performance
php artisan config:clear || true
php artisan route:clear || true
php artisan view:clear || true

echo "=== Application Ready. Starting Web Server on port ${PORT:-8000} ==="
exec "$@"
