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

selected=$(fuzzel --dmenu --width=140 --match-mode=exact --cache="$CACHE" <<<"$all")

[ -z "$selected" ] && exit 0

# Folders go to Thunar directly: xdg-open sends them to kitty on this machine
if [ -d "$HOME/$selected" ]; then
	thunar "$HOME/$selected" &
else
	xdg-open "$HOME/$selected" &
fi
