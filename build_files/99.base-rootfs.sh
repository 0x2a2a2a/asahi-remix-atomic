#!/usr/bin/env bash
set -xeuo pipefail

cp -avf "/ctx/base-rootfs"/. /

# sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service

bootupctl backend generate-update-metadata

# Necessary for general behavior expected by image-based systems
sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd"

rm -rf /home /root /usr/local /srv /opt /mnt /usr/local /boot /media
mkdir -p /boot /var /sysroot/ostree
ln -s sysroot/ostree /ostree
ln -sT var/home /home
ln -sT run/media /media
ln -sT var/mnt /mnt
ln -sT var/opt /opt
ln -sT var/roothome /root
ln -sT var/srv /srv
ln -sT ../var/usrlocal /usr/local

# minimal/basic-fixes.yaml

mkdir -p /usr/lib/systemd/system/local-fs.target.wants
if test '!' -f /usr/lib/systemd/system/local-fs.target.wants/tmp.mount; then
  ln -sf ../tmp.mount /usr/lib/systemd/system/local-fs.target.wants
fi

# See https://github.com/containers/bootc/issues/358
# basically systemd-tmpfiles doesn't follow symlinks; ordinarily our
# tmpfiles.d unit for `/var/roothome` is fine, but this actually doesn't
# work if we want to use tmpfiles.d to write to `/root/.ssh` because
# tmpfiles gives up on that before getting to `/var/roothome`.
#
# Redirect stdout to /dev/null because of some weird stdout issue
# with newer rpm-ostree: https://github.com/coreos/rpm-ostree/pull/5388#issuecomment-2971623787
sed -i -e 's, /root, /var/roothome,' /usr/lib/tmpfiles.d/provision.conf > /dev/null
# Because /var/roothome is also defined in rpm-ostree-0-integration.conf
# we need to delete /var/roothome
#
# Redirect stdout to /dev/null because of some weird stdout issue
# with newer rpm-ostree: https://github.com/coreos/rpm-ostree/pull/5388#issuecomment-2971623787
sed -i -e '/^d- \/var\/roothome /d' /usr/lib/tmpfiles.d/provision.conf > /dev/null

# manifests/tmpfiles.yaml

# Workaround for https://issues.redhat.com/browse/RHEL-106203
rm -f /usr/lib/tmpfiles.d/home.conf

# https://gitlab.com/fedora/bootc/base-images/-/issues/28
ln -sT ../run /var/run
test -d /var/tmp || mkdir -m 1777 /var/tmp

RPM_MUT_DB="/usr/lib/sysimage/rpm-ostree-base-db"
RPM_DB="/usr/lib/sysimage/rpm"
RPM_OSTREE_DB="/usr/share/rpm"

mkdir -p "${RPM_MUT_DB}"
mv -T "${RPM_DB}" "${RPM_OSTREE_DB}"
ln -srf "${RPM_OSTREE_DB}" "${RPM_DB}"

# See: https://github.com/coreos/rpm-ostree/issues/4554
# https://forge.fedoraproject.org/atomic/tracker/issues/82
for file in rpmdb.sqlite rpmdb.sqlite-shm rpmdb.sqlite-wal; do
    target="${RPM_DB}/${file}"
    link_path="${RPM_MUT_DB}/${file}"
    # Note, this needs to be a hardlink, not a symbolic link.
    ln -f "${target}" "${link_path}"
done

rm -rf /etc/systemd/system/*
systemctl preset-all
rm -rf /etc/systemd/user/*
systemctl --user --global preset-all

semodule -i /usr/share/selinux/custom/nix.pp

dnf repoquery --installed --qf "%{name} %{installsize}\n" | numfmt --field 2 --to=iec > /usr/share/installed_pkg.txt
