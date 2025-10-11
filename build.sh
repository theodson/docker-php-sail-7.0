#!/usr/bin/env bash
# you may want to set the env DOCKERID="yourGitHubOrDockerHubId/"
test -z "${DOCKERID}" && {
  echo "set DOCKERID ENV"
  exit 1
}
export PLATFORM="${PLATFORM:-$(uname -m)}" # arm64, amd64 or all
export ACTION="${1:-build_$PLATFORM}" # build_arm64, build_amd64
export IMAGE=${DOCKERID}php-sail-7.0
export TAG="${TAG:-2.0}"
export IMAGE_TAG="${IMAGE}:${TAG}-${PLATFORM}"

export WWWGROUP=${WWWGROUP:-$(id -g)}
export NODE_VERSION=${NODE_VERSION:-20}

test -z "${WWWGROUP}" && {
  echo "set WWWGROUP ENV"
  exit 1
}

function build_arm64() {
  # Build arm64 from the arm64-tailored Dockerfile
  info
  local local_tag="${IMAGE}:${TAG}-arm64"
  docker buildx build \
    --platform linux/arm64 \
    --build-arg WWWGROUP=${WWWGROUP} \
    --build-arg NODE_VERSION=${NODE_VERSION} \
    --build-arg POSTGRES_VERSION=9.5 \
    -t ${local_tag} \
    -f arm64/Dockerfile \
    --load .
}

function build_arm64_debug() {
  # Build arm64 from the arm64-tailored Dockerfile
  # PHP_DEBUG='--enable-debug' to build php debug symbols use gdb for tracing SegFault, etc
  export TAG="${TAG}_DBG"
  export IMAGE_TAG="${IMAGE}:${TAG}-${PLATFORM}"
  info
  docker buildx build \
    --platform linux/arm64 \
    --build-arg PHP_DEBUG='--enable-debug' \
    --build-arg WWWGROUP=${WWWGROUP} \
    --build-arg NODE_VERSION=${NODE_VERSION} \
    --build-arg POSTGRES_VERSION=9.5 \
    -t ${IMAGE_TAG} \
    -f arm64/Dockerfile \
    --load .
}

function build_amd64() {
  # Build amd64 from baseline Dockerfile
  info
  local local_tag="${IMAGE}:${TAG}-amd64"
  docker buildx build \
    --platform linux/amd64 \
    --build-arg WWWGROUP=${WWWGROUP} \
    --build-arg NODE_VERSION=${NODE_VERSION} \
    --build-arg POSTGRES_VERSION=9.5 \
    -t ${local_tag} \
    -f amd64/Dockerfile \
    --load .
}

function push_arm64() {
  # Push a prebuilt arm64 from the arm64-tailored Dockerfile
  info
  local local_tag="${IMAGE}:${TAG}-arm64"
  docker buildx build \
    --platform linux/arm64 \
    --build-arg WWWGROUP=${WWWGROUP} \
    --build-arg NODE_VERSION=${NODE_VERSION} \
    --build-arg POSTGRES_VERSION=9.5 \
    -t ${local_tag} \
    -f arm64/Dockerfile \
    --push \
    .
}

function push_amd64() {
  # Push a prebuilt amd64 from the amd64 Dockerfile
  info
  local local_tag="${IMAGE}:${TAG}-amd64"
  docker buildx build \
    --platform linux/amd64 \
    --build-arg WWWGROUP=${WWWGROUP} \
    --build-arg NODE_VERSION=${NODE_VERSION} \
    --build-arg POSTGRES_VERSION=9.5 \
    -t ${local_tag} \
    -f amd64/Dockerfile \
    --push \
    .
}

function publish() {
  # Create and push a unified manifest tag
  docker manifest create ${IMAGE}:${TAG} \
    --amend ${IMAGE}:${TAG}-amd64 \
    --amend ${IMAGE}:${TAG}-arm64

  docker manifest annotate ${IMAGE}:${TAG} ${IMAGE}:${TAG}-amd64 --arch amd64
  docker manifest annotate ${IMAGE}:${TAG} ${IMAGE}:${TAG}-arm64 --arch arm64

  docker manifest push ${IMAGE}:${TAG}
}

function info() {
  cat <<CONF
ACTION=$ACTION
PLATFORM=$PLATFORM
IMAGE=$IMAGE
TAG=$TAG
IMAGE_TAG=$IMAGE_TAG
WWWGROUP=$WWWGROUP
NODE_VERSION=$NODE_VERSION
CONF
}

# Note: look at docker manifest or buildx for better multi architecture single image setup rather than tagging to distinguish platform.
case "${ACTION}" in
'build')
  build_arm64
  build_amd64
  ;;
'build_arm64_debug')
  build_arm64_debug
  ;;
'build_arm64')
  build_arm64
  ;;
'build_amd64')
  build_amd64
  ;;
'push')
  push_arm64
  push_amd64
  ;;
'push_arm64')
  push_arm64
  ;;
'push_amd64')
  push_amd64
  ;;
'publish')
  publish
  ;;
esac
echo Finished Docker build using buildx, tagged with

exit

DOCKERTAG=${DOCKERID}php-sail-7.0-$(uname -m)
if test $(uname -m) = 'arm64'; then
  # build in Apple Silicon environment
  docker build --build-arg WWWGROUP=${WWWGROUP} -t "$dockertag" -f $dockerfile .
  # docker build --build-arg WWWGROUP=${WWWGROUP} -t "$dockertag" --no-cache -f $dockerfile .
else
  # build in Intel environment
  DOCKERTAG="${DOCKERID}php-sail-7.0"
  docker build --build-arg WWWGROUP=${WWWGROUP} -t "$dockertag" -f $dockerfile .
  # docker build --build-arg WWWGROUP=${WWWGROUP} -t "$dockertag" --no-cache -f $dockerfile .
fi

echo Finished Docker build, tagged with $dockertag
