#!/bin/bash
# Lock the screen with hyprlock. Every lock route uses this (hypridle, Super+Shift+L,
# the desktop menu, hypr-settings).
#
# The lock image and its own pywal palette are prepared *ahead* of time, so locking is
# instant (it also runs right before suspend). With shuffle on, the next random image
# is prepared after you unlock.
#   lock.sh               lock now
#   lock.sh prepare FILE  use FILE (a name in the wallpaper dir) for the next lock
#   lock.sh prepare       pick a random image for the next lock
set -u

WALLPAPER_DIR="$HOME/.config/wallpapers"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
LINK="$STATE/lock-wallpaper"     # hyprlock.conf: background path
COLORS="$STATE/lock-colors.conf" # hyprlock.conf: source
SHUFFLE="$STATE/lock-shuffle"    # exists = new random image after every unlock
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/lock-wal"
THEMES="$HOME/.config/wal/wallpaper-themes"

# Print the path of FILE's hyprlock palette, generating it on first use.
palette() {
    local name=$1 out="$CACHE/$1.conf" tmp theme
    if [[ ! -s "$out" ]]; then
        tmp=$(mktemp -d)
        theme=$(awk -v w="$name" '$1 == w {print $2}' "$THEMES" 2>/dev/null)
        # A separate pywal cache (PYWAL_CACHE_DIR; pywal ignores XDG_CACHE_HOME) = a palette
        # for the lock screen only, leaving ~/.cache/wal (the desktop's) alone.
        # -n -s -t -e: don't set the wallpaper, terminal or tty colours, or reload anything.
        if [[ -n "$theme" ]]; then
            PYWAL_CACHE_DIR="$tmp" wal --theme "$theme" -n -s -t -e -q 2>/dev/null
        else
            PYWAL_CACHE_DIR="$tmp" wal -i "$WALLPAPER_DIR/$name" -n -s -t -e -q 2>/dev/null
        fi
        mkdir -p "$CACHE"
        # Lowercase the hex (pywal sometimes emits uppercase)
        sed -E 's/rgba\(([0-9A-Fa-f]+)\)/rgba(\L\1)/' "$tmp/colors-hyprlock.conf" > "$out"
        rm -rf "$tmp"
    fi
    [[ -s "$out" ]] && echo "$out"
}

prepare() {
    local name=${1:-} current pal
    if [[ -z "$name" ]]; then
        current=$(basename "$(readlink "$LINK" 2>/dev/null)")
        name=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -printf '%f\n' |
            grep -vxF "$current" | shuf -n1)
    fi
    name=$(basename "$name")
    pal=$(palette "$name") || return 1
    mkdir -p "$STATE"
    ln -sfn "$WALLPAPER_DIR/$name" "$LINK"
    ln -sfn "$pal" "$COLORS"
}

if [[ "${1:-}" == prepare ]]; then
    prepare "${2:-}"
    exit
fi

pidof hyprlock >/dev/null && exit 0
# First run: make sure hyprlock has an image and colours (otherwise it's prepared already)
[[ -e "$LINK" && -e "$COLORS" ]] || prepare
hyprlock
[[ -e "$SHUFFLE" ]] && prepare
