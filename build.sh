#!/usr/bin/env bash
export WWWGROUP=${WWWGROUP:-$(id -g)}
docker build --build-arg WWWGROUP=${WWWGROUP} -t php-sail-7.0 -f Dockerfile .
