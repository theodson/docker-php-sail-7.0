#!/usr/bin/env bash
# you may want to set the env dockerid="yourid/"
test -z "${dockerid}" && {
  echo "set dockerid ENV"
  exit 1
}

dockerfile="${DOCKERFILE:-Dockerfile}"
dockertag=${dockerid}php-sail-7.0-$(uname -m)

export WWWGROUP=${WWWGROUP:-$(id -g)}

# Note: look at docker manifest or buildx for better multi architecture single image setup rather than tagging to distinguish platform.

if test $(uname -m) = 'arm64'; then
  # build in Apple Silicon environment
  docker build --build-arg WWWGROUP=${WWWGROUP} -t "$dockertag" -f $dockerfile .
  # docker build --build-arg WWWGROUP=${WWWGROUP} -t "$dockertag" --no-cache -f $dockerfile .
else
  # build in Intel environment
  dockertag="${dockerid}php-sail-7.0"
  docker build --build-arg WWWGROUP=${WWWGROUP} -t "$dockertag" -f $dockerfile .
  # docker build --build-arg WWWGROUP=${WWWGROUP} -t "$dockertag" --no-cache -f $dockerfile .
fi

echo Finished Docker build, tagged with $dockertag