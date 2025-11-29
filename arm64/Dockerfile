FROM ubuntu:24.04

LABEL maintainer="Taylor Otwell"

ARG WWWGROUP
ARG NODE_VERSION=20
ARG POSTGRES_VERSION=9.5
ARG PHP_DEBUG=''

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV SUPERVISOR_PHP_COMMAND="/usr/bin/php -d variables_order=EGPCS /var/www/html/artisan serve --host=0.0.0.0 --port=80"
ENV SUPERVISOR_PHP_USER="sail"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::BrokenProxy    true;" >> /etc/apt/apt.conf.d/99custom

RUN apt-get update && apt-get upgrade -y \
    && mkdir -p /etc/apt/keyrings \
    && apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python3 dnsutils librsvg2-bin fswatch ffmpeg nano \
    && curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xb8dc7e53946656efbce4c1dd71daeaab4ad4cab6' | gpg --dearmor | tee /usr/share/keyrings/ppa_ondrej_php.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update \
    && apt-get install -y php8.0-cli php8.0-dev \
       php8.0-pgsql php8.0-sqlite3 php8.0-gd php8.0-imagick \
       php8.0-curl php8.0-memcached php8.0-mongodb \
       php8.0-imap php8.0-mysql php8.0-mbstring \
       php8.0-xml php8.0-zip php8.0-bcmath php8.0-soap \
       php8.0-intl php8.0-readline php8.0-pcov \
       php8.0-msgpack php8.0-igbinary php8.0-ldap \
       php8.0-redis php8.0-swoole php8.0-xdebug \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && npm install -g bun \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /usr/share/keyrings/pgdg.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt noble-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y yarn \
    && apt-get install -y mysql-client \
    && apt-get install -y postgresql-client-$POSTGRES_VERSION \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-alternatives --set php /usr/bin/php8.0

RUN setcap "cap_net_bind_service=+ep" /usr/bin/php8.0

RUN userdel -r ubuntu
RUN groupadd --force -g $WWWGROUP sail
RUN useradd -ms /bin/bash --no-user-group -g $WWWGROUP -u 1337 sail
RUN git config --global --add safe.directory /var/www/html

COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/8.0/cli/conf.d/99-sail.ini
RUN chmod +x /usr/local/bin/start-container


# ---------------------------------------------------------
# The following deviates from the standard Laravel Sail BUILT to add Php7.0 support (yes in 2025!)
#
# Install build dependencies for PHP 7.0
# Additional toolchain to build curl with GnuTLS (avoid OpenSSL in libcurl) \
# ---------------------------------------------------------
ENV PHP_VERSION=7.0.33
ENV ICU_VERSION=59_1
ENV ICU_VERSION_RELEASE=59-1
ENV OPENSSL_VER=1.1.1w
ENV CURL_VER=8.7.1

RUN apt-get update \
    && apt-get install -y \
    ca-certificates \
    build-essential \
    autoconf \
    pkg-config \
    libxml2-dev libssl-dev libsqlite3-dev libbz2-dev libgmp-dev libpq-dev libjpeg-dev libpng-dev libwebp-dev \
    libfreetype6-dev libzip-dev libreadline-dev libxslt1-dev libyaml-dev libmagickwand-6.q16-dev imagemagick-6.q16 imagemagick-6-common libmagickcore-6.q16-7-extra libsodium-dev libssh2-1-dev \
    libgettextpo-dev zlib1g-dev libbison-dev libnss3 libnspr4 \
    libgnutls28-dev nettle-dev libidn2-0-dev libpsl-dev libbrotli-dev zlib1g-dev \
    gettext bison  re2c  wget  git  curl  nginx iputils-ping curl wget httpie traceroute \
    vim ripgrep gettext-base unzip zip git docutils-common htop redis-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

# Fix ICU incompatible version
# Apply patch to ICU to remove xlocale.h
# This patch simply replaces `#include <xlocale.h>` with `#include <locale.h>` in ICU source
# ---------------------------------------------------------
# Build OpenSSL 1.1.x (PHP 7.0 is incompatible with OpenSSL 3)
# ---------------------------------------------------------

# ---------------------------------------------------------
# Build libcurl with GnuTLS (prevents OpenSSL 3 from loading via system libcurl)
# ---------------------------------------------------------

RUN wget https://github.com/unicode-org/icu/releases/download/release-${ICU_VERSION_RELEASE}/icu4c-${ICU_VERSION}-src.tgz \
    && tar -xzf icu4c-${ICU_VERSION}-src.tgz \
    && sed -i 's|# *include *<xlocale.h>|#include <locale.h>|g' icu/source/i18n/*.cpp icu/source/common/*.cpp icu/source/i18n/*.cpp \
    && echo "#ifndef U_HAVE_XLOCALE_H\n#define U_HAVE_XLOCALE_H 0\n#endif" >> icu/source/common/unicode/utypes.h; \
    cd icu/source \
    && ./configure --prefix=/usr/local \
    && make -j$(nproc) && make install \
    && cd ../.. \
    && rm -rf icu4c-${ICU_VERSION}-src.tgz icu; \
    cd /usr/src \
    && curl -fsSLO https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz \
    && tar xzf openssl-${OPENSSL_VER}.tar.gz \
    && cd openssl-${OPENSSL_VER} \
    && ./Configure linux-aarch64 --prefix=/usr/local/openssl-1.1 --libdir=lib no-shared \
    && make -j$(nproc) \
    && make install_sw \
    && echo "/usr/local/openssl-1.1/lib" > /etc/ld.so.conf.d/openssl-1.1.conf \
    && ldconfig \
    && cd .. \
    && rm -rf openssl-${OPENSSL_VER}*; \
    cd /usr/src \
    && curl -fsSLO https://curl.se/download/curl-${CURL_VER}.tar.gz \
    && tar xzf curl-${CURL_VER}.tar.gz \
    && cd curl-${CURL_VER} \
    && PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig \
       ./configure \
          --prefix=/usr/local/curl-gnutls \
          --with-gnutls \
          --enable-ipv6 \
          --disable-static \
          --with-zlib \
          --with-brotli \
          --with-libidn2 \
          --with-libpsl \
    && make -j"$(nproc)" \
    && make install \
    && echo "/usr/local/curl-gnutls/lib" > /etc/ld.so.conf.d/curl-gnutls.conf \
    && ldconfig \
    && cd .. \
    && rm -rf curl-${CURL_VER}*

# Download PHP 7.0.33
RUN wget https://www.php.net/distributions/php-7.0.33.tar.gz \
  && tar xzf php-7.0.33.tar.gz && rm php-7.0.33.tar.gz

ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/openssl-1.1/lib/pkgconfig:/usr/local/curl-gnutls/lib/pkgconfig

WORKDIR /usr/src/php-7.0.33

# Provide a freetype-config shim that proxies to pkg-config (Ubuntu 24.04 no longer ships freetype-config)
# Configure PHP
RUN printf '#!/usr/bin/env bash\ncase "$1" in\n  --cflags) pkg-config --cflags freetype2 ;;\n  --libs)   pkg-config --libs freetype2 ;;\n  --prefix) pkg-config --variable=prefix freetype2 ;;\n  --version) pkg-config --modversion freetype2 ;;\n  *) echo "usage: freetype-config [--cflags|--libs|--prefix|--version]" >&2; exit 1 ;;\n esac\n' > /usr/local/bin/freetype-config \
    && chmod +x /usr/local/bin/freetype-config; \
    CPPFLAGS="-I/usr/local/openssl-1.1/include" \
    LDFLAGS="-L/usr/local/openssl-1.1/lib -L/usr/local/curl-gnutls/lib -Wl,-rpath,/usr/local/openssl-1.1/lib -Wl,-rpath,/usr/local/curl-gnutls/lib" \
    ./configure \
    --prefix=/usr \
    --program-suffix=7.0 \
    --with-config-file-path=/etc/php/7.0/cli \
    --with-config-file-scan-dir=/etc/php/7.0/cli/conf.d/ \
    $PHP_DEBUG \
    --enable-fpm \
    --with-fpm-user=www-data \
    --with-fpm-group=www-data \
    --enable-mbstring \
    --with-bz2 \
    --enable-calendar \
    --enable-zip \
    --enable-soap \
    --enable-intl \
    --enable-exif \
    --enable-opcache \
    --enable-ftp \
    --with-curl=/usr/local/curl-gnutls \
    --with-openssl=/usr/local/openssl-1.1 \
    --with-zlib \
    --with-gettext \
    --with-gmp \
    --with-xsl \
    --with-pdo-mysql \
    --with-mysqli \
    --with-pdo-sqlite \
    --with-pgsql=/usr \
    --with-pdo-pgsql=/usr \
    --with-gd \
    --with-jpeg-dir=/usr \
    --with-webp-dir=/usr \
    --with-freetype-dir=/usr \
    --with-readline \
    --enable-pcntl \
    --enable-shmop \
    --enable-sockets \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    ICU_CFLAGS="$(pkg-config --cflags icu-i18n)" \
    ICU_LIBS="$(pkg-config --libs icu-i18n)" \
    FREETYPE_CFLAGS="$(pkg-config --cflags freetype2)" \
    FREETYPE_LIBS="$(pkg-config --libs freetype2)" \
    && echo "# Build & install" \
    && make -j$(nproc) && make install

# ---------------------------------------------------------
# Build and install PECL extensions for PHP 7.0 (pinned versions)
# Now split into separate layers for better caching/debugging and add retry logic
# igbinary, redis, yaml, imagick, libsodium (sodium), ssh2, xdebug
# ---------------------------------------------------------

# Installing Chromium for arm64 running in Docker is suprisingly difficult (See build docs)
# Ensure Chromium runtime NSS libraries are present for --version and headless runs
# Playwright's install-deps can occasionally skip or fail under CI; install explicitly.

ENV PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/playwright-browsers
ENV PLAYWRIGHT_CHROMIUM_REVISION="1106"
ENV PLAYWRIGHT_REVISION="1.43.0"

# Tell Puppeteer to skip installing Chrome. We'll be using the installed chrome from playwright.
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

ENV PECL_BUILD_DIR=/usr/src/pecl

# Use bash for subsequent RUN steps to allow 'set -o pipefail'
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Prepare build workspace and conf.d
RUN set -euxo pipefail; \
    mkdir -p "$PECL_BUILD_DIR" /etc/php/7.0/cli/conf.d; \
    echo "; Enable PECL extensions" > /etc/php/7.0/cli/conf.d/00-pecl.ini; \
    echo "# igbinary" \
    && set -euxo pipefail; \
    cd "$PECL_BUILD_DIR"; \
    curl -fL -sS --retry 5 --retry-delay 3 --retry-connrefused -O https://pecl.php.net/get/igbinary-3.2.12.tgz; \
    tar xzf igbinary-3.2.12.tgz; \
    cd igbinary-3.2.12; \
    /usr/bin/phpize7.0; \
    ./configure --with-php-config=/usr/bin/php-config7.0; \
    make -j"$(nproc)" && make install; \
    echo "extension=igbinary.so" > /etc/php/7.0/cli/conf.d/10-igbinary.ini; \
    echo "# redis"; \
    set -euxo pipefail; \
    cd "$PECL_BUILD_DIR"; \
    curl -fL -sS --retry 5 --retry-delay 3 --retry-connrefused -O https://pecl.php.net/get/redis-5.3.7.tgz; \
    tar xzf redis-5.3.7.tgz; \
    cd redis-5.3.7; \
    /usr/bin/phpize7.0; \
    ./configure --with-php-config=/usr/bin/php-config7.0; \
    make -j"$(nproc)" && make install; \
    echo "extension=redis.so" > /etc/php/7.0/cli/conf.d/20-redis.ini; \
    echo "# yaml (pinned 2.0.4 for PHP 7.0 compatibility)"; \
    set -euxo pipefail; \
    cd "$PECL_BUILD_DIR"; \
    curl -fL -sS --retry 5 --retry-delay 3 --retry-connrefused -O https://pecl.php.net/get/yaml-2.0.4.tgz; \
    tar xzf yaml-2.0.4.tgz; \
    cd yaml-2.0.4; \
    /usr/bin/phpize7.0; \
    ./configure --with-php-config=/usr/bin/php-config7.0; \
    make -j"$(nproc)" && make install; \
    echo "extension=yaml.so" > /etc/php/7.0/cli/conf.d/20-yaml.ini; \
    echo "# imagick (pinned 3.4.4; ImageMagick 6 via libmagickwand-6.q16-dev)"; \
    set -euxo pipefail; \
    cd "$PECL_BUILD_DIR"; \
    curl -fL -sS --retry 5 --retry-delay 3 --retry-connrefused -O https://pecl.php.net/get/imagick-3.4.4.tgz; \
    tar xzf imagick-3.4.4.tgz; \
    cd imagick-3.4.4; \
    /usr/bin/phpize7.0; \
    PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" ./configure --with-php-config=/usr/bin/php-config7.0; \
    make -j"$(nproc)" && make install; \
    echo "extension=imagick.so" > /etc/php/7.0/cli/conf.d/20-imagick.ini; \
    echo "# libsodium (extension name sodium)"; \
    set -euxo pipefail; \
    cd "$PECL_BUILD_DIR"; \
    curl -fL -sS --retry 5 --retry-delay 3 --retry-connrefused -O https://pecl.php.net/get/libsodium-2.0.23.tgz; \
    tar xzf libsodium-2.0.23.tgz; \
    cd libsodium-2.0.23; \
    /usr/bin/phpize7.0; \
    ./configure --with-php-config=/usr/bin/php-config7.0; \
    make -j"$(nproc)" && make install; \
    echo "extension=sodium.so" > /etc/php/7.0/cli/conf.d/20-sodium.ini; \
    echo "# ssh2 (link explicitly with OpenSSL 1.1)"; \
    set -euxo pipefail; \
    cd "$PECL_BUILD_DIR"; \
    curl -fL -sS --retry 5 --retry-delay 3 --retry-connrefused -O https://pecl.php.net/get/ssh2-1.3.1.tgz; \
    tar xzf ssh2-1.3.1.tgz; \
    cd ssh2-1.3.1; \
    /usr/bin/phpize7.0; \
    CPPFLAGS="-I/usr/local/openssl-1.1/include" \
    LDFLAGS="-L/usr/local/openssl-1.1/lib" \
    PKG_CONFIG_PATH="/usr/local/openssl-1.1/lib/pkgconfig:${PKG_CONFIG_PATH}" \
    ./configure --with-php-config=/usr/bin/php-config7.0 --with-ssh2=/usr; \
    make -j"$(nproc)" && make install; \
    echo "extension=ssh2.so" > /etc/php/7.0/cli/conf.d/20-ssh2.ini; \
    echo "# xdebug (PHP 7.0 compatible: 2.7.2)"; \
    set -euxo pipefail; \
    cd "$PECL_BUILD_DIR"; \
    curl -fL -sS --retry 5 --retry-delay 3 --retry-connrefused -O https://pecl.php.net/get/xdebug-2.7.2.tgz; \
    tar xzf xdebug-2.7.2.tgz; \
    cd xdebug-2.7.2; \
    /usr/bin/phpize7.0; \
    ./configure --with-php-config=/usr/bin/php-config7.0; \
    make -j"$(nproc)" && make install; \
    echo "zend_extension=xdebug.so" > /etc/php/7.0/cli/conf.d/20-xdebug.ini; \
    echo "xdebug.default_enable=0" >> /etc/php/7.0/cli/conf.d/20-xdebug.ini; \
    echo "xdebug.remote_enable=0"  >> /etc/php/7.0/cli/conf.d/20-xdebug.ini; \
    echo "xdebug.remote_host=host.docker.internal" >> /etc/php/7.0/cli/conf.d/20-xdebug.ini; \
    echo "xdebug.remote_port='9003'"  >> /etc/php/7.0/cli/conf.d/20-xdebug.ini;

RUN update-alternatives --install /usr/bin/php php /usr/bin/php7.0 110 \
    && update-alternatives --set php /usr/bin/php7.0 \
    && update-alternatives --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm7.0 110 \
    && update-alternatives --set php-fpm /usr/sbin/php-fpm7.0; \
    setcap "cap_net_bind_service=+ep" /usr/bin/php7.0; \
    echo "# Php 7.0 needs composer 2.2"; \
    curl -sLS https://getcomposer.org/installer | php -- --2.2 --install-dir=/usr/bin/ --filename=composer; \
    echo "# Load developer helper functions when starting interactive shell with www container" >> /home/sail/.profile; \
    echo 'source $HOME/bin/functions' >> /home/sail/.profile

# Install Chromium browser
RUN mkdir -p $PLAYWRIGHT_BROWSERS_PATH \
    && apt-get install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 libxcomposite1 libxdamage1 \
    && npm -g install playwright@$PLAYWRIGHT_REVISION; \
    npx playwright install-deps || true; \
    npx playwright install chromium || true; \
    chmod -R a+rwx $PLAYWRIGHT_BROWSERS_PATH; \
    apt-get -y autoremove || true; apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Cleanup PECL build dir at the end
RUN set -euxo pipefail; \
    rm -rf "$PECL_BUILD_DIR" /usr/src/* && \
    # Purge heavy build toolchains and -dev packages that are no longer needed at runtime \
    apt-get purge -y --auto-remove build-essential autoconf pkg-config bison re2c || true; \
    # Remove static libs and libtool files \
    find /usr -type f -name '*.a' -o -name '*.la' -delete || true; \
    # Strip common binaries/libraries where safe (ignore failures) \
    strip --strip-unneeded /usr/bin/php7.0 /usr/sbin/php-fpm7.0 || true; \
    strip --strip-unneeded /usr/local/openssl-1.1/lib/*.so* /usr/local/curl-gnutls/lib/*.so* || true; \
    rm -rf /usr/share/doc /usr/share/man /usr/share/info /usr/share/lintian || true; \
    npm cache clean --force || true; \
    yarn cache clean || true; \
    composer clear-cache || true; \
    # Cleanup language/docs and caches \
    rm -rf /root/.cache /home/sail/.cache /var/cache/*; \
    apt-get -y autoremove || true; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#RUN cd $PLAYWRIGHT_BROWSERS_PATH \
#  && wget https://playwright.azureedge.net/builds/chromium/$PLAYWRIGHT_CHROMIUM_REVISION/chromium-linux-arm64.zip -O chromium-linux-arm64.$PLAYWRIGHT_CHROMIUM_REVISION.zip \
#  && unzip chromium-linux-arm64.$PLAYWRIGHT_CHROMIUM_REVISION.zip -d chromium-$PLAYWRIGHT_CHROMIUM_REVISION \
#  && cd $PLAYWRIGHT_BROWSERS_PATH && rm chromium-linux-arm64.$PLAYWRIGHT_CHROMIUM_REVISION.zip; \
#  chmod +x $PLAYWRIGHT_BROWSERS_PATH/chromium-$PLAYWRIGHT_CHROMIUM_REVISION/chrome-linux/chrome
#   npm -g install playwright@1.43.0 installs chromium build 1112 is installed. https://playwright-akamai.azureedge.net/builds/chromium/1112/chromium-linux-arm64.zip


RUN echo "SAIL BUILD DATE $(TZ=$TZ date): $(TZ=Australia/NSW date)" > /etc/SAIL_BUILD; \
    ln -snf $PLAYWRIGHT_BROWSERS_PATH/chromium-*/chrome-linux/chrome /usr/bin/chromium; \
    chmod +x /usr/local/bin/start-container

COPY ../functions /home/sail/bin/
COPY ../php.ini /etc/php/7.0/cli/conf.d/99-sail.ini

RUN chmod +x /usr/local/bin/start-container

WORKDIR /var/www/html

EXPOSE 80/tcp

ENTRYPOINT ["start-container"]
