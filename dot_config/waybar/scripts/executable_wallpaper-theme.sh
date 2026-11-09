#!/bin/bash
# Pick a wallpaper with an image preview, set it in hyprpaper, and recolour everything with pywal.
#   no args:      open the picker in a floating kitty window
#   pick:         run the picker in the current terminal
#   preview FILE: draw FILE in fzf's preview pane

WALLPAPER_DIR="$HOME/.config/wallpapers"
HYPRPAPER_FILE="$HOME/.config/hypr/hyprpaper.conf"

case "${1:-}" in
    pick) ;;
    preview)
        # sed: fzf's documented fix so icat's trailing line doesn't scroll the pane
        kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no \
            --place="${FZF_PREVIEW_COLUMNS}x$((FZF_PREVIEW_LINES - 1))@0x0" "$WALLPAPER_DIR/$2" |
            sed '$d' | sed $'$s/$/\e[m/'
        exit
        ;;
    *) exec kitty --class wallpaper-picker "$0" pick ;;
esac

# Wallpapers that use a fixed pywal theme. All others get colours generated from the image.
THEMES="
city2.png                    nordfox
hollow-sat.jpg               sexy-sweetlove
frosted-dark.png             nordfox
swirl.jpg                    ashes
flower-dark.jpg              tempus_dusk
"

SELECTED=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -printf '%f\n' |
    sort |
    fzf --no-info --preview "\"$0\" preview {}" --preview-window=right,75%,border-left)
[[ -z "$SELECTED" ]] && exit 0

THEME=$(awk -v w="$SELECTED" '$1 == w {print $2}' <<<"$THEMES")
WALLPAPER_PATH="$WALLPAPER_DIR/$SELECTED"

# Persist the choice for the next hyprpaper start
sed -i "s|~/.config/wallpapers/.*|~/.config/wallpapers/$SELECTED|g" "$HYPRPAPER_FILE"

# -n: hyprpaper handles the wallpaper, pywal only does colours
if [[ -n "$THEME" ]]; then
    wal --theme "$THEME" -n -q
else
    wal -i "$WALLPAPER_PATH" -n -q
fi

hyprctl hyprpaper preload "$WALLPAPER_PATH"
hyprctl hyprpaper wallpaper ",$WALLPAPER_PATH"
pkill -SIGUSR2 waybar
hyprctl reload  # re-read pywal colours for window borders
makoctl reload  # re-read pywal colours for notifications
