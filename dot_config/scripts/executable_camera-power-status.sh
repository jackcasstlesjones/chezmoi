#!/bin/bash
# Display camera USB power control status for waybar
# Camera: SunplusIT RGB Camera (174f:11b4)

DEVICE_PATH="/sys/bus/usb/devices/1-1"

if [ ! -f "$DEVICE_PATH/power/control" ]; then
    echo '{"text":"❌","class":"critical","tooltip":"Camera device not found"}'
    exit 0
fi

STATUS=$(cat "$DEVICE_PATH/power/control" 2>/dev/null)
RUNTIME=$(cat "$DEVICE_PATH/power/runtime_status" 2>/dev/null)

case "$STATUS" in
    "on")
        echo "{\"text\":\"✓\",\"class\":\"good\",\"tooltip\":\"Camera autosuspend: disabled ($RUNTIME)\"}"
        ;;
    "auto")
        echo "{\"text\":\"⚠\",\"class\":\"warning\",\"tooltip\":\"Camera autosuspend: ENABLED ($RUNTIME) - may cause issues!\"}"
        ;;
    *)
        echo "{\"text\":\"?\",\"class\":\"unknown\",\"tooltip\":\"Camera power status: unknown\"}"
        ;;
esac
