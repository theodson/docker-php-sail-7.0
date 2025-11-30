Overview
This directory builds an experimental Ubuntu 24.04 (Noble) arm64 image that includes:

- System PHP 8.0 from `ppa:ondrej/php` for modern tooling (Composer, etc.)
- A from-source build of PHP 7.0.33 intended for legacy projects

The base is Ubuntu 24.04, which ships modern toolchains and libraries (ICU 74, OpenSSL 3, Freetype 2.13+, etc.). PHP 7.0.33 was released in 2018 and expects older ABIs/APIs. Building it on 24.04 requires workarounds documented below.

Goals
- Target architecture: `linux/arm64` (Apple Silicon and ARM servers)
- Base image: `ubuntu:24.04` if possible, then `ubuntu:22.04`
- PHP 7.0.33 built in `/usr/local` (CLI + FPM)
- Keep Sail-like UX (user `sail`, supervisor, start script)
- Include common php extensions: `bz2`, `calendar`, `Core`, `ctype`, `curl`, `date`, `dom`, `exif`, `fileinfo`, `filter`, `ftp`, `gd`, `gd`, `gettext`, `gmp`, `hash`, `igbinary`, `iconv`, `intl`, `json`, `libxml`, `mbstring`, `openssl`, `pcntl`, `pcre`, `PDO`, `pdo_pgsql`, `pgsql`, `Phar`, `posix`, `readline`, `redis`, `Reflection`, `session`, `shmop`, `SimpleXML`, `sockets`, `SPL`, `standard`, `sysvmsg`, `sysvsem`, `sysvshm`, `tokenizer`, `xml`, `xmlreader`, `xmlwriter`, `xsl`, `xsl`, `yaml`, `zip`, `zlib`, 
- Once the common php extensions are built include these: `imagick` ,`sodium` ,`ssh2`
  - Developer tooling: `xdebug` (pinned to 2.7.2 for PHP 7.0) — disabled by default.

Key challenges on Ubuntu 24.04
1) ICU (International Components for Unicode)
   - Ubuntu 24.04 provides ICU 74 (libicu74, `libicu-dev`). PHP 7.0’s intl extension was developed around ICU 57–60.
   - Mixing headers from ICU 74 with older expectations causes build or runtime symbol errors.
   - Approach used here: build and install ICU 59.1 from source into `/usr/local`, then point PHP’s `intl` build to it using `pkg-config`:
     - Ensure `pkg-config` can find ICU-59 by setting `PKG_CONFIG_PATH=/usr/local/lib/pkgconfig` during `./configure` for PHP.
     - Pass `ICU_CFLAGS` and `ICU_LIBS` (see Dockerfile).
   - Note: Avoid installing `libicu-dev` from apt after installing ICU 59.1, as it can introduce conflicting headers and `.pc` files for ICU 74.

2) Freetype2 and GD detection
   - PHP 7.0’s `ext/gd/config.m4` historically preferred `freetype-config` (removed in newer distros) rather than `pkg-config freetype2`.
   - Ubuntu 24.04 no longer ships `freetype-config`.
   - Decision: the `gd-freetype-pkgconfig.patch` approach does not work reliably here. Instead, provide a lightweight `freetype-config` shim that proxies to `pkg-config freetype2` so PHP 7.0’s configure can proceed unchanged.
   - Create `/usr/local/bin/freetype-config` (executable) before running PHP’s `./configure` with the following content:
     ```bash
     #!/usr/bin/env bash
     case "$1" in
       --cflags) pkg-config --cflags freetype2 ;;
       --libs)   pkg-config --libs freetype2 ;;
       --prefix) pkg-config --variable=prefix freetype2 ;;
       --version) pkg-config --modversion freetype2 ;;
       *) echo "usage: freetype-config [--cflags|--libs|--prefix|--version]" >&2; exit 1 ;;
     esac
     ```
   - Ensure it’s on `PATH` (e.g., `/usr/local/bin`) and `chmod +x` it. Keep `libfreetype6-dev` installed so headers and libs exist. You may still pass `FREETYPE_CFLAGS`/`FREETYPE_LIBS` for clarity, but the shim removes the hard stop in `ext/gd`.

3) OpenSSL
   - Ubuntu 24.04 ships OpenSSL 3 (`libssl3`, `libssl-dev` for 3.0). PHP 7.0 does not support OpenSSL 3 APIs and typically fails to compile with them.
   - Decision: build and use OpenSSL 1.1.x and keep `--with-openssl` enabled for PHP 7.0.
   - Reference steps (inside Docker build, prior to PHP configure):
     ```bash
     OPENSSL_VER=1.1.1w
     cd /usr/src && \
       curl -fsSLO https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz && \
       tar xzf openssl-${OPENSSL_VER}.tar.gz && cd openssl-${OPENSSL_VER} && \
       ./Configure linux-aarch64 --prefix=/usr/local/openssl-1.1 --libdir=lib no-shared && \
       make -j$(nproc) && make install_sw && \
       echo "/usr/local/openssl-1.1/lib" > /etc/ld.so.conf.d/openssl-1.1.conf && ldconfig && \
       cd .. && rm -rf openssl-${OPENSSL_VER}* 
     ```
     Then invoke PHP’s configure with:
     ```bash
     CPPFLAGS="-I/usr/local/openssl-1.1/include" \
     LDFLAGS="-L/usr/local/openssl-1.1/lib" \
     PKG_CONFIG_PATH="/usr/local/openssl-1.1/lib/pkgconfig:${PKG_CONFIG_PATH}" \
     ./configure ... --with-openssl=/usr/local/openssl-1.1 ...
     ```
   - Ensure no `libssl-dev` (OpenSSL 3) headers shadow the 1.1 include path during PHP’s build.

4) libonig / mbstring
   - PHP 7.0 bundled Oniguruma; the `libonig-dev` apt package may not match expectations.
   - Decision: If PHP 7.0’s `./configure` errors out with mbstring/Oniguruma issues (e.g., missing `oniguruma.h`, symbol/version mismatches), prefer building WITHOUT external `libonig-dev` and rely on PHP 7.0’s bundled Oniguruma.
   - Practical tip: remove `libonig-dev` from build deps and ensure no stray Oniguruma headers are present in default include paths before re-running `./configure`.

5) XLocale removal
   - Newer libc removed `<xlocale.h>`. Old ICU sources referenced it. The Dockerfile patches ICU sources to include `<locale.h>` and defines `U_HAVE_XLOCALE_H 0` to bypass this header.

Build layout and sequence
1. Install baseline tools, PHP 8.0 and runtime utilities (Node/Yarn/Postgres client) to maintain Sail-like environment.
2. Build ICU 59.1 into `/usr/local` and expose `.pc` files via `PKG_CONFIG_PATH`.
3. Download and extract `php-7.0.33` source under `/usr/src/php-7.0.33`.
4. (If needed) Apply `gd-freetype-pkgconfig.patch` to switch GD’s Freetype detection to `pkg-config`.
5. Configure PHP 7.0 with explicit CFLAGS/LIBS overrides for ICU and Freetype. Use OpenSSL 1.1.x and keep `--with-openssl=/usr/local/openssl-1.1` with `CPPFLAGS`/`LDFLAGS` pointing to it.
6. `make -j$(nproc)` and `make install`.

Environment variables and flags
- ICU
  - `export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}`
  - `ICU_CFLAGS="$(pkg-config --cflags icu-i18n)"`
  - `ICU_LIBS="$(pkg-config --libs icu-i18n)"`
- Freetype
  - `FREETYPE_CFLAGS="$(pkg-config --cflags freetype2)"`
  - `FREETYPE_LIBS="$(pkg-config --libs freetype2)"`

Known failure modes to expect on first run
- OpenSSL: `configure: error: OpenSSL version is too old/unsupported` or compile errors referencing OpenSSL 3 symbols.
- ICU: `undefined reference to 'u_...'` or header mismatches if `libicu-dev` (74) headers are picked instead of ICU 59.1.
- Freetype/GD: `configure: error: freetype.h not found` or `freetype-config: command not found` if the patch/overrides are not applied.

Recommendations and next steps
- OpenSSL: build OpenSSL 1.1.x in `/usr/local/openssl-1.1` and keep `--with-openssl` pointing to that path.
- Ensure the ICU 59.1 pkg-config files are the only ICU ones visible during PHP’s configure step (avoid apt `libicu-dev` after ICU build).
- Freetype: do not use the `gd-freetype-pkgconfig.patch`; instead, include the `freetype-config` shim described above so PHP’s GD detection succeeds on Ubuntu 24.04.
- libonig/mbstring: if configure errors related to Oniguruma/mbstring occur, remove external `libonig-dev` and rebuild so PHP 7.0 uses its bundled Oniguruma.

PECL extensions build hardening and version pins
The Dockerfile now builds PECL extensions in separate layers with stronger error handling and retry logic to improve reliability and caching during CI builds.

- Hardening techniques used:
  - Use `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` for the PECL build section.
  - Prepend each build step with `set -euxo pipefail` to fail fast, echo commands, and propagate pipeline failures.
  - Download tarballs with resilient curl options: `curl -fL -sS --retry 5 --retry-delay 3 --retry-connrefused -O <url>`.
  - Create `/usr/local/etc/conf.d` upfront and drop one `.ini` file per extension for clarity.
  - Split each extension into its own `RUN` layer to maximize Docker cache hits and ease debugging.

- Pinned extensions and versions (known compatible with PHP 7.0.33 on Ubuntu 24.04 arm64):
  - igbinary: `3.2.12` → `extension=igbinary.so`
  - redis: `5.3.7` → `extension=redis.so`
  - yaml: `2.0.4` → `extension=yaml.so` (newer versions can fail to compile on PHP 7.0)
  - imagick: `3.4.4` → `extension=imagick.so` (built against ImageMagick 6 via `libmagickwand-6.q16-dev`)
  - libsodium (sodium): `2.0.23` → `extension=sodium.so`
  - ssh2: `1.3.1` → `extension=ssh2.so`
    - Important: explicitly link against the locally built OpenSSL 1.1 to avoid OpenSSL 3 incompatibility on Ubuntu 24.04.
      - Example (as used in Dockerfile):
        - `CPPFLAGS=-I/usr/local/openssl-1.1/include`
        - `LDFLAGS=-L/usr/local/openssl-1.1/lib`
        - `PKG_CONFIG_PATH=/usr/local/openssl-1.1/lib/pkgconfig:${PKG_CONFIG_PATH}`
        - `./configure --with-php-config=/usr/local/bin/php-config --with-ssh2=/usr`
  - xdebug: `2.7.2` → `zend_extension=xdebug.so` (compatible with PHP 7.0.x)
    - Installed INI defaults (disabled by default to avoid performance cost):
      - `xdebug.default_enable=0`
      - `xdebug.remote_enable=0`

Runtime validation tip
After building, verify modules inside the container (note: use PHP 7.0 path `/usr/local/bin/php`):

```bash
docker run --rm --entrypoint /bin/bash php-sail-7.0ub24:1.1-arm64 -lc \
  "/usr/local/bin/php -v && echo '---modules---' && \
   /usr/local/bin/php -m | egrep '^(bz2|calendar|curl|dom|exif|fileinfo|filter|ftp|gd|gettext|gmp|iconv|intl|json|libxml|mbstring|openssl|pcntl|PDO|pdo_pgsql|pgsql|Phar|posix|readline|redis|igbinary|session|shmop|SimpleXML|sockets|SPL|standard|sysvmsg|sysvsem|sysvshm|tokenizer|xml|xmlreader|xmlwriter|xsl|yaml|zip|zlib|imagick|sodium|ssh2|xdebug)$' || true"
```

How to run the build
```bash
# From the repository root
bash arm64/24.04/build.sh
```

The script runs a local `docker buildx build` targeting arm64 using `arm64/24.04/Dockerfile` with tag `php-sail-7.0ub24:1.1-arm64`.

Troubleshooting outside Docker
- If your host lacks Docker or Buildx, the script will fail quickly with an error like “docker: command not found” or “Cannot connect to the Docker daemon”. Install Docker Desktop (macOS) or Docker Engine (Linux) and enable Buildx.

Change log / open items
- [x] Decide on OpenSSL strategy: build 1.1.x and keep `--with-openssl`.
- [x] Policy confirmed: If configure errors out, prefer building without external `libonig-dev` for PHP 7.0.
- [x] Freetype/GD approach: patch does not work here; use a `freetype-config` shim that proxies to `pkg-config`.
- [x] PECL build hardening: split into separate RUN layers, use bash with `set -euxo pipefail`, and add `curl` retries.
- [x] Xdebug version pin: use `xdebug-2.7.2`, disabled by default via INI.
