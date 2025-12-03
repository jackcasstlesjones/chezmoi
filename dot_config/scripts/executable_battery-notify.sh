#!/bin/bash
STATE_FILE="/tmp/battery-notified-level"

# Get current battery percentage
BATTERY_LEVEL=$(cat /sys/class/power_supply/BAT0/capacity)
BATTERY_STATUS=$(cat /sys/class/power_supply/BAT0/status)

# Only notify if discharging
if [ "$BATTERY_STATUS" != "Discharging" ]; then
    rm -f "$STATE_FILE"
    exit 0
fi

# Check if we're in the 1-10% range
if [ "$BATTERY_LEVEL" -ge 1 ] && [ "$BATTERY_LEVEL" -le 10 ]; then
    # Read last notified level
    LAST_NOTIFIED=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

    # Only notify if this level hasn't been notified yet
    if [ "$BATTERY_LEVEL" != "$LAST_NOTIFIED" ]; then
        notify-send -u critical -a "Battery Warning" "Battery at ${BATTERY_LEVEL}%" \
            "Your battery is at ${BATTERY_LEVEL}%"
        echo "$BATTERY_LEVEL" > "$STATE_FILE"
    fi
else
    # Clear state file when outside the range
    rm -f "$STATE_FILE"
fi
