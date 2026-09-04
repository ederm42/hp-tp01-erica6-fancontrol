#!/bin/bash
set -e

[[ $EUID -eq 0 ]] || { echo "Run this as root."; exit 1; }

for cmd in bash smartctl lsblk timeout modprobe modinfo; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Missing: $cmd"; exit 1; }
done

modinfo it87 >/dev/null 2>&1 || {
    echo "Missing it87 driver. Install Frank Crawford's external it87 driver first."
    exit 1
}

NEW_NAME=hp-tp01-erica6-fancontrol

install -m 0755 src/$NEW_NAME /usr/local/sbin/$NEW_NAME

CFG=/etc/$NEW_NAME.conf
if [[ ! -e "$CFG" ]]; then
    install -m 0644 config/default.conf "$CFG"
fi

install -m 0644 systemd/$NEW_NAME.service /etc/systemd/system/$NEW_NAME.service

systemctl daemon-reload
systemctl enable --now hp-tp01-erica6-fancontrol

echo "Installed."
echo "Status: systemctl status hp-tp01-erica6-fancontrol"
echo "Logs:   journalctl -u hp-tp01-erica6-fancontrol -f"
