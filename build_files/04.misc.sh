#!/usr/bin/env bash
set -xeuo pipefail

cp -avf "/ctx/system_files"/. /

semanage fcontext -a -f f -t xdm_exec_t "/usr/bin/ly"
semodule -i /ctx/nix.pp

printf "NoDisplay=true\n" >> /usr/share/applications/panel-preferences.desktop

systemctl enable \
  keyd.service \
  tuned.service \
  tuned-ppd.service \
  nix-daemon.socket \
  ly@tty7.service

systemctl mask wpa_supplicant.service

dnf repoquery --installed --qf "%{name} %{installsize}\n" | numfmt --field 2 --to=iec > /usr/share/installed_pkg.txt
