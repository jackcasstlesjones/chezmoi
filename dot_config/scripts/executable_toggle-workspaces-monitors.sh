#!/bin/bash
# Toggle all workspaces between monitors

# Get list of all monitors
monitors=$(hyprctl monitors -j | jq -r '.[].name')
monitor_array=($monitors)
monitor_count=${#monitor_array[@]}

# Exit if we don't have at least 2 monitors
if [ $monitor_count -lt 2 ]; then
    echo "Need at least 2 monitors to toggle workspaces"
    exit 1
fi

# Get all workspace names
workspaces=$(hyprctl workspaces -j | jq -r '.[].name')

# Count how many workspaces are on the first monitor
first_monitor="${monitor_array[0]}"
ws_on_first=$(hyprctl workspaces -j | jq -r ".[] | select(.monitor == \"$first_monitor\") | .name" | wc -l)
total_ws=$(echo "$workspaces" | wc -w)

# If more than half the workspaces are on the first monitor, move all to second
# Otherwise move all to first
if [ $ws_on_first -gt $((total_ws / 2)) ]; then
    # Move all to second monitor
    target_monitor="${monitor_array[1]}"
else
    # Move all to first monitor
    target_monitor="$first_monitor"
fi

# Move all workspaces to the target monitor
for ws in $workspaces; do
    hyprctl dispatch moveworkspacetomonitor name:$ws $target_monitor
done
