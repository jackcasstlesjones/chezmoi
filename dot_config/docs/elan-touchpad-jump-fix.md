# ELAN Touchpad Sensitivity Issues

## Issue
Touchpad sensitivity randomly changing - becomes sluggish then returns to normal.
Two-finger gestures (pinch-to-zoom, scroll) reliably trigger the issue.

## System details

- ThinkPad T14 Gen 6 (21QJCTO1WW), AMD, kernel 6.18.8-arch2-1
- Hyprland 0.53.3 (Wayland), libinput 1.30.1
- Touchpad: ELAN0678:00 04F3:3195 (i2c-hid, hid-multitouch driver)
- Touchpad bus: i2c via AMDI0010:01 controller
- Only affects trackpad, not bluetooth mouse

## Diagnosis

### libinput debug-events
```bash
sudo libinput debug-events --device /dev/input/event8
```

Sometimes shows:
```
kernel bug: Touch jump detected and discarded.
```
But the sluggishness also occurs **without** this error appearing.
When the sluggishness happens without the error, POINTER_MOTION events continue flowing normally from libinput — suggesting the problem may be above libinput (in the compositor or between devices).

### HID device quirks (from sysfs)
```
Quirks value: 334864 (0x51C10)
Active: ALWAYS_VALID, IGNORE_DUPLICATES, HOVERING, CONTACT_CNT_ACCURATE, STICKY_FINGERS, WIN8_PTP_BUTTONS
```
**MT_QUIRK_CONFIDENCE is NOT set** — the kernel is NOT doing confidence-bit-based palm rejection on this device. Earlier theory about confidence=0 mapping to MT_TOOL_PALM was incorrect.

### Touchpad exposes two input devices
- `event7`: ELAN0678:00 04F3:3195 **Mouse** (relative, REL_X/REL_Y)
- `event8`: ELAN0678:00 04F3:3195 **Touchpad** (absolute, multitouch)

Both are registered as mice in Hyprland.

### Attempted fixes that didn't work

- `sudo modprobe elan_i2c` — no effect
- `sudo sysctl kernel.split_lock_mitigate=0` — no effect
- Disabling i2c autosuspend (`echo on > /sys/devices/platform/AMDI0010:01/power/control`) — no effect
- Removing MT_QUIRK_STICKY_FINGERS via sysfs quirks — no effect
- Removing libinput quirks file (`/etc/libinput/local-overrides.quirks`) — no effect
- Disabling `disable_while_typing` in Hyprland — no effect
- Reloading hid-multitouch module — not yet tested

### Other findings

- **i2c controller power management**: `control: auto`, `autosuspend_delay_ms: 1000`, controller enters `suspended` when idle — not confirmed as a cause
- **TLP**: active, `performance/AC` profile, only custom config: `USB_DENYLIST="174f:11b4"`
- **keyd**: only remaps capslock to hyper (`overload(hyper, esc)`), no mouse interaction
- **No scripts or processes** dynamically modifying input settings via hyprctl
- **libinput quirks** (from `/etc/libinput/local-overrides.quirks`): `AttrPressureRange=10:8`, `AttrPalmPressureThreshold=150`

## Next steps
1. Reboot and select **linux-lts** (6.12.69) from bootloader to test for kernel regression
2. If kernel regression confirmed, stick with LTS or report upstream
3. If issue persists on LTS, consider Timeshift revert to `2026-01-13_08-22-52`

## References
- https://wayland.freedesktop.org/libinput/doc/latest/touchpad-jumping-cursors.html
- https://bbs.archlinux.org/viewtopic.php?id=274049
- https://bbs.archlinux.org/viewtopic.php?id=289144 (same symptom: libinput misclassifies motion as POINTER_SCROLL_FINGER)
- https://gitlab.freedesktop.org/libinput/libinput/-/issues/572
- https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1778087 (ELAN touchpad jumps/disconnects)
