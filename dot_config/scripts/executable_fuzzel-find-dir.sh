#!/usr/bin/env bash
set -euo pipefail

# fuzzel ranks entries you pick often higher using this cache
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fuzzel-find-dir/cache"
mkdir -p "$(dirname "$CACHE")"

cd "$HOME"

all=$(fd --type d --type f --max-depth 5 \
	--exclude node_modules \
	--exclude target \
	--exclude __pycache__ \
	--exclude /miniconda3 \
	--exclude /go \
	--exclude /nltk_data \
	--exclude '/Calibre Library' \
	.)

# Ctrl+Enter makes fuzzel exit with 10; any other failure means cancelled
status=0
selected=$(fuzzel --dmenu --width=140 --match-mode=exact --cache="$CACHE" \
	--override=key-bindings.custom-1=Control+Return <<<"$all") || status=$?

[ "$status" -eq 0 ] || [ "$status" -eq 10 ] || exit 0
[ -z "$selected" ] && exit 0

path="$HOME/$selected"

# Folders go to Thunar directly: xdg-open sends them to kitty on this machine
if [ -d "$path" ]; then
	thunar "$path" &
elif [ "$status" -eq 10 ]; then
	thunar "$(dirname "$path")" &
else
	xdg-open "$path" &
fi
