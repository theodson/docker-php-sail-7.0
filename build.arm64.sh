#!/usr/bin/env bash
export IMAGE_VERSION="${IMAGE_VERSION:-1.0.1}"
export DOCKERID=theodson
export PLATFORM="${PLATFORM:-$(uname -m)}" # arm64, amd64 or all
export ACTION="${1:-build_$PLATFORM}" # build_arm64, build_amd64

D=$(date -u +%Y-%m-%dT%H:%M:%SZ)

function build_arm64() {
  # Push a prebuilt arm64 from the arm64-tailored Dockerfile
  local local_tag="theodson/php-sail-7.0:${IMAGE_VERSION}-arm64"
  docker buildx build \
    --platform linux/arm64 \
    --build-arg IMAGE_VERSION="${IMAGE_VERSION}" \
    --build-arg BUILD_DATE="$D" \
    --build-arg WWWGROUP=${WWWGROUP} \
    --build-arg NODE_VERSION=${NODE_VERSION} \
    --build-arg POSTGRES_VERSION=9.5 \
    -t ${local_tag} \
    -f arm64/Dockerfile \
    --load .
}

function push_arm64() {
  # Push a prebuilt arm64 from the arm64-tailored Dockerfile
  local local_tag="theodson/php-sail-7.0:${IMAGE_VERSION}-arm64"
  docker buildx build \
    --platform linux/arm64 \
    --build-arg IMAGE_VERSION="${IMAGE_VERSION}" \
    --build-arg BUILD_DATE="$D" \
    --build-arg WWWGROUP=${WWWGROUP} \
    --build-arg NODE_VERSION=${NODE_VERSION} \
    --build-arg POSTGRES_VERSION=9.5 \
    -t ${local_tag} \
    -f arm64/Dockerfile \
    --push .
}

build_arm64
#push_arm64

#DOCKERFILE=arm64/Dockerfile.arm64 dockerid="theodson/" ./build.sh