#!/bin/bash
# Hold pwm2 at a higher value by rewriting it every 0.5 seconds.
# This proved pwm2 -> fan2 independently of pwm1/fan1.

H=$(dirname "$(grep -l '^it8628$' /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1)")
[ -n "$H" ] || { echo "it8628 hwmon not found"; exit 1; }

OLD=$(cat "$H/pwm2")
OLDEN=$(cat "$H/pwm2_enable")
restore() { echo "$OLD" > "$H/pwm2"; echo "$OLDEN" > "$H/pwm2_enable"; }
trap restore EXIT INT TERM

TEST=$(( OLD + 30 ))
(( TEST > 255 )) && TEST=255

echo 1 > "$H/pwm2_enable"
echo "Holding pwm2=$TEST for 10 seconds"
for n in $(seq 1 20); do
    echo "$TEST" > "$H/pwm2"
    printf '%2d  pwm1=%s fan1=%s pwm2=%s fan2=%s\n' \
        "$n" "$(cat "$H/pwm1")" "$(cat "$H/fan1_input")" \
        "$(cat "$H/pwm2")" "$(cat "$H/fan2_input")"
    sleep 0.5
done
