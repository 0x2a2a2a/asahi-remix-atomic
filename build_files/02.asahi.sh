#!/usr/bin/env bash
set -xeuo pipefail

dnf -y install \
  asahi-platform-metapackage-audio \
  asahi-platform-metapackage-desktop
