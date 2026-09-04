#!/bin/bash
# Hold pwm1 at a higher value by rewriting it every 0.5 seconds.
# This proved that frequent reassertion can beat the HP firmware overwrite.

H=$(dirname "$(grep -l '^it8628$' /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1)")
[ -n "$H" ] || { echo "it8628 hwmon not found"; exit 1; }

OLD=$(cat "$H/pwm1")
OLDEN=$(cat "$H/pwm1_enable")
restore() { echo "$OLD" > "$H/pwm1"; echo "$OLDEN" > "$H/pwm1_enable"; }
trap restore EXIT INT TERM

TEST=$(( OLD + 25 ))
(( TEST > 255 )) && TEST=255

echo 1 > "$H/pwm1_enable"
echo "Holding pwm1=$TEST for 10 seconds"
for n in $(seq 1 20); do
    echo "$TEST" > "$H/pwm1"
    printf '%2d  pwm1=%s fan1=%s fan2=%s\n' \
        "$n" "$(cat "$H/pwm1")" "$(cat "$H/fan1_input")" "$(cat "$H/fan2_input")"
    sleep 0.5
done
