ARG FEDORA_VERSION
FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION} AS builder
RUN dnf -y install 'dnf5-plugins' && \
    dnf -y copr enable @asahi/fedora-remix-branding && \
    dnf -y install asahi-repos

RUN /usr/libexec/bootc-base-imagectl build-rootfs \
  --manifest=minimal \
  --exclude kernel \
  --install kernel-16k \
  --install asahi-platform-metapackage-core \
  --install iwd \
  --install bluez \
  --install micro \
  --install bash-completion \
  --install linux-firmware \
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

dnf -y install --setopt=install_weak_deps=False \
  asahi-repos binutils busybox trfs-progs cryptsetup exfatprogs hostname iproute iptables-nft iputils \
  lsof less mesa-dri-drivers mesa-vulkan-drivers openssh-clients openssh-server \
  plymouth plymouth-system-theme python-unversioned-command psmisc rpm-ostree rsync sudo tar time tree \
  usbutils vim-minimal wget2-wget which whois zram-generator-defaults \
  git-core slirp4netns fuse-overlayfs systemd-container ncurses hfsplus-tools \
  fd-find fzf eza bat zsh ripgrep yazi resvg zoxide btop fastfetch ncdu hyperfine openssl \
  strace ltrace lsof socat just age distrobox ly keyd brightnessctl pavucontrol libsecret \
  logrotate polkit tuned tuned-ppd upower jq kernel-tools

dnf -y install asahi-platform-metapackage-audio asahi-platform-metapackage-desktop asahi-platform-metapackage-mesa

dnf -y install glibc-all-langpacks default-fonts-cjk-mono default-fonts-cjk-sans default-fonts-cjk-serif \
  default-fonts-core-emoji default-fonts-core-math default-fonts-core-mono default-fonts-core-sans default-fonts-core-serif \
  default-fonts-other-mono default-fonts-other-sans default-fonts-other-serif adwaita-sans-fonts adwaita-mono-fonts open-sans-fonts \
  aajohan-comfortaa-fonts cascadia-mono-nf-fonts fontawesome-6-free-fonts fontawesome-6-brands-fonts terminus-fonts-console

dnf -y install --setopt=install_weak_deps=False \
  hyprland hyprland-uwsm hyprland-guiutils hyprpicker hyprpaper hypridle hyprlock hyprpolkitagent hyprshot hyprcursor \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal xdg-utils xdg-user-dirs dbus-tools dconf qt6ct nwg-look \
  mailcap wl-clipboard

dnf -y install --setopt=install_weak_deps=False \
  qt6-qtwayland qt5-qtwayland alacritty foot cage mako waybar fuzzel cliphist keepassxc \
  fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-rime luajit \
  thunar thunar-volman thunar-media-tags-plugin thunar-archive-plugin xarchiver 7zip unzip unzip \
  chromium firefox firefox-langpacks nix nix-daemon tuned-gtk

semanage fcontext -a -t xdm_exec_t "/usr/bin/ly"

printf "NoDisplay=true\n" >> /usr/share/applications/panel-preferences.desktop
mkdir /etc/iwd
printf "[General]\nEnableNetworkConfiguration=true\n\n[Network]\nNameResolvingService=systemd\n" > /etc/iwd/main.conf

systemctl enable iwd.service keyd.service tuned.service tuned-ppd.service nix-daemon.socket ly@tty7.service

# Remove leftover build artifacts from installing packages in the final built image.
dnf clean all

# rm -f /boot/symvers*
# rm -rf /run/* /run/.* /tmp/* /tmp/.* 2>/dev/null || true
# rm -rf /var/cache/* /var/log/* /var/lib/dnf/* /var/db/sudo /var/spool/plymouth

# Run the bootc linter to avoid encountering certain bugs and maintain content quality. Place this as the final command in your last run invoaction.
bootc container lint
EORUN

LABEL containers.bootc 1
LABEL ostree.bootable 1

ENV container=oci
STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]

