FROM php:7.4-fpm AS base

# Arguments defined in docker-compose.yml
ARG user
ARG uid

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip && apt-get clean && rm -rf /var/lib/apt/lists/* && \ 
    docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd && \
    useradd -G www-data,root -u $uid -d /home/$user $user && \
    mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl opcache

# setup php.ini
RUN ln -s /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
COPY docker-compose/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Get latest Composer
FROM composer:2.3.7 AS build

COPY app/composer.json .
COPY app/composer.lock .
RUN composer install --no-dev --no-scripts --ignore-platform-reqs

RUN composer dumpautoload --optimize


# Set working directory
FROM base AS final

COPY ./app /var/www
COPY --from=build /app/vendor /var/www/vendor
