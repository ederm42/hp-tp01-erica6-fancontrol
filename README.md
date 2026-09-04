# HP TP01 Erica6 Fan Control (Unraid plugin & Linux)

Small Unraid/Linux fan curve controller for the **HP Pavilion TP01** Ryzen edition which uses the **Erica6 motherboard**.

I made this because the HDDs in my TP01 were getting too hot and HP gives us basically no fan controls, and I could not get any ordinary fan controller to work. It reads Ryzen CPU temperature plus the hottest temperature from **all disks**, then drives the two motherboard fan headers. 

It was made as an **Unraid plugin**, but should also work on **other Linux distributions**.

Tested on:

- HP Pavilion Desktop TP01
- HP 8906 / Erica6 board
- Ryzen 5 5600G
- ITE IT8631E (`0x8631`)
- Unraid 7.x

## The weird bit

The IT8631E is not supported directly by the Linux `it87` driver. This project loads it using the IT8628E compatibility ID:

```bash
modprobe it87 force_id=0x8628
```

Upstream calls `force_id` a testing option, so don't blindly use this on unrelated hardware.

On **Unraid**, first install **ITE IT87 Driver** by ich777 from Community Applications. This project does not bundle the kernel driver.

On normal Linux, install Frank Crawford's external `it87` driver first: <https://github.com/frankcrawford/it87>

## Fan mapping

Confirmed by manually testing the physical fans on this TP01:

- `pwm1 / fan1` = 3-pin **SYS_FAN** = stock rear exhaust
- `pwm2 / fan2` = 4-pin **CPU_FAN** = CPU fan + my two extra fans on a splitter

Linux still calls the 3-pin header control `pwm1`; that does not mean the physical fan itself is PWM controlled.

## Curves

The Unraid plugin has an editor under **Settings -> HP TP01 Erica6 Fan Control**. Curves are simple `temperature -> control (0-255)` points. **Restore Defaults** puts the shipped config back and restarts the controller.

Defaults live in [`config/default.conf`](config/default.conf):

```text
CPU_FAN / pwm2 from CPU:  45:64 55:90 65:130 75:190 85:255
CPU_FAN / pwm2 from disk: 30:64 35:90 38:120 41:160 44:200 47:235 50:255

SYS_FAN / pwm1 from CPU:  45:110 55:130 65:165 75:210 85:255
SYS_FAN / pwm1 from disk: 30:110 35:125 38:145 41:170 44:200 47:230 50:255
```

For each header, whichever curve asks for more cooling wins. At **90C CPU** or **50C disk**, both headers go to `255`.

Disk temps are checked every 30 seconds. SATA drives are queried with `smartctl -n standby`, so sleeping disks are not intentionally woken up. Recent disk temperatures are cached for 10 minutes.

Fan values are re-written every 0.5 seconds because the HP firmware otherwise takes control back after roughly 1-2 seconds.

## Unraid

Install this URL through **Plugins -> Install Plugin**:

```text
https://raw.githubusercontent.com/ederm42/hp-tp01-erica6-fancontrol/main/unraid/hp-tp01-erica6-fancontrol.plg
```

Or install a downloaded copy:

```bash
plugin install /tmp/hp-tp01-erica6-fancontrol.plg
```

Then open **Settings -> HP TP01 Erica6 Fan Control**.

Useful commands:

```bash
/etc/rc.d/rc.hp-tp01-erica6-fancontrol status
/etc/rc.d/rc.hp-tp01-erica6-fancontrol restart
tail -f /var/log/hp-tp01-erica6-fancontrol.log
```

Config lives at:

```text
/boot/config/plugins/hp-tp01-erica6-fancontrol/hp-tp01-erica6-fancontrol.conf
```

## Normal Linux

Requirements: Bash, `smartmontools`, `lsblk`, systemd, and the external `it87` driver.

```bash
sudo ./scripts/install.sh
systemctl status hp-tp01-erica6-fancontrol
```

Config: `/etc/hp-tp01-erica6-fancontrol.conf`

The repo default/example config is `config/default.conf`.

## How this was figured out

The hardware discovery and manual test scripts are documented in [`docs/how-we-got-here.md`](docs/how-we-got-here.md). It includes the actual little scripts used to map the channels, prove the HP firmware overwrite, run full blast, and watch disk temperatures.

## Safety / weirdness

This is specifically for the TP01 setup above. The actual IT8631E is being forced to another supported `it87` ID. This project only trusts the fan controls plus Ryzen `k10temp`; don't trust random voltage/temp readings from the forced ITE profile.

The project deliberately does **not** use `fix_pwm_polarity=1` or `ignore_resource_conflict=1`.

If the CPU sensor fails, both fan channels go full speed. When the controller stops, it writes `255` once and lets HP firmware take back over.

## License

MIT. Have fun, and please report other TP01 board revisions if you try it.
