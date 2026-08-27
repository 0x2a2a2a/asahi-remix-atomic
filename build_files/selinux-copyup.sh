#!/usr/bin/env bash
set -xeuo pipefail

if [ -d /etc/selinux/targeted ]; then
    cp -a /etc/selinux/targeted /etc/selinux/targeted.copyup
    rm -rf /etc/selinux/targeted
    mv /etc/selinux/targeted.copyup /etc/selinux/targeted
fi
