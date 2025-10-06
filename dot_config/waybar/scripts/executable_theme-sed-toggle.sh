#!/bin/bash

# Wallpaper array
WALLPAPERS=("city2.png" "fallout.jpg" "anime.png" "hollow-sat.jpg" "hollow-yellow.png" "herakles.png" "frosted-dark.png" "nord-mountain.png" "hollowknight-cartoon.jpg")

# Config files
STYLE_FILE="$HOME/.config/waybar/style.css"
STATE_FILE="$HOME/.config/waybar/.theme-state"
HYPRPAPER_FILE="$HOME/.config/hypr/hyprpaper.conf"

# Use fuzzel to select wallpaper
SELECTED=$(printf '%s\n' "${WALLPAPERS[@]}" | fuzzel --dmenu --hide-prompt)

# Exit if no selection
[[ -z "$SELECTED" ]] && exit 0

# Find index of selected wallpaper
NEXT_INDEX=0
for i in "${!WALLPAPERS[@]}"; do
    if [[ "${WALLPAPERS[$i]}" == "$SELECTED" ]]; then
        NEXT_INDEX=$i
        break
    fi
done

# Apply waybar theme (use pywal-generated colors)
sed -i "s|@import url(\"./.*\\.css\");|@import url(\"$HOME/.cache/wal/colors-waybar.css\");|g" "$STYLE_FILE"

# Update hyprpaper config
sed -i "s|~/.config/wallpapers/.*|~/.config/wallpapers/${WALLPAPERS[$NEXT_INDEX]}|g" "$HYPRPAPER_FILE"

# Use pywal for terminal colors (skip wallpaper since hyprpaper handles it)
# Use specific themes for certain wallpapers
if [[ "${WALLPAPERS[$NEXT_INDEX]}" == frosted-dark* ]] || [[ "${WALLPAPERS[$NEXT_INDEX]}" == city2* ]]; then
    wal --theme nordfox -n -q
elif [[ "${WALLPAPERS[$NEXT_INDEX]}" == hollow-sat* ]]; then
    wal --theme sexy-sweetlove -n -q
else
    wal -i "$HOME/.config/wallpapers/${WALLPAPERS[$NEXT_INDEX]}" -n -q
fi

# Save new index
echo "$NEXT_INDEX" > "$STATE_FILE"

# Reload
pkill -SIGUSR2 waybar
pkill hyprpaper && hyprpaper &
