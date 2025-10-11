# Developer Guidelines — theodson/php-sail-7.0

This repository contains Dockerfiles and small helper scripts for building a PHP 7.0 development image derived from Laravel Sail (last Ubuntu 20.04-based release v1.38.0). The image is intended for legacy projects stuck on PHP 7.0 and is published at Docker Hub: `theodson/php-sail-7.0`.

Important lifecycle notice

- As of 2025-07-01, Ubuntu 20.04 and the `ppa:ondrej/php` hosting for older PHP versions are archived/EOL. Fresh builds against upstream archives are fragile or may fail. Prefer pulling the prebuilt images from Docker Hub. Build instructions below are provided primarily for reference and for environments that can access the relevant archives.

Contents

- Build and configuration
- Testing: how to run quick repo checks and add new ones
- Development notes and code style
- Multi-architecture builds and Docker Hub publishing via buildx

Build and configuration

Files and scripts

- `amd64/Dockerfile` — baseline image for linux/amd64. Includes both PHP 8.0 and PHP 7.0 packages, utilities, and Sail-style entrypoint/supervisor. Uses Ubuntu 20.04 and `ppa:ondrej/php` plus Postgres client and Node.js/Yarn.
- `arm64/Dockerfile` — Apple Silicon/arm64 variant. Tailored to ARM and includes additional multi-arch apt sources. Installs PHP 7.0 via an archived/alternate PPA and Composer 2.2.
- `build.sh` — multiplatform builder using Docker Buildx. Uses `PLATFORM`, `DOCKERID`, `TAG`, `WWWGROUP`, `NODE_VERSION`.
- `build.amd64.sh`, `build.arm64.sh` — convenience wrappers; set `PLATFORM=amd64` or `PLATFORM=arm64` and default `DOCKERID="theodson/"` for examples.
- `functions`, `start-container`, `supervisord.conf`, `php.ini`, `memcached/*`, `postgresql/postgresql-9.5.list` — runtime wiring and extra extension bits required by legacy projects.

Environment variables used during build

- `DOCKERID` — repository prefix used by `build.sh` for tagging (e.g., `export DOCKERID="your-dockerhub-username/"`). Required by `build.sh`.
- `PLATFORM` — which architecture(s) to build: `amd64`, `arm64`, or `all`. Defaults to `all`.
- `IMAGE` — image name. Defaults to `${DOCKERID}php-sail-7.0` inside `build.sh`.
- `TAG` — image tag base. Defaults to `1.1` in `build.sh`. Built images are pushed as `${TAG}-amd64` / `${TAG}-arm64` when building per-arch.
- `WWWGROUP` — numeric group id mapped to the `sail` user. Defaults to current host GID via `id -g`. In CI, set explicitly: `WWWGROUP=1000`.
- `NODE_VERSION` — Node.js major version to install. Defaults to `20`.
- Build args supported by Dockerfiles (pass with `--build-arg` when using `docker buildx build`):
  - `WWWGROUP` (no Docker default; scripts default to current host GID)
  - `NODE_VERSION` (defaults to `20`)
  - `POSTGRES_VERSION` (defaults to `9.5`)

Examples (arm64):

```bash
export IMAGE=theodson/php-sail-7.0
export TAG=dev-arm64

# Override WWWGROUP, NODE_VERSION, POSTGRES_VERSION at build time
docker buildx build \
  --platform linux/arm64 \
  --build-arg WWWGROUP=1000 \
  --build-arg NODE_VERSION=20 \
  --build-arg POSTGRES_VERSION=9.5 \
  -t ${IMAGE}:${TAG} \
  -f arm64/Dockerfile \
  --push .
```

Minimum supported tools

- Docker 24+ with `buildx` plugin (for multi-arch) and logged-in Docker Hub client when pushing.
- On macOS Apple Silicon, ensure Docker Desktop has `Use Rosetta for x86/amd64 emulation on Apple Silicon` enabled if you plan to run amd64 binaries inside containers, but prefer true multi-arch images when possible.

Example builds

- Local single-arch build (amd64 host):
  1. `export DOCKERID="yourname/"`
  2. `./build.amd64.sh`
  3. Result: pushes `${DOCKERID}php-sail-7.0:${TAG}-amd64` via Buildx.

- Local single-arch build (arm64/Apple Silicon):
  1. `export DOCKERID="yourname/"`
  2. `./build.arm64.sh`
  3. Result: pushes `${DOCKERID}php-sail-7.0:${TAG}-arm64` via Buildx.

Notes and caveats

- EOL archives: The Dockerfiles reference sources that may become unavailable or rate-limited. Builds can fail even if apt keys are present. If you only need the image, pull from Docker Hub: `docker pull theodson/php-sail-7.0:1.0` or `:1.0-arm64`.
- Composer pin: Composer is pinned to 2.2 to maintain compatibility with PHP 7.0.
- Node/Yarn: `NODE_VERSION` arg defaults to 20; modify as needed.

Testing

Purpose

- This repository doesn’t contain runtime unit tests; instead, keep quick “repo health” checks to validate that scripts are syntactically correct and key Dockerfile markers remain present.

Run quick checks

- Validate shell scripts parse and key files exist:

  ```bash
  bash -n build.sh build.amd64.sh build.arm64.sh && \
  test -f amd64/Dockerfile && test -f arm64/Dockerfile && \
  grep -q "ubuntu:20.04" amd64/Dockerfile && grep -q "ubuntu:20.04" arm64/Dockerfile && \
  echo "Repo checks passed"
  ```

- Optional: dry-evaluate Dockerfiles with Docker’s frontend without pulling layers (syntax check) using BuildKit’s `--load`/`--pull=false` can still hit network during `RUN`. Because the Dockerfiles include `RUN apt-get ...`, a true syntax-only check isn’t reliable via `docker build`. Prefer static checks above.

Adding new tests

- Add small POSIX shell scripts under a `tests/` directory that:
  - Use `bash -n` to check script syntax.
  - Grep for required markers/labels/args in Dockerfiles.
  - Avoid performing networked operations in CI unless strictly controlled.
- Keep tests idempotent and fast. If you add such files, remember to integrate them into CI and remove temporary local-only helpers from commits.

Demonstration test that was validated locally for this guide

- During authoring of this guide, a temporary script executed these checks:

  ```bash
  bash -n build.sh build.amd64.sh build.arm64.sh 
  test -f amd64/Dockerfile && test -f arm64/Dockerfile
  grep -q "ubuntu:20.04" amd64/Dockerfile
  grep -q "ubuntu:20.04" arm64/Dockerfile
  grep -q "PLATFORM=arm64" build.arm64.sh
  grep -q "DOCKERID=\"theodson/\"" build.arm64.sh
  ```

Development notes and code style

- Shell style: scripts are POSIX/Bash hybrids. Keep them `bash -n` clean. Prefer:
  - `set -euo pipefail` for new scripts.
  - Quoting variable expansions and using `$(...)` subshells.
  - Minimal external dependencies for portability.
- Dockerfile style:
  - Group related apt operations and clean `apt` lists to reduce layers (already present in `Dockerfile`).
  - Keep ARGs at top, prefer `--no-install-recommends` where feasible.
  - Be explicit with pinned versions when working with archived repositories.
- Entrypoint/runtime:
  - `start-container` integrates supervisor and sets capabilities to bind to privileged ports for PHP CLI server. Changes here affect both Dockerfiles.
  - `functions` is sourced in `sail` user profile for helper commands; maintain backwards compatibility.

Multi-architecture builds with Docker buildx

Recommended approach: build per-architecture images and then create a manifest that unifies them under one tag. Because `Dockerfile.arm64` contains arm64-specific apt sources, it should be used only for `linux/arm64`, and the baseline `Dockerfile` should be used for `linux/amd64`.

Prerequisites

- Docker 24+ with buildx. Log in to Docker Hub: `docker login`.

Setup buildx builder (one-time)

```bash
docker buildx create --name multi --use
docker buildx inspect --bootstrap
```

Build per-arch images then create a manifest (recommended)

```bash
export IMAGE=theodson/php-sail-7.0
export TAG=1.0

# Build amd64 from baseline Dockerfile
docker buildx build \
  --platform linux/amd64 \
  --build-arg WWWGROUP=1000 \
  -t ${IMAGE}:${TAG}-amd64 \
  -f Dockerfile \
  --push .

# Build arm64 from the arm64-tailored Dockerfile
docker buildx build \
  --platform linux/arm64 \
  --build-arg WWWGROUP=1000 \
  # Optionally override additional args also supported by Dockerfile.arm64:
  # --build-arg NODE_VERSION=18 \
  # --build-arg POSTGRES_VERSION=9.6 \
  -t ${IMAGE}:${TAG}-arm64 \
  -f Dockerfile.arm64 \
  --push .

# Create and push a unified manifest tag
docker manifest create ${IMAGE}:${TAG} \
  --amend ${IMAGE}:${TAG}-amd64 \
  --amend ${IMAGE}:${TAG}-arm64

docker manifest annotate ${IMAGE}:${TAG} ${IMAGE}:${TAG}-amd64 --arch amd64
docker manifest annotate ${IMAGE}:${TAG} ${IMAGE}:${TAG}-arm64 --arch arm64

docker manifest push ${IMAGE}:${TAG}
```

Recommendations

- Because `Dockerfile.arm64` includes multi-arch apt sources and other arm64 specifics, use it exclusively for `linux/arm64` builds, and the baseline `Dockerfile` for `linux/amd64`. Publish a single tag using the manifest approach above.
- Consider locking base image digests to avoid surprise changes in archived repos.
- Include SBOM/provenance if your environment supports it: add `--provenance=true --sbom=true` flags to `docker buildx build`.

Publishing single-arch images (legacy)

Examples are in `README.md`. Quick reference:

```bash
docker tag theodson/php-sail-7.0 theodson/php-sail-7.0:1.0
docker push theodson/php-sail-7.0:1.0
```

Troubleshooting

- apt 404/Release errors: when mixing `ports.ubuntu.com` (arm64) and `archive.ubuntu.com` (amd64), ensure the correct `arch=` qualifiers per source list. The `Dockerfile.arm64` demonstrates a working split configuration and cleans lists at the end of the multi-arch install step.
- GPG key issues: both Dockerfiles import keys using `gpg --dearmor`. Keys can rotate or expire; you may need to refresh from the official mirrors or archives. Avoid `apt-key adv` and keyservers (timeouts are common/EOL). Prefer fetching the ASCII armored key via HTTPS and using `signed-by=` with a dearmored keyring.
  - PostgreSQL archive example (used in `Dockerfile.arm64`):
    ```bash
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      | gpg --dearmor -o /usr/share/keyrings/pgdg-archive.gpg
    echo "deb [signed-by=/usr/share/keyrings/pgdg-archive.gpg] https://apt-archive.postgresql.org/pub/repos/apt focal-pgdg main" \
      > /etc/apt/sources.list.d/pgdg-archive.list
    apt-get update
    ```
- Composer/Node network failures: use retry logic in CI or maintain a local cache proxy for reproducibility.
