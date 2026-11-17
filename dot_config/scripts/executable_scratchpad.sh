#!/bin/bash

# Escape, :wq, Return into the focused nvim. send_shortcut rather than
# xdotool/wtype: it ignores the hyper modifiers still held from the bind.
send_wq() {
    for k in '"", key = "Escape"' '"SHIFT", key = "semicolon"' '"", key = "w"' '"", key = "q"' '"", key = "Return"'; do
        hyprctl dispatch "hl.dsp.send_shortcut({ mods = $k })" >/dev/null
        sleep 0.03
    done
}

# Check if scratchpad window is open by looking for kitty process with nvim scratchpad
if pgrep -f "kitty.*nvim.*scratchpad.md" > /dev/null; then
    # Get the window ID of the scratchpad
    WINDOW_ID=$(hyprctl clients -j | jq -r '.[] | select(.title | contains("scratchpad.md")) | .address')

    if [ -n "$WINDOW_ID" ]; then
        # Focus the window and send save+quit commands
        hyprctl dispatch "hl.dsp.focus({ window = \"address:$WINDOW_ID\" })"
        sleep 0.1
        # Send Escape to ensure we're in normal mode, then :wq and Enter
        send_wq
        # Wait a moment for nvim to properly exit
        sleep 0.2
    else
        # Fallback: try to send :wq first, then kill if needed
        send_wq
        sleep 0.3
        pkill -f "kitty.*nvim.*scratchpad.md"
    fi
else
    # Open the scratchpad
    hyprctl dispatch 'hl.dsp.exec_cmd("kitty -e nvim ~/obsidian/jacks-vault/scratchpad.md", { float = true, size = "800 600", center = true })'
fi
