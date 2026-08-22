ARG RELEASE_VER=44
FROM docker.io/library/fedora:${RELEASE_VER} AS builder

RUN <<EORUN
set -xeuo pipefail

dnf -y --setopt=install_weak_deps=False install \
  cmake curl gcc-c++ git make tar \
  gtk3 qt5-qtbase-devel qt5-qtx11extras-devel qt6-qtbase-devel sassc

dnf clean all
EORUN

WORKDIR /opt/qogir

# qogir-adwaita-qt: Qt6 and Qt5 style plugins (built on the same architecture as the runner)
RUN <<EORUN
set -xeuo pipefail

git clone --depth 1 https://github.com/pijulius/qogir-adwaita-qt.git

cmake -S qogir-adwaita-qt -B build-qt6 \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_QT6=ON -DBUILD_EXAMPLE=OFF
cmake --build build-qt6 -j"$(nproc)"
DESTDIR=/staging cmake --install build-qt6 --prefix /usr

cmake -S qogir-adwaita-qt -B build-qt5 \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_QT6=OFF -DBUILD_EXAMPLE=OFF
cmake --build build-qt5 -j"$(nproc)"
DESTDIR=/staging cmake --install build-qt5 --prefix /usr

rm -rf build-qt6 build-qt5
EORUN

# Qogir GTK theme (standard/light/dark variants, rounded windows)
RUN <<EORUN
set -xeuo pipefail

mkdir -p /staging/usr/share/themes
git clone --depth 1 https://github.com/vinceliuice/Qogir-theme.git
Qogir-theme/install.sh -d /staging/usr/share/themes --tweaks round -t default

rm -rf Qogir-theme
EORUN

# Qogir icon theme (all variants incl. cursors)
RUN <<EORUN
set -xeuo pipefail

mkdir -p /staging/usr/share/icons
git clone --depth 1 https://github.com/vinceliuice/Qogir-icon-theme.git
Qogir-icon-theme/install.sh -d /staging/usr/share/icons -t default

rm -rf Qogir-icon-theme
EORUN

# Bibata cursors (prebuilt release artifacts)
RUN <<EORUN
set -xeuo pipefail

curl -fsSLo /tmp/oc.tar.xz https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Original-Classic.tar.xz
curl -fsSLo /tmp/mi.tar.xz https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz
tar -xJf /tmp/oc.tar.xz -C /tmp
tar -xJf /tmp/mi.tar.xz -C /tmp
cp -a /tmp/Bibata-Original-Classic /staging/usr/share/icons/
cp -a /tmp/Bibata-Modern-Ice /staging/usr/share/icons/

rm -rf /tmp/* /var/cache/* /var/log/*
EORUN

# Content-only image: themes, icons, cursors and Qt style plugins + runtime libs
FROM scratch
COPY --from=builder /staging/ /

LABEL org.opencontainers.image.source=https://github.com/0x2a2a2a/asahi-remix-atomic
LABEL org.opencontainers.image.description="Qogir themes, Bibata cursors and qogir-adwaita-qt style plugin"