#!/bin/bash
# Briefly raise pwm1 once and watch fan1/fan2.
# This test demonstrated pwm1 -> fan1 and also showed HP firmware reclaiming the value.

H=$(dirname "$(grep -l '^it8628$' /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1)")
[ -n "$H" ] || { echo "it8628 hwmon not found"; exit 1; }

OLD=$(cat "$H/pwm1")
OLDEN=$(cat "$H/pwm1_enable")
restore() { echo "$OLD" > "$H/pwm1"; echo "$OLDEN" > "$H/pwm1_enable"; }
trap restore EXIT INT TERM

TEST=$(( OLD + 25 ))
(( TEST > 255 )) && TEST=255

echo 1 > "$H/pwm1_enable"
echo "$TEST" > "$H/pwm1"

echo "Original pwm1=$OLD; wrote pwm1=$TEST"
for n in $(seq 0 15); do
    printf '%2d  pwm1=%s fan1=%s fan2=%s\n' \
        "$n" "$(cat "$H/pwm1")" "$(cat "$H/fan1_input")" "$(cat "$H/fan2_input")"
    sleep 0.5
done
