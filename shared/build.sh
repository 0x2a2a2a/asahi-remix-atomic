#!/usr/bin/env bash

set -xeuo pipefail

git clone "https://github.com/bootc-dev/bootc.git" . -b v1.16.10
 
make bin install-all DESTDIR=/output

