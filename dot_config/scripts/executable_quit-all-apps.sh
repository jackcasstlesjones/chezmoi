#!/usr/bin/env bash

# List of apps to quit
apps=("chrome" "firefox" "spotify" "Discord" "thunderbird" "kitty" "steam")

for app in "${apps[@]}"; do
    # Try polite quit
    pkill -15 "$app" 2>/dev/null
    sleep 0.2

    # If still running, force kill
    if pgrep -x "$app" >/dev/null; then
        pkill -9 "$app" 2>/dev/null
    fi
done
