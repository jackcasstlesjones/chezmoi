#!/bin/bash
# Fuzzel-based workspace switcher for Hyprland

workspace=$(hyprctl workspaces -j | jq -r '.[].name' | sort | fuzzel --dmenu --hide-prompt -I)

if [ -n "$workspace" ]; then
    hyprctl dispatch workspace name:"$workspace"
fi
