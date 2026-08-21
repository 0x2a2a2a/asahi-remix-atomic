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
  /target-rootfs

FROM scratch
COPY --from=builder /target-rootfs/ /

RUN <<EORUN
# Set pipefail to display failures within the heredoc and avoid false-positive successful builds.
set -xeuo pipefail

dnf -y install dnf5-plugins
dnf copr enable -y @asahi/fedora-remix-branding
dnf copr enable -y lionheartp/Hyprland
dnf copr enable -y lihaohong/yazi
dnf copr enable -y alternateved/keyd

# base tool & sys mgr
dnf -y install --setopt=install_weak_deps=False \
  attr \
  bash-completion \
  busybox \
  hostname \
  iproute \
  jq \
  less \
  vim-minimal \
  tar \
  time \
  tree \
  which \
  whois \
  psmisc \
  procps-ng \
  lsof \
  ncurses \
  openssl \
  rsync \
  sudo \
  polkit \
  logrotate \
  rpm-ostree \
  nss-altfiles \
  iputils \
  socat \
  exfatprogs \
  hfsplus-tools \
  fuse-overlayfs \
  udftools \
  squashfs-tools \
  usbutils \
  ly

# virt & pm
dnf -y install --setopt=install_weak_deps=False \
  slirp4netns \
  systemd-container \
  distrobox \
  nix \
  nix-daemon

# asahi support
dnf -y install \
  asahi-platform-metapackage-audio \
  asahi-platform-metapackage-desktop \
  asahi-platform-metapackage-mesa \
  mesa-vulkan-drivers

# desktop utils
dnf -y install --setopt=install_weak_deps=False \
  qt6ct \
  qt6-qtwayland \
  qt5-qtwayland \
  nwg-look \
  dconf \
  xdg-desktop-portal \
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk \
  xdg-utils \
  xdg-user-dirs \
  dbus-tools \
  mailcap

# i18n & fonts
dnf -y install \
  glibc-all-langpacks \
  default-fonts-cjk-mono \
  default-fonts-cjk-sans \
  default-fonts-cjk-serif \
  default-fonts-core-emoji \
  default-fonts-core-math \
  default-fonts-core-mono \
  default-fonts-core-sans \
  default-fonts-core-serif \
  default-fonts-other-mono \
  default-fonts-other-sans \
  default-fonts-other-serif \
  adwaita-sans-fonts \
  adwaita-mono-fonts \
  open-sans-fonts \
  aajohan-comfortaa-fonts \
  cascadia-mono-nf-fonts \
  fontawesome-6-free-fonts \
  fontawesome-6-brands-fonts \
  terminus-fonts-console

# cli
dnf -y install --setopt=install_weak_deps=False \
  git-core \
  wget2-wget \
  fd-find \
  fzf \
  ripgrep \
  eza \
  bat \
  yazi \
  resvg \
  zoxide \
  hyperfine \
  just \
  age \
  strace \
  ltrace

# power
dnf -y install --setopt=install_weak_deps=False \
  kernel-tools \
  tuned \
  tuned-ppd \
  tuned-gtk \
  upower \
  pavucontrol \
  brightnessctl \
  keyd \
  playerctl

# wayland
dnf -y install \
  libwayland-client \
  libwayland-server \
  libwayland-cursor \
  libwayland-egl \
  waybar \
  fuzzel \
  mako \
  cliphist \
  wl-clipboard \
  cage

# hyprland
dnf -y install --setopt=install_weak_deps=False \
  hyprland \
  hyprland-uwsm \
  hyprland-guiutils \
  hyprpicker \
  hyprpaper \
  hypridle \
  hyprlock \
  hyprpolkitagent \
  hyprshot \
  hyprcursor

# shell & terminal
dnf -y install --setopt=install_weak_deps=False \
  zsh \
  alacritty \
  foot \
  fastfetch \
  btop \
  ncdu

# ime
dnf -y install --setopt=install_weak_deps=False\
  fcitx5 \
  fcitx5-configtool \
  fcitx5-gtk \
  fcitx5-qt \
  fcitx5-rime \
  luajit

# fm
dnf -y install --setopt=install_weak_deps=False \
  thunar \
  thunar-volman \
  thunar-media-tags-plugin \
  thunar-archive-plugin \
  xarchiver \
  7zip \
  7zip-standalone \
  unzip

# browser
dnf -y install --setopt=install_weak_deps=False \
  chromium \
  firefox \
  firefox-langpacks

# passwd
dnf -y install \
  keepassxc \
  libsecret

# misc
dnf -y install \
  plymouth \
  plymouth-system-theme

semanage fcontext -a -t xdm_exec_t "/usr/bin/ly"

printf "NoDisplay=true\n" >> /usr/share/applications/panel-preferences.desktop
mkdir /etc/iwd
printf "[General]\nEnableNetworkConfiguration=true\n\n[Network]\nNameResolvingService=systemd\n" > /etc/iwd/main.conf

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

