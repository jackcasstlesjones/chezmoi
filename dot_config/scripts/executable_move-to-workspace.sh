#!/bin/bash
# Move active window to a workspace (existing or new)

# Get existing workspaces and add option to create new one
workspaces=$(hyprctl workspaces -j | jq -r '.[].name' | sort)
echo -e "NEW\n$workspaces" | fuzzel --dmenu --prompt "Move to: " | while read workspace; do
    if [ "$workspace" = "NEW" ]; then
        # Prompt for new workspace name
        new_name=$(echo "" | fuzzel --dmenu --prompt "New workspace name: ")
        [ -n "$new_name" ] && hyprctl dispatch "hl.dsp.window.move({ workspace = \"name:$new_name\", follow = true })"
    elif [ -n "$workspace" ]; then
        hyprctl dispatch "hl.dsp.window.move({ workspace = \"name:$workspace\", follow = true })"
    fi
done
