#!/usr/bin/env bash
PLATFORM=arm64 DOCKERID="theodson/" ./build.sh "$@"
# To debug the php build
# PLATFORM=arm64 DOCKERID="theodson/" ./build.sh build_arm64_debug
