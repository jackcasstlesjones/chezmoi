#!/usr/bin/env bash
# Copy the most recently downloaded file to the clipboard as a file (text/uri-list),
# so it can be pasted into a file manager, browser upload, chat app, etc.

set -eu

dir="$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads")"

# Newest regular file, skipping in-progress downloads and hidden files
latest="$(find "$dir" -maxdepth 1 -type f ! -name '.*' \
    ! -name '*.crdownload' ! -name '*.part' ! -name '*.download' \
    -printf '%T@\t%p\n' | sort -rn | head -n1 | cut -f2-)"

if [[ -z "$latest" ]]; then
    notify-send "Copy latest download" "No files in $dir"
    exit 1
fi

uri="file://$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$latest")"
printf '%s\r\n' "$uri" | wl-copy --type text/uri-list

notify-send "Copied to clipboard" "$(basename "$latest")"
