#!/bin/bash
# Move active window to a workspace (existing or new)

# Get existing workspaces and add option to create new one
workspaces=$(hyprctl workspaces -j | jq -r '.[].name' | sort)
echo -e "NEW\n$workspaces" | fuzzel --dmenu --prompt "Move to: " | while read workspace; do
    if [ "$workspace" = "NEW" ]; then
        # Prompt for new workspace name
        new_name=$(echo "" | fuzzel --dmenu --prompt "New workspace name: ")
        [ -n "$new_name" ] && hyprctl dispatch movetoworkspace name:"$new_name"
    elif [ -n "$workspace" ]; then
        hyprctl dispatch movetoworkspace name:"$workspace"
    fi
done
