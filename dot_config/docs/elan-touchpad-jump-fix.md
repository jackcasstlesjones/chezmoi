# ELAN Touchpad Sensitivity Issues

## Issue
Touchpad sensitivity randomly changing - becomes sluggish then returns to normal.
Started after Jan 29 2026 update (kernel 6.18.6 -> 6.18.7, Hyprland 0.53.1 -> 0.53.3).

## Diagnosis

### libinput debug
```bash
sudo pacman -S libinput-tools
sudo libinput debug-events --device /dev/input/event8 2>&1 | grep -iE "palm|thumb|speed|device|reset|error|warn|jump"
```

Showed errors:
```
kernel bug: Touch jump detected and discarded.
```

### Attempted fixes that didn't work

**elan_i2c module** - Did not help, errors persist:
```bash
sudo modprobe elan_i2c
```

**Split lock mitigation** - System logs showed Steam causing split lock traps, but disabling didn't help:
```bash
sudo sysctl kernel.split_lock_mitigate=0
```

## Likely cause
Kernel 6.18.7 regression. Need to confirm by booting into linux-lts (6.12.68).

## Next steps
1. Reboot and select **linux-lts** from bootloader
2. Test touchpad
3. If fixed on LTS, report kernel regression or stick with LTS

## References
- https://wayland.freedesktop.org/libinput/doc/latest/touchpad-jumping-cursors.html
- https://bbs.archlinux.org/viewtopic.php?id=274049
- https://gitlab.freedesktop.org/libinput/libinput/-/issues/572
