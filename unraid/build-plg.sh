#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/unraid/hp-tp01-erica6-fancontrol.plg"
VERSION="${VERSION:-1.0.0}"
REPO="${REPO:-ederm42/hp-tp01-erica6-fancontrol}"
AUTHOR="${AUTHOR:-ederm42}"
PLUGIN_URL="https://raw.githubusercontent.com/$REPO/main/unraid/hp-tp01-erica6-fancontrol.plg"
SUPPORT_URL="https://github.com/$REPO/issues"
ICON_NAME="hp-tp01-erica6-fancontrol.png"

emit_file() {
    local dest=$1 src=$2
    cat >> "$OUT" <<EOF2
<FILE Name="$dest">
<INLINE><![CDATA[
EOF2
    cat "$src" >> "$OUT"
    cat >> "$OUT" <<'EOF2'
]]></INLINE>
</FILE>

EOF2
}

emit_icon() {
    local b64
    b64=$(base64 -w 0 "$ROOT/assets/fan.png")
    cat >> "$OUT" <<EOF2
<FILE Run="/bin/bash">
<INLINE><![CDATA[
mkdir -p /usr/local/emhttp/plugins/hp-tp01-erica6-fancontrol
printf '%s' '$b64' | base64 -d > /usr/local/emhttp/plugins/hp-tp01-erica6-fancontrol/$ICON_NAME
chmod 0644 /usr/local/emhttp/plugins/hp-tp01-erica6-fancontrol/$ICON_NAME
]]></INLINE>
</FILE>

EOF2
}

cat > "$OUT" <<EOF2
<?xml version='1.0' standalone='yes'?>
<!DOCTYPE PLUGIN [
<!ENTITY name "hp-tp01-erica6-fancontrol">
<!ENTITY author "$AUTHOR">
<!ENTITY version "$VERSION">
<!ENTITY pluginURL "$PLUGIN_URL">
<!ENTITY supportURL "$SUPPORT_URL">
<!ENTITY icon "$ICON_NAME">
<!ENTITY plugin "/boot/config/plugins/&name;">
<!ENTITY emhttp "/usr/local/emhttp/plugins/&name;">
]>

<PLUGIN name="&name;" author="&author;" version="&version;" launch="Settings/HPErica6FanControl" pluginURL="&pluginURL;" support="&supportURL;" icon="&icon;" min="6.12.0">

<CHANGES>
### &version;
- First clean release as hp-tp01-erica6-fancontrol.
- Confirmed mapping: pwm1/fan1 is rear SYS_FAN; pwm2/fan2 is CPU_FAN + splitter.
- Editable fan curves, Restore Defaults, disk temperature monitoring and fail-safe full speed.
</CHANGES>

EOF2

cat >> "$OUT" <<'EOF2'
<!-- Kernel driver dependency stays separate on purpose. -->
<FILE Run="/bin/bash">
<INLINE><![CDATA[
if ! modinfo it87 >/dev/null 2>&1; then
    echo ""
    echo "WARNING: it87 is not available yet."
    echo "Install 'ITE IT87 Driver' by ich777 from Community Applications."
    echo "The fan controller will stay stopped until the driver is available."
    echo ""
fi

for cmd in smartctl lsblk timeout; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "WARNING: missing required command: $cmd"
    fi
done
]]></INLINE>
</FILE>

EOF2

emit_icon
emit_file "&emhttp;/scripts/&name;" "$ROOT/src/hp-tp01-erica6-fancontrol"
emit_file "&emhttp;/default.conf" "$ROOT/config/default.conf"
emit_file "&emhttp;/HPErica6FanControl.page" "$ROOT/unraid/HPErica6FanControl.page"
emit_file "&emhttp;/event/started" "$ROOT/unraid/started"
emit_file "&emhttp;/event/stopping" "$ROOT/unraid/stopping"
emit_file "/etc/rc.d/rc.hp-tp01-erica6-fancontrol" "$ROOT/unraid/rc.hp-tp01-erica6-fancontrol"

cat >> "$OUT" <<'EOF2'
<FILE Run="/bin/bash">
<INLINE><![CDATA[
mkdir -p /boot/config/plugins/hp-tp01-erica6-fancontrol
chmod +x /usr/local/emhttp/plugins/hp-tp01-erica6-fancontrol/scripts/hp-tp01-erica6-fancontrol
chmod +x /usr/local/emhttp/plugins/hp-tp01-erica6-fancontrol/event/started
chmod +x /usr/local/emhttp/plugins/hp-tp01-erica6-fancontrol/event/stopping
chmod +x /etc/rc.d/rc.hp-tp01-erica6-fancontrol

CFG=/boot/config/plugins/hp-tp01-erica6-fancontrol/hp-tp01-erica6-fancontrol.conf
DEFAULT=/usr/local/emhttp/plugins/hp-tp01-erica6-fancontrol/default.conf
if [ ! -f "$CFG" ]; then
    cp "$DEFAULT" "$CFG"
fi

/etc/rc.d/rc.hp-tp01-erica6-fancontrol restart || true

echo ""
echo "HP TP01 Erica6 Fan Control installed."
echo "Open Settings > HP TP01 Erica6 Fan Control."
echo ""
]]></INLINE>
</FILE>

<FILE Run="/bin/bash" Method="remove">
<INLINE><![CDATA[
/etc/rc.d/rc.hp-tp01-erica6-fancontrol stop 2>/dev/null || true
rm -f /etc/rc.d/rc.hp-tp01-erica6-fancontrol
rm -rf /usr/local/emhttp/plugins/hp-tp01-erica6-fancontrol
rm -rf /boot/config/plugins/hp-tp01-erica6-fancontrol
rm -f /var/run/hp-tp01-erica6-fancontrol.* /var/log/hp-tp01-erica6-fancontrol.log

echo "HP TP01 Erica6 Fan Control removed."
]]></INLINE>
</FILE>

</PLUGIN>
EOF2

echo "Built $OUT"
