<p align="center"><img width="294" height="69" src="/art/logo.svg" alt="Logo Laravel Sail"></p>

# Laravel Sail PHP 7.0 — `php-sail-7.0`

`php-sail-7.0` provides a Docker-powered local development experience for legacy Laravel projects stuck on PHP 7.0. It is partially compatible with [Laravel Sail](https://github.com/laravel/sail) and is designed to run on macOS, Windows (WSL2), and Linux.

## Overview

This repository contains Dockerfiles and helper scripts for building a PHP 7.0 development image derived from Laravel Sail. It addresses the challenges of running older PHP versions on modern operating systems (like Ubuntu 24.04) and architectures (Apple Silicon/ARM64).

### Stack
- **PHP**: 7.0 (compiled from source for Ubuntu 24.04 compatibility in v2.0)
- **Base OS**: Ubuntu 24.04 (v2.0+) or Ubuntu 20.04 (v1.0)
- **Node.js**: v20 (default, configurable)
- **Composer**: 2.2 (pinned for PHP 7.0 compatibility)
- **Postgres**: 9.5 (default)
- **Chromium/Playwright**: Included for PDF generation (compatible with `spatie/browsershot` / puppeteer)
- **ImageMagick**: Supported with HTTPS delegates
- **Supervisor**: Manages PHP and other services via `supervisord.conf`

## Requirements
- **Docker**: 24.0+ with [Buildx](https://docs.docker.com/build/buildx/)
- **OrbStack**: (Highly recommended for Apple Silicon/macOS) for better performance and emulation support.
- **Docker Hub Account**: Required for pushing/publishing images.

## Project Structure
- `amd64/Dockerfile`: Baseline image for linux/amd64.
- `arm64/Dockerfile`: Tailored image for Apple Silicon/arm64.
- `build.sh`: Multi-platform builder script.
- `build.amd64.sh` / `build.arm64.sh`: Convenience wrappers for single-arch builds.
- `publish.sh`: Legacy script for single-arch tagging and pushing.
- `functions`: Helper functions sourced in the container.
- `start-container`: Entrypoint script for the Docker container.
- `supervisord.conf`: Configuration for process management.
- `php.ini`: Default PHP configuration.
- `art/`: Repository assets (logos).

## Environment Variables

### Build-time Variables
| Variable | Description | Default       |
| --- | --- |---------------|
| `DOCKERID` | Docker Hub namespace (required for build scripts) | -             |
| `PLATFORM` | Target architecture (`amd64`, `arm64`, or `all`) | `$(uname -m)` |
| `TAG` | Image tag version | `2.1`         |
| `WWWGROUP` | Host user group ID for file permissions | `$(id -g)`    |
| `NODE_VERSION` | Node.js major version | `20`          |
| `POSTGRES_VERSION`| PostgreSQL client version | `9.5`         |

### Runtime Variables
| Variable | Description | Default |
| --- | --- | --- |
| `WWWUSER` | Runtime user ID mapping | - |
| `SUPERVISOR_PHP_USER`| User to run PHP processes (`sail` or `root`) | `sail` |

## Usage

### Quick Start: Pull Prebuilt Images
Docker Hub: [theodson/php-sail-7.0](https://hub.docker.com/r/theodson/php-sail-7.0/tags)

```bash
# v2+ (Multi-arch)
docker pull theodson/php-sail-7.0:2.1

# v1 (Single-arch)
docker pull theodson/php-sail-7.0:1.0        # amd64
docker pull theodson/php-sail-7.0:1.0-arm64  # arm64
```

### Running Locally
Typically integrated via `docker-compose.yml`. For a quick test:

```bash
docker run -it --rm \
  -v $(pwd):/var/www/html \
  -e WWWUSER=$(id -u) \
  -p :80 \
  theodson/php-sail-7.0:2.1 \
  bash
```
Or when building a specific architecture 
```bash
docker run -it --rm \
  -v $(pwd):/var/www/html \
  -e WWWUSER=$(id -u) \
  -p :80 \
  theodson/php-sail-7.0:2.1-arm64 \
  bash
```

## Scripts & Development

- `build.sh`: The primary script for building images. Supports `build`, `push`, and `publish` (manifest) actions.
- `build.amd64.sh` / `build.arm64.sh`: Shortcuts to build and push for a specific architecture.
- `publish.sh`: Simple script to tag and push `php-sail-7.0` to a custom version on Docker Hub.

### Multi-Architecture Build
Build both architectures, create a manifest, and publish to Docker Hub:

```bash
export DOCKERID="your-namespace"
export TAG=2.1

./build.sh build    # Builds both amd64 and arm64
./build.sh push     # Pushes individual images
./build.sh publish  # Creates and pushes the multi-arch manifest
```

## Testing
- **TODO**: Add automated runtime tests (e.g., verifying PHP version and extensions inside the container).
- **Static Checks**: Validate script syntax:
  ```bash
  bash -n build.sh build.amd64.sh build.arm64.sh
  ```

## Releases

### v2.0 (Ubuntu 24.04 Noble)
- Supports both **amd64** and **arm64**.
- PHP 7.0 and extensions are compiled from source as Noble lacks native PHP 7.0 repositories.
- Based on [Laravel Sail 8.0 image (v1.48)](https://github.com/laravel/sail/blob/v1.48.0/runtimes/8.0/Dockerfile).

### v1.0 (Ubuntu 20.04 Focal)
- Based on [Laravel Sail 8.0 image (v1.38)](https://github.com/laravel/sail/blob/v1.38.0/runtimes/8.0/Dockerfile).
- **Notice**: As of 2025-07-01, Ubuntu 20.04 and `ppa:ondrej/php` are EOL. Builds may be unstable; prefer prebuilt images.

## Technical Notes

### PDF Generation (Chromium & Playwright)
Finding a native ARM64 Chromium for puppeteer on legacy PHP is challenging. This image uses **Playwright** to install a native binary. Ensure these variables are set in your `.env`:

```bash
PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/playwright-browsers
PLAYWRIGHT_CHROMIUM_REVISION="1106"
PLAYWRIGHT_REVISION="1.43.0"
PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

### Multi-Architecture Emulation
OrbStack supports emulating other architectures (e.g., running amd64 programs on Apple Silicon). If the Playwright approach fails, you might explore adding foreign architectures via `dpkg --add-architecture amd64`.


## Buildx Cache FAQ
Docker buildx uses a separate build cache from the regular Docker image store. This is why you're seeing this behavior.
Where Images Are Stored
1. **Regular Docker images** (docker images): Stored in Docker's local image store
2. **Buildx cache**: Stored in the buildx builder instance (often a separate container or driver)

### Why Your Images Appear After "Deletion"
When you use docker `buildx build --load`, the image is:
- Built inside the buildx builder
- Then loaded into the local Docker image store

When you use docker `buildx build --push`, the image is:
- Built inside the buildx builder
- Pushed directly to the registry
- **NOT automatically loaded into local Docker images**

However, the **buildx build cache persists** in the builder. So when you run a command that needs the image, buildx can quickly reconstruct it from cache without downloading.
### To Fully Clear Buildx Cache

```
# List buildx builders
docker buildx ls
```

```
# Remove buildx cache for the current builder
docker buildx prune
```

```
# Or remove ALL buildx cache (more aggressive)
docker buildx prune -a
```

```
docker builder prune -a
# To also clear regular Docker build cache
```

### To See What's in Buildx Cache
```
docker buildx du
```

### Summary
Your `docker images | grep sail` shows the local image store, but buildx maintains its own cache. 
That's why images rebuild instantly—they're cached in the buildx builder, not downloaded from Docker Hub.

## License
This project is open-sourced software licensed under the [MIT license](LICENSE).
