#!/bin/bash
# Log battery level every run (battery-log.timer, every 5 min).
# Line format: "YYYY-MM-DD HH:MM:SS <status> <capacity>%[ <rate>%/hr (<hours>hr to empty)]"
# Read by `bat` (zsh alias) and graphed on the Battery page of hypr-settings.
BAT=/sys/class/power_supply/BAT0
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/battery/battery.log"
KEEP=2100 # ~7 days at 5-minute intervals

mkdir -p "$(dirname "$LOG")"
if [ "$(wc -l < "$LOG" 2>/dev/null)" -ge $((KEEP + 100)) ]; then
    tail -n "$KEEP" "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

NOW=$(date '+%Y-%m-%d %H:%M:%S')
STATUS=$(cat $BAT/status)
CAPACITY=$(cat $BAT/capacity)

RATE=""
if [ "$STATUS" = "Discharging" ]; then
    NOW_EPOCH=$(date -d "$NOW" +%s)
    TARGET_EPOCH=$(( NOW_EPOCH - 3600 ))
    # Discharging entry closest to 1 hour ago, within a 30–90 min window.
    # Only the last 30 lines (~2.5h) can qualify, so don't scan the whole log.
    BEST=$(tail -n 30 "$LOG" 2>/dev/null | grep "Discharging" | awk -v target="$TARGET_EPOCH" -v now="$NOW_EPOCH" '
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
