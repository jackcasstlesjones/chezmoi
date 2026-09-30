#!/usr/bin/env bash

# Pick a resolution for the KTC H32D6 (DP-8) via fuzzel.
# The panel's EDID has no 1920x1080@100 mode; 1080p tops out at 75Hz.
# eDP-1 is re-positioned to sit centred below the external in each mode.

KTC="desc:Shenzhen KTC Technology Group H32D6"

choice=$(printf '%s\n' "2K (2560x1440) @ 100Hz" "1080p (1920x1080) @ 75Hz" \
    | fuzzel --dmenu --prompt "Resolution: " --lines 2)

case "$choice" in
    2K*)
        hyprctl eval "hl.monitor({ output=\"$KTC\", mode=\"2560x1440@99.97\", position=\"0x0\", scale=1 })"
        hyprctl eval 'hl.monitor({ output="eDP-1", mode="preferred", position="320x1440", scale=1 })'
        notify-send "Monitor Resolution" "2560x1440 @ 100Hz" -t 2000
        ;;
    1080p*)
        hyprctl eval "hl.monitor({ output=\"$KTC\", mode=\"1920x1080@75\", position=\"0x0\", scale=1 })"
        hyprctl eval 'hl.monitor({ output="eDP-1", mode="preferred", position="0x1080", scale=1 })'
        notify-send "Monitor Resolution" "1920x1080 @ 75Hz" -t 2000
        ;;
    *)
        exit 0
        ;;
esac
