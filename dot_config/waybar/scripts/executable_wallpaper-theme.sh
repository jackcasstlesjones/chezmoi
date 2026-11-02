#!/bin/bash
# Pick a wallpaper with fuzzel, set it in hyprpaper, and recolour everything with pywal.

WALLPAPER_DIR="$HOME/.config/wallpapers"
HYPRPAPER_FILE="$HOME/.config/hypr/hyprpaper.conf"

# wallpaper                  pywal theme ("-" = generate colours from the image)
THEMES="
city2.png                    nordfox
fallout.jpg                  -
anime.png                    -
hollow-sat.jpg               sexy-sweetlove
hollow-yellow.png            -
herakles.png                 -
frosted-dark.png             nordfox
nord-mountain.png            -
hollowknight-cartoon.jpg     -
swirl.jpg                    ashes
flower-dark.jpg              tempus_dusk
"

SELECTED=$(awk 'NF {print $1}' <<<"$THEMES" | fuzzel --dmenu --hide-prompt)
[[ -z "$SELECTED" ]] && exit 0

THEME=$(awk -v w="$SELECTED" '$1 == w {print $2}' <<<"$THEMES")
WALLPAPER_PATH="$WALLPAPER_DIR/$SELECTED"

# Persist the choice for the next hyprpaper start
sed -i "s|~/.config/wallpapers/.*|~/.config/wallpapers/$SELECTED|g" "$HYPRPAPER_FILE"

# -n: hyprpaper handles the wallpaper, pywal only does colours
if [[ "$THEME" == "-" ]]; then
    wal -i "$WALLPAPER_PATH" -n -q
else
    wal --theme "$THEME" -n -q
fi

hyprctl hyprpaper preload "$WALLPAPER_PATH"
hyprctl hyprpaper wallpaper ",$WALLPAPER_PATH"
pkill -SIGUSR2 waybar
