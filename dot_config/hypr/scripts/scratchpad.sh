#!/bin/bash

# Check if scratchpad window is open by looking for kitty process with nvim scratchpad
if pgrep -f "kitty.*nvim.*scratchpad.md" > /dev/null; then
    # Close the scratchpad window
    pkill -f "kitty.*nvim.*scratchpad.md"
else
    # Open the scratchpad
    hyprctl dispatch exec "[float; size 800 600; center] kitty -e nvim ~/obsidian/jacks-vault/scratchpad.md"
fi