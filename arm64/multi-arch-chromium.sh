#!/usr/bin/env bash

# Installing Chromium for arm64 running in Docker is suprisingly difficult, options considered are
# 1. use Ubuntu's multi-arch support to run amd64 chromium images OR
# 2. use the pre-built arm64 binary available as part of playwright

# This script investigates Ubuntu's multi-arch support to allow Chromium to run.
# Enable multi-architecture (amd64) to allow running x86_64 binaries on arm64 containers under OrbStack
# See: https://docs.orbstack.dev/machines/#multi-architecture
# Updated: Use canonical mirrors per-architecture to avoid 404s and missing Release file errors.
# - arm64 indexes are served from ports.ubuntu.com
# - amd64 indexes are served from archive.ubuntu.com and security.ubuntu.com

# Alternative approach to investigate if the playwright install does not work.
dpkg --add-architecture amd64 &&
  mv /etc/apt/sources.list /etc/apt/sources.list.orig &&
  printf "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports noble main restricted universe multiverse\n" >/etc/apt/sources.list.d/ubuntu-arm64.list &&
  printf "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports noble-updates main restricted universe multiverse\n" >>/etc/apt/sources.list.d/ubuntu-arm64.list &&
  printf "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports noble-security main restricted universe multiverse\n" >>/etc/apt/sources.list.d/ubuntu-arm64.list

printf "deb [arch=amd64] http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse\n" >/etc/apt/sources.list.d/ubuntu-amd64.list &&
  printf "deb [arch=amd64] http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse\n" >>/etc/apt/sources.list.d/ubuntu-amd64.list &&
  printf "deb [arch=amd64] http://archive.ubuntu.com/ubuntu noble-security main restricted universe multiverse\n" >>/etc/apt/sources.list.d/ubuntu-amd64.list

apt-get update || true

apt-get install -y --no-install-recommends \
  libc6:amd64 \
  libstdc++6:amd64 \
  libgcc-s1:amd64 \
  zlib1g:amd64 \
  libasound2t64:amd64 \
  libatk-bridge2.0-0:amd64 \
  libatk1.0-0:amd64 \
  libatspi2.0-0:amd64 \
  libcairo2:amd64 \
  libcups2:amd64 \
  libdbus-1-3:amd64 \
  libdrm2:amd64 \
  libexpat1:amd64 \
  libgbm1:amd64 \
  libglib2.0-0:amd64 \
  libgtk-3-0:amd64 \
  libnspr4:amd64 \
  libnss3:amd64 \
  libpango-1.0-0:amd64 \
  libx11-6:amd64 \
  libx11-xcb1:amd64 \
  libxcb1:amd64 \
  libxcomposite1:amd64 \
  libxcursor1:amd64 \
  libxdamage1:amd64 \
  libxext6:amd64 \
  libxfixes3:amd64 \
  libxi6:amd64 \
  libxrandr2:amd64 \
  libxrender1:amd64 \
  libxss1:amd64 \
  libxtst6:amd64 \
  ca-certificates:amd64 \
  fonts-liberation:amd64 \
  xdg-utils:amd64 \
  wget:amd64
