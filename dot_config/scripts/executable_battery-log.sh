#!/bin/bash
BAT=/sys/class/power_supply/BAT0
LOG="$HOME/battery.log"

if [ "$(wc -l < "$LOG" 2>/dev/null)" -ge 200 ]; then
    tail -n +51 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

NOW=$(date '+%Y-%m-%d %H:%M:%S')
STATUS=$(cat $BAT/status)
CAPACITY=$(cat $BAT/capacity)

RATE=""
if [ "$STATUS" = "Discharging" ]; then
    NOW_EPOCH=$(date -d "$NOW" +%s)
    TARGET_EPOCH=$(( NOW_EPOCH - 3600 ))
    # Find the Discharging entry closest to 1 hour ago
    # Find the Discharging entry closest to 1 hour ago, within a 30–90 min window
    BEST=$(grep "Discharging" "$LOG" 2>/dev/null | awk -v target="$TARGET_EPOCH" -v now="$NOW_EPOCH" '
        {
            cmd = "date -d \""$1" "$2"\" +%s"
            cmd | getline epoch
            close(cmd)
            age = now - epoch
            if (age < 1800 || age > 5400) next
            diff = epoch - target; if (diff < 0) diff = -diff
            if (best_diff == "" || diff < best_diff) { best_diff = diff; best_line = $0; best_epoch = epoch }
        }
        END { if (best_line != "") print best_epoch " " best_line }
    ')
    if [ -n "$BEST" ]; then
        BEST_EPOCH=$(echo "$BEST" | awk '{print $1}')
        BEST_CAP=$(echo "$BEST" | awk '{gsub(/%/,"",$5); print $5}')
        DELTA_SEC=$(( NOW_EPOCH - BEST_EPOCH ))
        if [ "$DELTA_SEC" -gt 0 ]; then
            RATE=$(awk -v dc="$((BEST_CAP - CAPACITY))" -v ds="$DELTA_SEC" \
                'BEGIN { r = (dc / ds) * 3600; tte = 100 / r; printf " %.2f%%/hr (%.1fhr to empty)", r, tte }')
        fi
    fi
fi

echo "$NOW $STATUS ${CAPACITY}%${RATE}" >> "$LOG"
