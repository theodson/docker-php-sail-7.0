FROM theodson/php-sail-7.0:1.0-arm64

ARG WWWGROUP
ARG NODE_VERSION=20
ARG POSTGRES_VERSION=9.5

# Build-time metadata
ARG IMAGE_VERSION=1.0.1
ARG BUILD_DATE

# OCI labels
LABEL \
  org.opencontainers.image.title="php-sail-7.0" \
  org.opencontainers.image.version="$IMAGE_VERSION" \
  org.opencontainers.image.created="$BUILD_DATE"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Expose version inside the container
ENV IMAGE_VERSION="$IMAGE_VERSION"
RUN echo "$IMAGE_VERSION" > /etc/IMAGE_VERSION

WORKDIR /var/www/html

ENV SUPERVISOR_PHP_COMMAND="/usr/bin/php -d variables_order=EGPCS /var/www/html/artisan serve --host=0.0.0.0 --port=80"
ENV SUPERVISOR_PHP_USER="sail"

# Installing Chromium for arm64 running in Docker is suprisingly difficult (See build docs)
# Ensure Chromium runtime NSS libraries are present for --version and headless runs
# Playwright's install-deps can occasionally skip or fail under CI; install explicitly.

ENV PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/playwright-browsers
ENV PLAYWRIGHT_CHROMIUM_REVISION="1106"
ENV PLAYWRIGHT_REVISION="1.43.0"

# Tell Puppeteer to skip installing Chrome. We'll be using the installed chrome from playwright.
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Install Chromium browser
RUN mkdir -p $PLAYWRIGHT_BROWSERS_PATH \
    && apt-get install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 libxcomposite1 libxdamage1 \
    && npm -g install playwright@$PLAYWRIGHT_REVISION; \
    npx playwright install-deps || true; \
    npx playwright install chromium || true; \
    chmod -R a+rwx $PLAYWRIGHT_BROWSERS_PATH; \
    apt-get -y autoremove || true; apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "SAIL BUILD DATE $(TZ=$TZ date): $(TZ=Australia/NSW date)" > /etc/SAIL_BUILD; \
    ln -snf $PLAYWRIGHT_BROWSERS_PATH/chromium-*/chrome-linux/chrome /usr/bin/chromium; \
    chmod +x /usr/local/bin/start-container

EXPOSE 80/tcp

ENTRYPOINT ["start-container"]
