FROM php:7.4-fpm

ARG CURRENT_USER

RUN usermod -u ${CURRENT_USER? invalid argument} www-data
RUN groupmod -g ${CURRENT_USER? invalid argument} www-data

# Install dependencies
RUN apt-get -qq update && apt-get -qq install -y \
    libonig-dev \
    build-essential \
    libmcrypt-dev \
    libpq-dev \
    git \
    vim \
    zip \
    unzip \
    openssl \
    zlib1g-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    sqlite3 \
    jpegoptim optipng pngquant gifsicle \
    libsqlite3-dev  \
    curl

# Clear cache
RUN rm -rf /var/lib/apt/lists/*

RUN apt-get update -yqq && \
    apt-get install -y apt-utils && \
    pecl channel-update pecl.php.net

RUN apt-get update && apt-get install -y wget git unzip \
    && pecl install xdebug-2.9.0 \
    && docker-php-ext-enable xdebug

# Install extensions
RUN docker-php-ext-install mysqli pdo pdo_mysql zip mbstring tokenizer bcmath
RUN docker-php-ext-install -j$(nproc) iconv
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# install redis
RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini

RUN pear install PHP_CodeSniffer

RUN /usr/local/bin/phpcs --config-set show_progress 1 && \
    /usr/local/bin/phpcs --config-set colors 1 && \
    /usr/local/bin/phpcs --config-set report_width 140 && \
    /usr/local/bin/phpcs --config-set encoding utf-8 && \
    /usr/local/bin/phpcs --config-set severity 1

# Clean
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*
RUN chown -R ${CURRENT_USER} /var/www
