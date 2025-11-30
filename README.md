<p align="center"><img width="294" height="69" src="/art/logo.svg" alt="Logo Laravel Sail"></p>

# Laravel Sail PHP 7.0 — `php-sail-7.0`

Sail provides a Docker powered local development experience for Laravel that is compatible with macOS, Windows (WSL2), and Linux. Other than Docker, no software or libraries are required to be installed on your local computer before using Sail.

This image is only partially compatible with Laravel Sail and serves only to provide PHP 7.0 support for those who need it for their older projects.

Docker Hub: https://hub.docker.com/r/theodson/php-sail-7.0/tags


## Releases

### v2.0 Ubuntu 24.04
Uses **Ubuntu 24.04** based, support both amd64 and arm64 (Apple Silicon).
- No repositories exist for older PHP versions.
- Php 7.0, some extensions and OS libraries are compiled from source to be able to run on Ubuntu 24.04.


### v1.0 Ubuntu 20.04
Uses the last **Ubuntu 20.04**–based Sail release (v1.38.0), adapted to PHP 7.0, only amd64.

- Based on [Laravel Sail 8.0 image](https://github.com/laravel/sail/blob/v1.38.0/runtimes/8.0/Dockerfile)

Important lifecycle notice

- As of 2025‑07‑01, Ubuntu 20.04 and the `ppa:ondrej/php` hosting for older PHP versions are archived/EOL. Building from scratch can be fragile or fail depending on mirror availability. Prefer pulling the prebuilt images from Docker Hub.

## Usage

**Quick start**: pull prebuilt images

```bash
#
# v2+ - supports multi-architecture builds 
#       it automatically pulls to correct architecture for your platform

docker pull theodson/php-sail-7.0:2.0
```

```bash
#
# v1
#
docker pull theodson/php-sail-7.0:1.0        # amd64
docker pull theodson/php-sail-7.0:1.0-arm64  # arm64
```

## Build

**Repository layout**

- `amd64/Dockerfile` — baseline Dockerfile for linux/amd64
- `arm64/Dockerfile` — Apple Silicon/ARM64–tailored Dockerfile
- `build.sh` — multiplatform builder using Docker Buildx; see usage below
- `build.amd64.sh`, `build.arm64.sh` — convenience wrappers that set platform and `DOCKERID`
- Runtime helpers: `functions`, `start-container`, `supervisord.conf`, `php.ini`, `postgresql/postgresql-9.5.list`

**Notes**

- Composer is pinned to 2.2 for PHP 7.0 compatibility.
- The Dockerfiles use EOL/archived apt sources and ppa; builds may fail due to mirror/key rotation and availability.

**Prerequisites** 
 
- Docker 24+ with Buildx 
- logged in to Docker Hub if pushing.

**Build locally** (when archives are reachable)

Build both architectures, create a manifest and publish to Docker Hub with `build.sh`:

>  Note: building for a different architecture is supported regardless of the host/build machines architevture/platform.

```bash
# Optional: override defaults
export DOCKERID="theodson" # your Docker Hub namespace
export TAG=2.1
export NODE_VERSION=20

# Authenticate for your Docker Hub account
docker login

# Build both architectures (pushes images tagged with :${TAG}-amd64 and :${TAG}-arm64)
./build.sh build
./build.sh push
./build.sh publish
```


Set your Docker Hub namespace and run a single-arch build:

```bash
export DOCKERID="yourname/"
# explicitly set the platform to linux/amd64
./build.amd64.sh   # builds and pushes linux/amd64 using amd64/Dockerfile

# explicitly set the platform to linux/amd64
./build.arm64.sh   # builds and pushes linux/arm64 using arm64/Dockerfile

# automatically set the platform to the host architecture
./build.sh   # builds and pushes linux/arm64 using arm64/Dockerfile
```


## Publish
Publishing the built images to Docker Hub

```bash
# Optional: override defaults

# Authenticate for your Docker Hub account
docker login

# Assuming images are built and pushed (see previous examples)
./build.sh publish
```


```bash
#
# the publish argument generates these commands (based on ENV) 
# publishing look like this
#
docker manifest create theodson/php-sail-7.0:2.0 \
  --amend theodson/php-sail-7.0:2.0-amd64 \
  --amend theodson/php-sail-7.0:2.0-arm64

docker manifest annotate theodson/php-sail-7.0:2.0 \
  theodson/php-sail-7.0:2.0-amd64 --arch amd64

docker manifest annotate theodson/php-sail-7.0:2.0 \
  theodson/php-sail-7.0:2.0-arm64 --arch arm64

docker manifest push theodson/php-sail-7.0:2.0
```
