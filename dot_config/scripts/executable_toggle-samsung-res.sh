#!/bin/bash

# Get current resolution of Samsung monitor
current_res=$(hyprctl monitors -j | jq -r '.[] | select(.description | contains("Samsung Electric Company U32J59x")) | "\(.width)x\(.height)"')

if [ "$current_res" = "3840x2160" ]; then
    # Switch to 1080p
    hyprctl keyword monitor "desc:Samsung Electric Company U32J59x HNMN600224,1920x1080@60,0x0,1"
    notify-send "Monitor Resolution" "Switched to 1920x1080" -t 2000
else
    # Switch to 4K with scaling
    hyprctl keyword monitor "desc:Samsung Electric Company U32J59x HNMN600224,3840x2160@60,0x0,1.33"
    notify-send "Monitor Resolution" "Switched to 3840x2160 (1.33x scale)" -t 2000
fi
