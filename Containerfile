ARG REL_VER
FROM quay.io/fedora/fedora-bootc:${REL_VER} AS builder
RUN <<RUN-A
set -xeuo pipefail
dnf -y install dnf5-plugins
dnf -y copr enable @asahi/fedora-remix-branding
dnf -y copr enable lionheartp/Hyprland
dnf -y copr enable avengemedia/dms
dnf -y copr enable alternateved/keyd
# dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release terra-gpg-keys
dnf -y install asahi-repos

/usr/libexec/bootc-base-imagectl build-rootfs \
  --manifest=minimal \
  --exclude kernel \
  --install kernel-16k \
  --install linux-firmware \
  --install asahi-platform-metapackage-core \
  --install binutils \
  --install btrfs-progs \
  --install cryptsetup \
  --install iwd \
  --install bluez \
  --install micro \
  --install openssh-clients \
  --install openssh-server \
  --install plymouth \
  --install plymouth-system-theme \
  --install sudo \
  /target-rootfs

mkdir -p /target-rootfs/etc/yum.repos.d /target-rootfs/etc/pki/rpm-gpg
cp -a /etc/yum.repos.d/. /target-rootfs/etc/yum.repos.d/
cp -a /etc/pki/rpm-gpg/. /target-rootfs/etc/pki/rpm-gpg/
ls -la /target-rootfs
RUN-A

FROM scratch
COPY --from=builder /target-rootfs/ /

RUN <<RUN-B
set -xeuo pipefail

dnf -y --setopt=install_weak_deps=False install \
  7zip attr bash-completion bind-utils bluez-tools bsdtar busybox exfatprogs fuse-overlayfs \
  git-core hfsplus-tools hostname iproute iputils jq keyd less logrotate lsof \
  ncurses nss-altfiles openssl polkit procps-ng psmisc python-unversioned-command \
  rpm-ostree rsync socat squashfs-tools strace sudo time tree tuned tuned-ppd tuned-switcher tzdata \
  udftools unzip upower usbutils vim-minimal which whois xxhash

dnf -y --setopt=install_weak_deps=False install \
  age android-tools bat btop distrobox eza fastfetch fd-find fzf hyperfine \
  just ncdu nix nix-daemon ripgrep slirp4netns wget2-wget zoxide zsh

dnf -y install \
  asahi-platform-metapackage-audio \
  asahi-platform-metapackage-desktop \
  asahi-platform-metapackage-mesa \
  mesa-dri-drivers mesa-libEGL mesa-libGL \
  mesa-vulkan-drivers

dnf -y --setopt=install_weak_deps=False install \
  glibc-langpack-en glibc-langpack-zh \
  default-fonts-cjk-mono default-fonts-cjk-sans default-fonts-cjk-serif \
  default-fonts-core-emoji default-fonts-core-math default-fonts-core-mono default-fonts-core-sans default-fonts-core-serif \
  default-fonts-other-mono default-fonts-other-sans default-fonts-other-serif \
  aajohan-comfortaa-fonts adwaita-sans-fonts adwaita-mono-fonts cascadia-mono-nf-fonts \
  fontawesome-6-free-fonts fontawesome-6-brands-fonts open-sans-fonts terminus-fonts-console

dnf -y --setopt=install_weak_deps=False install \
  ly cage qt6ct qt6-qtwayland qt5-qtwayland dconf nwg-look gtk-murrine-engine \
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland \
  xdg-utils xdg-user-dirs dbus-tools libsecret sassc pavucontrol brightnessctl playerctl

dnf -y --setopt=install_weak_deps=False install \
  hyprland hyprland-uwsm hyprland-guiutils hyprpicker hyprpaper \
  hypridle hyprlock hyprpolkitagent hyprshot hyprcursor \
  fuzzel dms cliphist wl-clipboard alacritty foot keepassxc matugen imv mpv

dnf -y --setopt=install_weak_deps=False install \
  fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-rime luajit

dnf -y --setopt=install_weak_deps=False install \
  thunar thunar-volman thunar-media-tags-plugin thunar-archive-plugin \
  xarchiver 7zip-standalone

dnf -y --setopt=install_weak_deps=False install \
  chromium firefox firefox-langpacks

semanage fcontext -a -t xdm_exec_t "/usr/bin/ly"

printf "NoDisplay=true\n" >> /usr/share/applications/panel-preferences.desktop
mkdir /etc/iwd
printf "[General]\nEnableNetworkConfiguration=true\n\n[Network]\nNameResolvingService=systemd\n" > /etc/iwd/main.conf

printf "FONT=ter-v32n\n" >> /etc/vconsole.conf

printf "pci:v000017A0d00009755*\n ID_AUTOSUSPEND=0\n" > /usr/lib/udev/hwdb.d/65-autosuspend-override-asahi.hwdb

systemctl enable \
  iwd.service \
  keyd.service \
  tuned.service \
  tuned-ppd.service \
  nix-daemon.socket \
  ly@tty7.service

mkdir -p /etc/plymouth
cat << 'EOF' > /etc/plymouth/plymouthd.conf
[Daemon]
DeviceScale=2
EOF

mkdir /var/roothome

KVER=$(ls /usr/lib/modules | tail -n1)
sed -i '/^    if ((sysloglvl > 0)) || ((kmsgloglvl > 0)); then$/i\    if ((kmsgloglvl > 0)) \&\& ! { [[ -w /dev/kmsg ]] \&\& echo -n "" > /dev/kmsg 2> /dev/null; }; then\n        kmsgloglvl=0\n    fi' /usr/lib/dracut/dracut-logger.sh
dracut --reproducible -v --add ostree -f "/usr/lib/modules/${KVER}/initramfs.img" --no-hostonly --kver "${KVER}"
chmod 0600 "/usr/lib/modules/${KVER}/initramfs.img"

dnf repoquery --installed --qf "%{name} %{installsize}\n" | numfmt --field 2 --to=iec > /usr/share/installed_pkg.txt

# Remove leftover build artifacts from installing packages in the final built image.
dnf clean all
#rpm -e dnf5

rm -rf /run/* /tmp/* || true
rm /var/{log,cache,lib}/* -rf
#rm -rf /etc/yum.repos.d/*

# Run the bootc linter to avoid encountering certain bugs and maintain content quality. Place this as the final command in your last run invoaction.
bootc container lint
RUN-B

LABEL containers.bootc 1
LABEL ostree.bootable 1

ENV container=oci
STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
