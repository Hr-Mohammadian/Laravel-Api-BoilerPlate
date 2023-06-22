# Start with the official PHP 8.1 image
ARG PHP_VERSION=8.1
FROM php:${PHP_VERSION}-cli-buster

# Install system dependencies
RUN apt-get update; \
    apt-get upgrade -yqq; \
    pecl -q channel-update pecl.php.net; \
    apt-get install -yqq --no-install-recommends --show-progress \
          apt-utils \
          gnupg \
          gosu \
          git \
          curl \
          wget \
          libcurl4-openssl-dev \
          ca-certificates \
          supervisor \
          libmemcached-dev \
          libz-dev \
          libbrotli-dev \
          libpq-dev \
          libjpeg-dev \
          libpng-dev \
          libfreetype6-dev \
          libssl-dev \
          libwebp-dev \
          libmcrypt-dev \
          libonig-dev \
          libzip-dev zip unzip \
          libargon2-1 \
          libidn2-0 \
          libpcre2-8-0 \
          libpcre3 \
          libxml2 \
          libzstd1 \
          procps \
          libbz2-dev \
          vim


# Update the CA certificate store
#RUN update-ca-certificates
# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Redis
RUN pecl install redis && docker-php-ext-enable redis
RUN apt-get update && apt-get install -y redis-server

###########################################
# bzip2
###########################################

RUN docker-php-ext-install bz2;

###########################################
# pdo_mysql
###########################################

RUN docker-php-ext-install pdo_mysql;

###########################################
# zip
###########################################

RUN docker-php-ext-configure zip && docker-php-ext-install zip;

###########################################
# mbstring
###########################################

RUN docker-php-ext-install mbstring;

###########################################
# GD
###########################################

RUN docker-php-ext-configure gd \
            --prefix=/usr \
            --with-jpeg \
            --with-webp \
            --with-freetype \
    && docker-php-ext-install gd;

###########################################
# PHP Redis
###########################################

RUN apt-get install -y redis-server;
#COPY ./docker-configs/redis/redis.conf /usr/local/etc/redis/redis.conf
RUN echo "protected-mode no" >> /etc/redis/redis.conf;
EXPOSE 6379
###########################################
# PCNTL
###########################################

ARG INSTALL_PCNTL=true

RUN if [ ${INSTALL_PCNTL} = true ]; then \
      docker-php-ext-install pcntl; \
  fi

###########################################
# BCMath
###########################################

ARG INSTALL_BCMATH=true

RUN if [ ${INSTALL_BCMATH} = true ]; then \
      docker-php-ext-install bcmath; \
  fi

###########################################
# Laravel scheduler
###########################################


RUN apt-get update && apt-get install -y supervisor
COPY docker-configs/supervisord* /etc/supervisor/conf.d/
# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy existing application directory contents
COPY . /var/www
# Copy the specific .env.docker.local file to .env
COPY .env.example.docker .env
# Install any defined in composer.lock
RUN composer install

RUN chmod +x docker-configs/entrypoint.sh
RUN if [ -f "rr" ]; then \
    chmod +x rr; \
  fi
# Generate a new application key
#RUN php artisan key:generate
#RUN php artisan migrate:fresh --seed
#RUN php artisan optimize

# Expose port 8000 for the application
EXPOSE 8000
# Start Redis server
#CMD redis-server --daemonize yes
#RUN service redis-server start /usr/local/etc/redis/redis.conf --daemonize yes
#RUN service redis-server start /usr/local/etc/redis/redis.conf --daemonize yes
#RUN service redis-server start
# Start the Laravel queue worker
#RUN php artisan queue:work --tries=3
# Start the Laravel scheduler
#RUN cron && tail -f /var/log/cron.log
# Start the Laravel server
#RUN php artisan serve --host=0.0.0.0 --port=8000
ENTRYPOINT ["docker-configs/entrypoint.sh"]
