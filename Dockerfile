FROM php:8.2-fpm as php

# Set environment variables
ENV PHP_OPCACHE_ENABLE=1
ENV PHP_OPCACHE_ENABLE_CLI=0
ENV PHP_OPCACHE_VALIDATE_TIMESTAMP=0
ENV PHP_OPCACHE_REVALIDATE_FREQ=0

# Install dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    libpq-dev \
    libcurl4-gnutls-dev \
    libonig-dev \
    libgd-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libfreetype6-dev \
    libwebp-dev \
    zlib1g-dev \
    git \
    supervisor \
    libaio1 \
    libpcre3-dev

# Install PHP extensions
RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    bcmath \
    curl \
    opcache \
    mbstring \
    gd \
    pcntl

# Install Swoole extension
RUN pecl install swoole && docker-php-ext-enable swoole


# Add composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory and copy laravel project there
WORKDIR /var/www


COPY --chown=www-data:www-data . .


RUN composer install
# Install Laravel Octane
RUN composer require laravel/octane --dev


# Create a script to run octane install in non-interactive mode
RUN echo 'php artisan octane:install --server="swoole"' > install_octane.sh && \
    chmod +x install_octane.sh && \
    ./install_octane.sh

RUN php artisan vendor:publish --tag=octane-config

# Create laravel caching folders
RUN mkdir -p /var/www/storage/framework/{cache,testing,sessions,views}
RUN mkdir -p /var/www/resources/views

# Fix files ownership
RUN chown -R www-data /var/www/storage \
    && chown -R www-data /var/www/storage/framework \
    && chown -R www-data /var/www/storage/framework/sessions \
    && chown -R www-data /var/www/resources/views

# Set correct permission
RUN chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/storage/logs \
    && chmod -R 755 /var/www/storage/framework \
    && chmod -R 755 /var/www/storage/framework/sessions \
    && chmod -R 755 /var/www/bootstrap \
    && chmod -R 755 /var/www/resources/views


# Adjust user permission & group
RUN usermod --uid 1000 www-data \
    && groupmod --gid 1001 www-data

# Run the entrypoint file
ENTRYPOINT [ "docker/swoole.sh" ]
