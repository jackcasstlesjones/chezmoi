#!/bin/bash

# Check if scratchpad window is open by looking for kitty process with nvim scratchpad
if pgrep -f "kitty.*nvim.*scratchpad.md" > /dev/null; then
    # Get the window ID of the scratchpad
    WINDOW_ID=$(hyprctl clients -j | jq -r '.[] | select(.title | contains("scratchpad.md")) | .address')

    if [ -n "$WINDOW_ID" ]; then
        # Focus the window and send save+quit commands
        hyprctl dispatch "hl.dsp.focus({ window = \"address:$WINDOW_ID\" })"
        sleep 0.1
        # Send Escape to ensure we're in normal mode, then :wq and Enter
        hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "", key = "Escape" })'
        sleep 0.05
        xdotool type ":wq"
        sleep 0.05
        hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "", key = "Return" })'
        # Wait a moment for nvim to properly exit
        sleep 0.2
    else
        # Fallback: try to send :wq first, then kill if needed
        xdotool type ":wq" && hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "", key = "Return" })'
        sleep 0.3
        pkill -f "kitty.*nvim.*scratchpad.md"
    fi
else
    # Open the scratchpad
    hyprctl dispatch 'hl.dsp.exec_cmd("kitty -e nvim ~/obsidian/jacks-vault/scratchpad.md", { float = true, size = "800 600", center = true })'
fi
