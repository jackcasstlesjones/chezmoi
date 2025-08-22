#!/bin/bash

# Theme arrays
THEMES=("nord-theme.css" "orange-theme.css" "pink-theme.css" "nord-theme.css" "nord-theme.css")
WALLPAPERS=("city2.png" "fallout.jpg" "anime.png" "hollow-sat.jpg" "hollow-yellow.png")  
KITTY_THEMES=("nord-theme.conf" "orange-theme.conf" "pink-theme.conf" "nord-theme.conf" "nord-theme.conf")

# Config files
STYLE_FILE="$HOME/.config/waybar/style.css"
STATE_FILE="$HOME/.config/waybar/.theme-state"
HYPRPAPER_FILE="$HOME/.config/hypr/hyprpaper.conf"
KITTY_CONFIG="$HOME/.config/kitty/kitty.conf"

# Get current index
CURRENT_INDEX=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
NEXT_INDEX=$(((CURRENT_INDEX + 1) % ${#THEMES[@]}))

# Apply theme
sed -i "s|@import url(\"./.*-theme.css\");|@import url(\"./${THEMES[$NEXT_INDEX]}\");|g" "$STYLE_FILE"
sed -i "s|~/.config/wallpapers/.*|~/.config/wallpapers/${WALLPAPERS[$NEXT_INDEX]}|g" "$HYPRPAPER_FILE"
sed -i "s|include ./.*-theme.conf|include ./${KITTY_THEMES[$NEXT_INDEX]}|g" "$KITTY_CONFIG"

# Save new index
echo "$NEXT_INDEX" > "$STATE_FILE"

# Reload
pkill -SIGUSR2 waybar
pkill hyprpaper && hyprpaper &
kitty @ load-config
