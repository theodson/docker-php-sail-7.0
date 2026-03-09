# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] 
### Added
- ImageMagick module and delegate support for HTTPS in Dockerfiles. ([cc70529](https://github.com/theodson/docker-php-sail-7.0/commit/cc70529))
- PNG support to arm64 Dockerfile. ([0d600ab](https://github.com/theodson/docker-php-sail-7.0/commit/0d600ab))
### Changed
- Improved `build.sh` to validate and normalize `DOCKERID`. ([9fe9a9f](https://github.com/theodson/docker-php-sail-7.0/commit/9fe9a9f))
- Updated README with corrected Laravel Sail image links, version details, multi-architecture build details, and OrbStack compatibility. ([0d10532](https://github.com/theodson/docker-php-sail-7.0/commit/0d10532), [ac92441](https://github.com/theodson/docker-php-sail-7.0/commit/ac92441))
- Improved cleanup steps in arm64 Dockerfile. ([0d600ab](https://github.com/theodson/docker-php-sail-7.0/commit/0d600ab))

## [2.0.0] - 2025-12-01
### Added
- **Multi-architecture support**: Full support for both `amd64` and `arm64` (Apple Silicon) architectures. ([2d451fe](https://github.com/theodson/docker-php-sail-7.0/commit/2d451fe))
- **Ubuntu 24.04 (Noble)** support: The image now uses Ubuntu 24.04 as its base for v2.0. ([24d2e7b](https://github.com/theodson/docker-php-sail-7.0/commit/24d2e7b))
- **PHP 7.0 from source**: Since Ubuntu 24.04 lacks native PHP 7.0 packages, it is now compiled from source. ([24d2e7b](https://github.com/theodson/docker-php-sail-7.0/commit/24d2e7b))
- **Chromium/Playwright support**: Included for PDF generation (compatible with `spatie/browsershot`). ([c73d9e8](https://github.com/theodson/docker-php-sail-7.0/commit/c73d9e8))
- New `build.sh` script for unified multi-platform builds using Docker Buildx. ([1bf6872](https://github.com/theodson/docker-php-sail-7.0/commit/1bf6872))
### Changed
- Refactored documentation: moved `NOTES.md` to `docs/NOTES.md`. ([2bcf72d](https://github.com/theodson/docker-php-sail-7.0/commit/2bcf72d))
- Updated README with v2 installation and usage instructions. ([24d2e7b](https://github.com/theodson/docker-php-sail-7.0/commit/24d2e7b))

## [1.0.0] - 2025-07-17
### Added
- Initial release of `php-sail-7.0`. ([accf398](https://github.com/theodson/docker-php-sail-7.0/commit/accf398))
- Based on Laravel Sail v1.38.0 (Ubuntu 20.04). ([cc18d00](https://github.com/theodson/docker-php-sail-7.0/commit/cc18d00))
- Support for PHP 7.0 on `amd64`. ([cc18d00](https://github.com/theodson/docker-php-sail-7.0/commit/cc18d00))
- PostgreSQL 9.5 and Node.js support. ([cc18d00](https://github.com/theodson/docker-php-sail-7.0/commit/cc18d00))
### Changed
- Documentation updates to reference Docker Hub images. ([0447f6c](https://github.com/theodson/docker-php-sail-7.0/commit/0447f6c), [5032a72](https://github.com/theodson/docker-php-sail-7.0/commit/5032a72))
