ARG THEMES_IMAGE=ghcr.io/0x2a2a2a/asahi-remix-atomic:themes
FROM ${THEMES_IMAGE} AS themes

ARG RELEASE_VER
FROM quay.io/fedora/fedora-bootc:${RELEASE_VER} AS builder
RUN dnf -y install dnf5-plugins && \
    dnf -y copr enable @asahi/fedora-remix-branding && \
    dnf -y install asahi-repos

RUN /usr/libexec/bootc-base-imagectl build-rootfs \
  --manifest=minimal \
  --exclude kernel \
  --install kernel-16k \
  --install linux-firmware \
  --install asahi-repos \
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
  /target-rootfs

FROM scratch
COPY --from=builder /target-rootfs/ /

# Qogir GTK/icon themes, Bibata cursors and qogir-adwaita-qt style plugins
# (provided by the independent themes image built from themes.Containerfile, tag :themes)
COPY --from=themes /usr/share/themes /usr/share/themes
COPY --from=themes /usr/share/icons /usr/share/icons
COPY --from=themes /usr/lib64/qt5/plugins /usr/lib64/qt5/plugins
COPY --from=themes /usr/lib64/qt6/plugins /usr/lib64/qt6/plugins
COPY --from=themes /usr/lib64/libadwaitaqt* /usr/lib64/

RUN <<EORUN
# Set pipefail to display failures within the heredoc and avoid false-positive successful builds.
set -xeuo pipefail

dnf -y install dnf5-plugins
dnf copr enable -y @asahi/fedora-remix-branding
dnf copr enable -y lionheartp/Hyprland
dnf copr enable -y alternateved/keyd

dnf -y --setopt=install_weak_deps=False install \
  7zip attr bash-completion bsdtar busybox exfatprogs fuse-overlayfs \
  git-core gtk2-engines gtk-murrine-engine hfsplus-tools hostname iproute iputils jq keyd less logrotate lsof \
  ncurses nss-altfiles openssl polkit procps-ng psmisc python-unversioned-command \
  rpm-ostree rsync socat squashfs-tools strace sudo time tree tuned tuned-ppd tuned-switcher tzdata \
  udftools unzip upower usbutils vim-minimal which whois xxhash

dnf -y --setopt=install_weak_deps=False install \
  age bat btop distrobox eza fastfetch fd-find fzf hyperfine \
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
  ly cage qt6ct qt6-qtwayland qt5-qtwayland nwg-look dconf \
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  xdg-utils xdg-user-dirs dbus-tools libadwaita libsecret sassc pavucontrol brightnessctl playerctl

dnf -y --setopt=install_weak_deps=False install \
  hyprland hyprland-uwsm hyprland-guiutils hyprpicker hyprpaper \
  hypridle hyprlock hyprpolkitagent hyprshot hyprcursor \
  waybar fuzzel mako cliphist wl-clipboard alacritty foot keepassxc

dnf -y --setopt=install_weak_deps=False install \
  fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-rime luajit

dnf -y --setopt=install_weak_deps=False install \
  thunar thunar-volman thunar-media-tags-plugin thunar-archive-plugin \
  xarchiver 7zip 7zip-standalone unzip

dnf -y --setopt=install_weak_deps=False install \
  chromium firefox firefox-langpacks

semanage fcontext -a -t xdm_exec_t "/usr/bin/ly"

printf "NoDisplay=true\n" >> /usr/share/applications/panel-preferences.desktop
mkdir /etc/iwd
printf "[General]\nEnableNetworkConfiguration=true\n\n[Network]\nNameResolvingService=systemd\n" > /etc/iwd/main.conf

printf "FONT=ter-v32n\n" > /etc/vconsole.conf

printf "pci:v000017A0d00009755*\n ID_AUTOSUSPEND=0\n" > /usr/lib/udev/hwdb.d/65-autosuspend-override-asahi.hwdb

systemctl enable \
  iwd.service \
  keyd.service \
  tuned.service \
  tuned-ppd.service \
  nix-daemon.socket \
  ly@tty7.service

# Remove leftover build artifacts from installing packages in the final built image.
dnf clean all

rm -rf /run/* /run/.* /tmp/* /tmp/.* 2>/dev/null || true
rm -rf /var/cache/* /var/log/* /var/lib/dnf/* /var/db/sudo /var/spool/plymouth

# Run the bootc linter to avoid encountering certain bugs and maintain content quality. Place this as the final command in your last run invoaction.
bootc container lint
EORUN

LABEL containers.bootc 1
LABEL ostree.bootable 1

ENV container=oci
STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
