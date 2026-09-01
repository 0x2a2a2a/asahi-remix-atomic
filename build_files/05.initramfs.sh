#!/usr/bin/env bash
set -xeuo pipefail

mkdir /var/roothome

install -m 0644 -o root -g root /etc/passwd /usr/lib/passwd
install -m 0644 -o root -g root /etc/group /usr/lib/group

:> /usr/lib/kernel/install.d/15-update-m1n1.install

KERNEL_PACKAGE=kernel-16k
MODULES_DIR=/lib/modules
if [[ ! -d "${MODULES_DIR}" && -d /usr/lib/modules ]]; then
    MODULES_DIR=/usr/lib/modules
fi
mapfile -t kernel_packages < <(
    rpm -qa --qf '%{NAME}\n' \
        | grep -E "^${KERNEL_PACKAGE}(-|$)" | sort -u || true
)
if ((${#kernel_packages[@]} == 0)); then
    printf 'No installed packages match %s\n' "${KERNEL_PACKAGE}" >&2
    exit 1
fi

mapfile -t remove_kernels < <(
    rpm -qa --qf '%{NAME}\n' | grep -E '^kernel(-|$)' \
        | grep -v -E "^${KERNEL_PACKAGE}(-|$)" | sort -u || true
)
if ((${#remove_kernels[@]})); then
    rpm --erase "${remove_kernels[@]}" --nodeps
fi

mapfile -t kernels < <(
    for package in "${kernel_packages[@]}"; do
        rpm -ql "${package}"
    done \
        | sed -n 's#^/\(usr/\)\?lib/modules/\([^/]*\)\(/.*\)\?$#\2#p' \
        | sort -u
)
if ((${#kernels[@]} != 1)); then
    printf 'Expected exactly one %s module directory, found %s\n' \
        "${KERNEL_PACKAGE}" "${#kernels[@]}" >&2
    printf '%s\n' "${kernels[@]}" >&2
    exit 1
fi
KVER=${kernels[0]}

# sed -i '/^    if ((sysloglvl > 0)) || ((kmsgloglvl > 0)); then$/i\    if ((kmsgloglvl > 0)) \&\& ! { [[ -w /dev/kmsg ]] \&\& echo -n "" > /dev/kmsg 2> /dev/null; }; then\n        kmsgloglvl=0\n    fi' /usr/lib/dracut/dracut-logger.sh

dracut --reproducible -v -f "${MODULES_DIR}/${KVER}/initramfs.img" \
    --no-hostonly --kver "${KVER}"
chmod 0600 "${MODULES_DIR}/${KVER}/initramfs.img"

rm -rf /var/roothome
