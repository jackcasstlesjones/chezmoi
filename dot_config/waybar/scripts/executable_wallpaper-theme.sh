#!/bin/bash
# Pick a wallpaper with an image preview, set it with awww (animated), and recolour everything with pywal.
#   no args:      open the picker in a floating kitty window
#   pick:         run the picker in the current terminal
#   preview FILE: draw FILE in fzf's preview pane
#   apply FILE:   set FILE (name in the wallpaper dir) without the picker

WALLPAPER_DIR="$HOME/.config/wallpapers"

case "${1:-}" in
    pick) ;;
    apply) SELECTED=$(basename "$2") ;;
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

[[ -z "${SELECTED:-}" ]] && SELECTED=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -printf '%f\n' |
    sort |
    fzf --no-info --preview "\"$0\" preview {}" --preview-window=right,75%,border-left)
[[ -z "$SELECTED" ]] && exit 0

THEME=$(awk -v w="$SELECTED" '$1 == w {print $2}' <<<"$THEMES")
WALLPAPER_PATH="$WALLPAPER_DIR/$SELECTED"

# -n: awww handles the wallpaper, pywal only does colours
if [[ -n "$THEME" ]]; then
    wal --theme "$THEME" -n -q
else
    wal -i "$WALLPAPER_PATH" -n -q
fi
~/.config/scripts/wal-qt6ct.py  # Qt apps (qt6ct palette) follow pywal too
command -v pywalfox >/dev/null && pywalfox update  # Firefox (Pywalfox extension), live

# awww remembers the last image per monitor and restores it on daemon start.
# Random pick from the more dramatic transitions (no plain fade/slide), at a random angle.
TRANSITIONS=(wipe wave grow outer any)
awww img "$WALLPAPER_PATH" \
    --transition-type "${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}" \
    --transition-angle $((RANDOM % 360)) \
    --transition-duration 1.2 --transition-fps 60
pkill -SIGUSR2 waybar
hyprctl reload  # re-read pywal colours for window borders
makoctl reload  # re-read pywal colours for notifications
