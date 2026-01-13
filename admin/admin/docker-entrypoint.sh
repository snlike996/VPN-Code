#!/bin/bash
set -e

if [ ! -d "/var/www/html/vendor" ]; then
  echo "Installing Composer dependencies..."
  cd /var/www/html
  composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# ensure permissions
chown -R www-data:www-data storage bootstrap/cache || true

exec "$@"
