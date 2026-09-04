#!/bin/bash
# Print temperatures for all visible physical disks every 30 seconds.
# SATA/SAS disks use smartctl -n standby so this should not intentionally wake sleeping HDDs.
# Stop with Ctrl+C; terminal history can then be used to inspect the cooling trend.

while true; do
    echo
    echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="

    while read -r dev type; do
        [ "$type" = "disk" ] || continue
        path="/dev/$dev"

        if [[ "$path" == /dev/nvme* ]]; then
            temp=$(smartctl -A "$path" 2>/dev/null | awk '/^Temperature:/ {print $2; exit}')
        else
            temp=$(smartctl -A -n standby "$path" 2>/dev/null | awk '
                ($1==190 || $1==194) && $10 ~ /^[0-9]+$/ {print $10; exit}
                /Current Drive Temperature:/ {for(i=1;i<=NF;i++) if($i~/^[0-9]+$/){print $i; exit}}
            ')
        fi

        if [ -n "$temp" ]; then
            echo "$path: ${temp}C"
        else
            echo "$path: sleeping / no temperature"
        fi
    done < <(lsblk -dn -o NAME,TYPE)

    sleep 30
done
