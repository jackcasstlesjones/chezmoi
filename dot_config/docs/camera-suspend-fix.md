# Camera Suspend/Resume Fix

## Issue

Integrated RGB Camera (SunplusIT 174f:11b4) disconnects after system suspend and doesn't come back on resume.

**Symptoms:**

- Camera works fine after boot
- After suspend/resume, camera disappears from `lsusb`
- `dmesg` shows: `usb 1-1: PM: dpm_run_callback(): usb_dev_resume returns -22`
- Camera remains disconnected until reboot or manual USB controller reset

## Root Cause

Camera's USB resume callback fails with error -22 (EINVAL). This is a firmware/driver bug in the SunplusIT camera controller where the device fails to properly handle the USB resume process.

## Solution

Created systemd service that automatically resets the USB controller after suspend/resume if camera is missing.

### Script

`~/.config/scripts/reset-camera-usb.sh` (managed via chezmoi):

```bash
#!/bin/bash
# Reset USB controller to restore camera after suspend
# Camera: SunplusIT Integrated RGB Camera (174f:11b4)
# USB Controller: 0000:c4:00.4 (usb1)

sleep 2

if ! lsusb | grep -q "174f:11b4"; then
    echo "Camera not found after resume, resetting USB controller..."
    echo "0000:c4:00.4" > /sys/bus/pci/drivers/xhci_hcd/unbind
    sleep 2
    echo "0000:c4:00.4" > /sys/bus/pci/drivers/xhci_hcd/bind
    sleep 2

    if lsusb | grep -q "174f:11b4"; then
        echo "Camera successfully restored"
        exit 0
    else
        echo "Camera still not detected"
        exit 1
    fi
else
    echo "Camera already present, no action needed"
    exit 0
fi
```

### Systemd Service

`/etc/systemd/system/reset-camera-after-suspend.service`:

```ini
[Unit]
Description=Reset USB controller to restore camera after suspend
After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
ExecStart=/home/jack/.config/scripts/reset-camera-usb.sh

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
```

**Enable:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable reset-camera-after-suspend.service
```

## USB Autosuspend Prevention

The older `camera-no-autosuspend.service` prevents USB autosuspend during normal operation but doesn't fix the suspend/resume issue. Both services can run together:

- `camera-no-autosuspend.service` - Prevents autosuspend during normal use
- `reset-camera-after-suspend.service` - Fixes camera after system suspend

### Autosuspend Service
`~/.config/scripts/disable-camera-autosuspend.sh` (managed via chezmoi):

```bash
#!/bin/bash
# Disable USB autosuspend for SunplusIT camera (174f:11b4)
# This prevents the camera from randomly becoming unavailable during video calls

for dev in /sys/bus/usb/devices/*; do
    if [ -f "$dev/idVendor" ] && [ "$(cat "$dev/idVendor")" = "174f" ] && \
       [ -f "$dev/idProduct" ] && [ "$(cat "$dev/idProduct")" = "11b4" ]; then
        echo on > "$dev/power/control"
        echo "Disabled autosuspend for camera at $dev"
        exit 0
    fi
done

echo "Camera device 174f:11b4 not found"
exit 1
```

`/etc/systemd/system/camera-no-autosuspend.service`:

```ini
[Unit]
Description=Disable USB autosuspend for SunplusIT camera
After=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
ExecStart=/home/jack/.config/scripts/disable-camera-autosuspend.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
```

**Enable:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable camera-no-autosuspend.service
```

### TLP Configuration
TLP is also configured with camera in denylist (`/etc/tlp.conf`):

```
USB_DENYLIST="174f:11b4"
```

## Verification

```bash
# Check camera is present
lsusb | grep 174f

# Check service logs after suspend/resume
journalctl -u reset-camera-after-suspend.service -b

# Verify TLP settings
tlp-stat -u | grep -A 2 "174f:11b4"
```

## Manual Reset (if needed)

```bash
echo "0000:c4:00.4" | sudo tee /sys/bus/pci/drivers/xhci_hcd/unbind
sleep 2
echo "0000:c4:00.4" | sudo tee /sys/bus/pci/drivers/xhci_hcd/bind
```

## Alternative: Kernel Parameter

More elegant solution using USB quirks (prevents suspend at kernel level).

**Note: This system uses systemd-boot, not GRUB.**

Add to systemd-boot entry `/boot/loader/entries/*.conf` on the `options` line:

```
options ... usbcore.quirks=174f:11b4:b
```

The `:b` flag disables autosuspend for this device at the kernel level.

Example:
```
options root=PARTUUID=xxx zswap.enabled=0 rw rootfstype=ext4 usbcore.quirks=174f:11b4:b
```

## Status

**Working as of:** 2024-12-03

The USB controller reset approach successfully restores the camera after suspend/resume.
