# How we got here

This is the short version of how `hp-tp01-erica6-fancontrol` came together on the tested HP Pavilion TP01.

The important part: I did not start by assuming the fan mapping. I poked the hardware, watched RPMs, and corrected the mapping after physically checking which fan actually changed.

## 1. Find the fan controller

`sensors-detect` found an unknown ITE Super I/O with chip ID `0x8631`. That is an **ITE IT8631E**.

The external Linux `it87` driver does not directly support that ID, so I tested it with the closest supported compatibility ID I had available:

```bash
# Reload the external it87 driver and make the unsupported IT8631E
# identify as an IT8628E so Linux exposes its hwmon fan controls.
modprobe -r it87 2>/dev/null
modprobe it87 force_id=0x8628
```

That produced an `it8628` hwmon device and exposed `fan1_input`, `fan2_input`, `pwm1`, `pwm2`, and their enable files.

I only trust the fan-related controls from this forced profile. Random voltage and temperature readings from the ITE device may be wrong.

## 2. Inspect what Linux exposed

I used [`test-scripts/01-show-hwmon.sh`](test-scripts/01-show-hwmon.sh) to print the fan control files and current RPMs.

Initial values were roughly:

```text
pwm1 ~110   fan1 ~1000 RPM
pwm2 ~64    fan2 ~1120 RPM
```

At this point those were only **channel 1** and **channel 2**. I should not have attached physical fan names yet.

## 3. Prove each control affects only its matching tach channel

I first nudged `pwm1` and watched `fan1` rise while `fan2` stayed basically unchanged.

Then I held `pwm1` by rewriting it every 0.5 seconds. This was important because HP firmware was rewriting the value after about 1–2 seconds.

Scripts:

- [`02-test-pwm1.sh`](test-scripts/02-test-pwm1.sh)
- [`03-hold-pwm1.sh`](test-scripts/03-hold-pwm1.sh)

I then did the same for `pwm2`:

- [`04-hold-pwm2.sh`](test-scripts/04-hold-pwm2.sh)

Result:

```text
pwm1 -> fan1
pwm2 -> fan2
```

That mapping at the Linux hwmon level is solid.

## 4. Discover the HP firmware fight

A one-time write such as:

```bash
# Put channel 1 in manual mode and request a higher control value once.
echo 1 > "$H/pwm1_enable"
echo 134 > "$H/pwm1"
```

worked, but after roughly 1–2 seconds the value changed again without me touching it.

The solution was simple: keep reasserting the requested value faster than the firmware does. Rewriting every **0.5 seconds** proved reliable and has negligible overhead.

That is why the final daemon writes both fan controls every 0.5 seconds even when the target has not changed.

## 5. Full-speed test

Once both channels were mapped, I ran both at `255` and kept rewriting them until Ctrl+C:

- [`05-full-blast.sh`](test-scripts/05-full-blast.sh)

Both channels responded, which proved Linux could take useful control of the cooling hardware.

## 6. Correct the physical header mapping

This is where I fixed an early mistake.

The RPM tests proved `pwm1 -> fan1` and `pwm2 -> fan2`, but initially I guessed which motherboard header each pair represented. Later manual fan testing established the real physical mapping:

```text
pwm1 / fan1 = 3-pin SYS_FAN
              stock rear exhaust

pwm2 / fan2 = 4-pin CPU_FAN
              CPU fan + two additional fans on a splitter
```

This mapping is what the project now uses everywhere.

Linux calls the 3-pin SYS_FAN control `pwm1` because `pwmN` is the hwmon interface name. The physical 3-pin fan is most likely being speed-controlled by voltage/DC, not by a fourth PWM wire.

## 7. Add temperatures

CPU temperature comes from AMD `k10temp`, preferring `Tctl`.

Disk temperature is intentionally based on **all physical disks**, because hot HDDs were the reason for this project. I poll them every 30 seconds using `smartctl`.

For SATA disks I use:

```bash
# Read SMART data only if the drive is already awake.
# -n standby avoids intentionally spinning up a sleeping HDD just for temperature.
smartctl -n standby -A /dev/sdX
```

A recent disk temperature is cached for 10 minutes so a disk that just spun down does not instantly make the controller drop its cooling demand.

For a simple standalone disk-temperature logger, see:

- [`06-log-disk-temps.sh`](test-scripts/06-log-disk-temps.sh)

## 8. Final control logic

The final daemon has four simple curves:

```text
CPU temperature  -> SYS_FAN  (pwm1)
Disk temperature -> SYS_FAN  (pwm1)
CPU temperature  -> CPU_FAN  (pwm2)
Disk temperature -> CPU_FAN  (pwm2)
```

For each physical header, whichever curve asks for the higher control value wins.

That matters on this machine because most of the useful case airflow is attached to the 4-pin `CPU_FAN` splitter, so disk temperature is allowed to ramp that header too.

The shipped values live in [`../config/default.conf`](../config/default.conf) and can be edited from the Unraid settings page.

Emergency behavior is deliberately boring:

- CPU sensor failure -> both controls `255`
- CPU reaches emergency temperature -> both controls `255`
- hottest disk reaches emergency temperature -> both controls `255`
- daemon exits -> writes `255` once, then HP firmware can take control back

## Things I deliberately do not do

I do **not** use:

```text
fix_pwm_polarity=1
ignore_resource_conflict=1
```

They were not needed on the tested machine, and the first one is explicitly dangerous on the external driver.

I also do not use the forced ITE profile's temperature or voltage readings for control decisions. CPU temperature comes from `k10temp`; disk temperatures come from SMART.
