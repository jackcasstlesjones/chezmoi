#!/bin/bash
# Orange Theme Toggle using sed to replace CSS import
#
# HOW IT WORKS:
# 1. style.css contains: @import url('./orange-current-theme.css');
# 2. This script uses sed to replace that import line with either:
#    - @import url('./orange-nord-theme.css'); (default Nord)
#    - @import url('./orange-orange-theme.css'); (orange theme)
# 3. After replacing, signals waybar to reload CSS
#
# STATE TRACKING:
# - Uses ~/.config/waybar/.theme-state as state file
# - File contains: theme=nord or theme=orange (extensible for more themes)
# - Default is nord if file doesn't exist
WAYBAR_DIR="$HOME/.config/waybar"
STYLE_FILE="$WAYBAR_DIR/style.css"
STATE_FILE="$WAYBAR_DIR/.theme-state"
HYPRPAPER_FILE="$HOME/.config/hypr/hyprpaper.conf"
KITTY_CONFIG="$HOME/.config/kitty/kitty.conf"

# Read current theme from state file
if [[ -f "$STATE_FILE" ]]; then
    CURRENT_THEME=$(grep "^theme=" "$STATE_FILE" | cut -d'=' -f2)
else
    CURRENT_THEME="nord"
fi

# Cycle through themes: nord → orange → scooz → nord
if [[ "$CURRENT_THEME" == "nord" ]]; then
    # Currently nord, switch to orange
    sed -i 's|@import url("./nord-theme.css");|@import url("./orange-theme.css");|g' "$STYLE_FILE"
    sed -i 's|~/.config/wallpapers/.*|~/.config/wallpapers/fallout.jpg|g' "$HYPRPAPER_FILE"
    sed -i 's|include ./nord-theme.conf|include ./orange-theme.conf|g' "$KITTY_CONFIG"
    echo "theme=orange" > "$STATE_FILE"
elif [[ "$CURRENT_THEME" == "orange" ]]; then
    # Currently orange, switch to scooz
    sed -i 's|@import url("./orange-theme.css");|@import url("./pink-theme.css");|g' "$STYLE_FILE"
    sed -i 's|~/.config/wallpapers/.*|~/.config/wallpapers/anime.png|g' "$HYPRPAPER_FILE"
    sed -i 's|include ./orange-theme.conf|include ./pink-theme.conf|g' "$KITTY_CONFIG"
    echo "theme=scooz" > "$STATE_FILE"
elif [[ "$CURRENT_THEME" == "scooz" ]]; then
    # Currently orange, switch to scooz
    sed -i 's|@import url("./pink-theme.css");|@import url("./nord-theme.css");|g' "$STYLE_FILE"
    sed -i 's|~/.config/wallpapers/.*|~/.config/wallpapers/hollow-sat.jpg|g' "$HYPRPAPER_FILE"
    sed -i 's|include ./pink-theme.conf|include ./nord-theme.conf|g' "$KITTY_CONFIG"
    echo "theme=hollow" > "$STATE_FILE"
else
    # Currently scooz (or unknown), switch to nord
    sed -i 's|~/.config/wallpapers/.*|~/.config/wallpapers/city2.png|g' "$HYPRPAPER_FILE"
    echo "theme=nord" > "$STATE_FILE"
fi

# Reload waybar CSS, hyprpaper, and kitty
pkill -SIGUSR2 waybar
pkill hyprpaper && hyprpaper &
kitty @ load-config
