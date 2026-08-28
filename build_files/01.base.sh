#!/usr/bin/env bash
set -xeuo pipefail

sed -i "s|enabled=1|enabled=0|" /etc/yum.repos.d/fedora-cisco-openh264.repo

dnf -y install dnf5-plugins

dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release terra-gpg-keys

. /ctx/selinux-copyup.sh

# @core @standard
dnf -y --setopt=install_weak_deps=False --nodocs install \
  NetworkManager NetworkManager-wifi acl attr audit bash-color-prompt bash-completion bc bind-utils bzip2 \
  compsize crontabs dos2unix exfatprogs hostname iproute iputils less lsof ncurses nmap-ncat opensc \
  parted rsync smartmontools symlinks time tree unzip usbutils wget which whois zip zram-generator-defaults

# 
dnf -y --setopt=install_weak_deps=False --nodocs install \
  android-tools bluez-tools bsdtar busybox fastfetch git-core htop jq keyd openssl \
  psmisc python-unversioned-command socat tuned tuned-ppd tuned-switcher tzdata upower xxhash

# ctr & pm
dnf -y --setopt=install_weak_deps=False install \
  distrobox fuse-overlayfs nix nix-daemon slirp4netns
