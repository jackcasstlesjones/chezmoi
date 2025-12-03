#!/usr/bin/env bash

# Detect connected monitors
outputs=$(hyprctl -j monitors | jq -r '.[].name')

if echo "$outputs" | grep -q "DP-9"; then
    # Docked: external 4K + laptop
    hyprctl keyword monitor "DP-9,3840x2160@60,0x0,1.33"
    hyprctl keyword monitor "eDP-1,1920x1200@60,2887x0,1.0"
else
    # Laptop only
    hyprctl keyword monitor "eDP-1,1920x1200@60,0x0,1.0"
fi
