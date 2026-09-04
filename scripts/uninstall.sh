#!/bin/bash
set -e

[[ $EUID -eq 0 ]] || { echo "Run this as root."; exit 1; }

systemctl disable --now hp-tp01-erica6-fancontrol 2>/dev/null || true
rm -f /etc/systemd/system/hp-tp01-erica6-fancontrol.service
rm -f /usr/local/sbin/hp-tp01-erica6-fancontrol
systemctl daemon-reload

echo "Removed. /etc/hp-tp01-erica6-fancontrol.conf was kept."
