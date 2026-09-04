#!/bin/bash
# Show the IT8628 compatibility hwmon device, fan RPMs and current control values.
# This is a read-only inspection script; it does not change fan speeds.

H=$(dirname "$(grep -l '^it8628$' /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1)")
[ -n "$H" ] || { echo "it8628 hwmon not found"; exit 1; }

echo "hwmon: $H"
for f in pwm1 pwm1_enable fan1_input pwm2 pwm2_enable fan2_input; do
    printf '%-12s ' "$f"
    cat "$H/$f"
done
