#!/bin/bash
# Force both fan-control channels to 255 until Ctrl+C.
# Rewrites every 0.5 seconds so HP firmware cannot immediately reclaim the values.
# On exit it restores the values and enable modes that were present when the test started.

H=$(dirname "$(grep -l '^it8628$' /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1)")
[ -n "$H" ] || { echo "it8628 hwmon not found"; exit 1; }

OLD1=$(cat "$H/pwm1")
OLD2=$(cat "$H/pwm2")
OLDEN1=$(cat "$H/pwm1_enable")
OLDEN2=$(cat "$H/pwm2_enable")

restore() {
    echo
    echo "Restoring previous fan settings..."
    echo "$OLD1" > "$H/pwm1"
    echo "$OLD2" > "$H/pwm2"
    echo "$OLDEN1" > "$H/pwm1_enable"
    echo "$OLDEN2" > "$H/pwm2_enable"
}
trap restore EXIT INT TERM

echo 1 > "$H/pwm1_enable"
echo 1 > "$H/pwm2_enable"
echo "FULL BLAST - Ctrl+C to stop"

while true; do
    echo 255 > "$H/pwm1"
    echo 255 > "$H/pwm2"
    printf 'SYS_FAN fan1=%s RPM | CPU_FAN fan2=%s RPM\n' \
        "$(cat "$H/fan1_input")" "$(cat "$H/fan2_input")"
    sleep 0.5
done
