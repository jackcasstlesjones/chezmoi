#!/bin/bash

# Wallpaper array
WALLPAPERS=("city2.png" "fallout.jpg" "anime.png" "hollow-sat.jpg" "hollow-yellow.png")

# Config files
STYLE_FILE="$HOME/.config/waybar/style.css"
STATE_FILE="$HOME/.config/waybar/.theme-state"
HYPRPAPER_FILE="$HOME/.config/hypr/hyprpaper.conf"

# Get current index
CURRENT_INDEX=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
NEXT_INDEX=$(((CURRENT_INDEX + 1) % ${#WALLPAPERS[@]}))

# Apply waybar theme (use pywal-generated colors)
sed -i "s|@import url(\"./.*\\.css\");|@import url(\"$HOME/.cache/wal/colors-waybar.css\");|g" "$STYLE_FILE"

# Update hyprpaper config
sed -i "s|~/.config/wallpapers/.*|~/.config/wallpapers/${WALLPAPERS[$NEXT_INDEX]}|g" "$HYPRPAPER_FILE"

# Use pywal for terminal colors (skip wallpaper since hyprpaper handles it)
wal -i "$HOME/.config/wallpapers/${WALLPAPERS[$NEXT_INDEX]}" -n -q

# Save new index
echo "$NEXT_INDEX" > "$STATE_FILE"

# Reload
pkill -SIGUSR2 waybar
pkill hyprpaper && hyprpaper &
