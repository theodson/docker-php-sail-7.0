# Laravel Sail PHP 7.0 — `php-sail-7.0`

- Based on [Laravel Sail 8.0 image](https://github.com/laravel/sail/blob/v1.38.0/runtimes/8.0/Dockerfile)
- Uses the last Ubuntu 20.04–based Sail release (v1.38.0), adapted to PHP 7.0

This image is not directly compatible with Laravel Sail.

Docker Hub: https://hub.docker.com/r/theodson/php-sail-7.0/tags

Important lifecycle notice

- As of 2025‑07‑01, Ubuntu 20.04 and the `ppa:ondrej/php` hosting for older PHP versions are archived/EOL. Building from scratch can be fragile or fail depending on mirror availability. Prefer pulling the prebuilt images from Docker Hub.

Quick start: pull prebuilt images

```bash
docker pull theodson/php-sail-7.0:1.0        # amd64
docker pull theodson/php-sail-7.0:1.0-arm64  # arm64
```

Repository layout

- `amd64/Dockerfile` — baseline Dockerfile for linux/amd64
- `arm64/Dockerfile` — Apple Silicon/ARM64–tailored Dockerfile
- `build.sh` — multiplatform builder using Docker Buildx; see usage below
- `build.amd64.sh`, `build.arm64.sh` — convenience wrappers that set platform and `DOCKERID`
- Runtime helpers: `functions`, `start-container`, `supervisord.conf`, `php.ini`, `memcached/*`, `postgresql/postgresql-9.5.list`

Build locally (when archives are reachable)

Prerequisites: Docker 24+ with Buildx; logged in to Docker Hub if pushing.

Set your Docker Hub namespace and run a single-arch build:

```bash
export DOCKERID="yourname/"
./build.amd64.sh   # builds and pushes linux/amd64 using amd64/Dockerfile
./build.arm64.sh   # builds and pushes linux/arm64 using arm64/Dockerfile
```

Or build both and create a manifest with `build.sh`:

```bash
export DOCKERID="yourname/"
# Optional: override defaults
# export TAG=1.1
# export NODE_VERSION=20

# Build both architectures (pushes images tagged with :${TAG}-amd64 and :${TAG}-arm64)
PLATFORM=all ./build.sh

# Then create and push a unified manifest tag :${TAG}
docker manifest create ${DOCKERID}php-sail-7.0:${TAG} \
  --amend ${DOCKERID}php-sail-7.0:${TAG}-amd64 \
  --amend ${DOCKERID}php-sail-7.0:${TAG}-arm64
docker manifest annotate ${DOCKERID}php-sail-7.0:${TAG} ${DOCKERID}php-sail-7.0:${TAG}-amd64 --arch amd64
docker manifest annotate ${DOCKERID}php-sail-7.0:${TAG} ${DOCKERID}php-sail-7.0:${TAG}-arm64 --arch arm64
docker manifest push ${DOCKERID}php-sail-7.0:${TAG}
```

Notes

- Composer is pinned to 2.2 for PHP 7.0 compatibility.
- The Dockerfiles use EOL/archived apt sources; builds may fail due to mirror/key rotation.

```bash
# Authenticate for your Docker Hub account
docker login

# Tag and push amd64 image
docker tag theodson/php-sail-7.0 theodson/php-sail-7.0:1.0
docker push theodson/php-sail-7.0:1.0

# Tag and push arm64 image
docker tag theodson/php-sail-7.0-arm64 theodson/php-sail-7.0:1.0-arm64
docker push theodson/php-sail-7.0:1.0-arm64
```
