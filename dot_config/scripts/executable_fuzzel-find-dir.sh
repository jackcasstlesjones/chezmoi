#!/usr/bin/env bash
set -euo pipefail

cd "$HOME"

selected=$(fd --type d --max-depth 5 \
	--exclude node_modules \
	--exclude target \
	--exclude __pycache__ \
	. | fuzzel --dmenu --prompt "Find: ")

[ -z "$selected" ] && exit 0

thunar "$HOME/$selected" &
