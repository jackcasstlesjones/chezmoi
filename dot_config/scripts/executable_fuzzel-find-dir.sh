#!/usr/bin/env bash
set -euo pipefail

HIST="${XDG_CACHE_HOME:-$HOME/.cache}/fuzzel-find-dir/history"
mkdir -p "$(dirname "$HIST")"
touch "$HIST"

cd "$HOME"

all=$(fd --type d --max-depth 5 --no-ignore-vcs \
	--exclude node_modules \
	--exclude target \
	--exclude __pycache__ \
	.)

recent=$(grep -Fxf <(printf '%s\n' "$all") "$HIST" || true)

selected=$(printf '%s\n%s\n' "$recent" "$all" \
	| awk 'NF && !seen[$0]++' \
	| fuzzel --dmenu)

[ -z "$selected" ] && exit 0

{ printf '%s\n' "$selected"; cat "$HIST"; } \
	| awk 'NF && !seen[$0]++' \
	| head -n 200 > "$HIST.tmp"
mv "$HIST.tmp" "$HIST"

thunar "$HOME/$selected" &
