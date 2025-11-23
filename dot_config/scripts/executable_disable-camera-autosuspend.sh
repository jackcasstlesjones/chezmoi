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
