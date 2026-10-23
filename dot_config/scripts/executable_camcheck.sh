#!/bin/bash
# Print whether camera USB autosuspend is disabled (ok) or not
# Camera: SunplusIT RGB Camera (174f:11b4)

DEVICE_PATH="/sys/bus/usb/devices/1-1"

if [ ! -f "$DEVICE_PATH/power/control" ]; then
    echo "not ok: camera device not found"
    exit 1
fi

STATUS=$(cat "$DEVICE_PATH/power/control" 2>/dev/null)
RUNTIME=$(cat "$DEVICE_PATH/power/runtime_status" 2>/dev/null)

case "$STATUS" in
    "on")
        echo "ok: autosuspend disabled ($RUNTIME)"
        ;;
    "auto")
        echo "not ok: autosuspend enabled ($RUNTIME) - run disable-camera-autosuspend.sh"
        exit 1
        ;;
    *)
        echo "not ok: unknown power status"
        exit 1
        ;;
esac
