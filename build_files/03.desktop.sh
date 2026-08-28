#!/usr/bin/env bash
set -xeuo pipefail

dnf -y --setopt=install_weak_deps=False --nodocs install \
  glibc-langpack-en glibc-langpack-zh \
  default-fonts-cjk-mono default-fonts-cjk-sans default-fonts-cjk-serif \
  default-fonts-core-emoji default-fonts-core-math default-fonts-core-mono default-fonts-core-sans default-fonts-core-serif \
  default-fonts-other-mono default-fonts-other-sans default-fonts-other-serif \
  aajohan-comfortaa-fonts adwaita-sans-fonts adwaita-mono-fonts cascadia-mono-nf-fonts \
  fontawesome-6-free-fonts fontawesome-6-brands-fonts open-sans-fonts terminus-fonts-console

dnf -y --setopt=install_weak_deps=False --nodocs install \
  ly polkit qt6ct qt6-qtwayland qt5-qtwayland dconf nwg-look gtk-murrine-engine \
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
  xdg-utils xdg-user-dirs dbus-tools libsecret sassc pavucontrol brightnessctl playerctl

# dnf -y --setopt=install_weak_deps=False --nodocs install \
#   hyprland hyprland-uwsm hyprland-guiutils hyprpicker hyprpaper \
#   hypridle hyprlock hyprpolkitagent hyprshot hyprcursor \
#   fuzzel waybar cliphist wl-clipboard alacritty foot keepassxc matugen imv mpv

dnf -y --setopt=install_weak_deps=False --nodocs install \
  mangowm fuzzel foot alacritty waybar swaybg mako wl-clipboard cliphist \
  wlogout xfce-polkit grim slurp swaylock swayidle imv mpv keepassxc matugen \
  wlr-randr kanshi uwsm

dnf -y --setopt=install_weak_deps=False --nodocs install \
  fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-rime luajit

dnf -y --setopt=install_weak_deps=False --nodocs install \
  thunar thunar-volman thunar-media-tags-plugin thunar-archive-plugin \
  xarchiver 7zip-standalone 7zip gvfs

dnf -y --setopt=install_weak_deps=False --nodocs install \
  chromium
