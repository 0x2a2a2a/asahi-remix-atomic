#!/usr/bin/env bash
set -xeuo pipefail

mkdir /var/roothome

KVER=$(ls /usr/lib/modules | tail -n1)
# sed -i '/^    if ((sysloglvl > 0)) || ((kmsgloglvl > 0)); then$/i\    if ((kmsgloglvl > 0)) \&\& ! { [[ -w /dev/kmsg ]] \&\& echo -n "" > /dev/kmsg 2> /dev/null; }; then\n        kmsgloglvl=0\n    fi' /usr/lib/dracut/dracut-logger.sh
dracut --reproducible -v --add ostree -f "/usr/lib/modules/${KVER}/initramfs.img" --no-hostonly --kver "${KVER}"
chmod 0600 "/usr/lib/modules/${KVER}/initramfs.img"
