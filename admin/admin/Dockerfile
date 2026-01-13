FROM php:8.2-apache

# system deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libicu-dev libpng-dev libzip-dev libonig-dev libcurl4-openssl-dev unzip git \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-configure intl && \
    docker-php-ext-install -j$(nproc) mysqli pdo pdo_mysql mbstring intl gd zip curl opcache

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Apache rewrite
RUN a2enmod rewrite

WORKDIR /var/www/html

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
