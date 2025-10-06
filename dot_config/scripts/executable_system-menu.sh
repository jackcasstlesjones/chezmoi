#!/usr/bin/env bash

# System menu using fuzzel dmenu mode
# Icons using nerd font symbols

OPTIONS="🔒 Lock
🚪 Logout
💤 Suspend
🔄 Reboot
⏻ Shutdown
🌙 Night Light
🎧 Audio
📶 Bluetooth
🖥️  Display"

CHOICE=$(echo "$OPTIONS" | fuzzel --dmenu --hide-prompt --lines 9)

case "$CHOICE" in
    "🔒 Lock")
        hyprlock
        ;;
    "🚪 Logout")
        hyprctl dispatch exit
        ;;
    "💤 Suspend")
        systemctl suspend
        ;;
    "🔄 Reboot")
        systemctl reboot
        ;;
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "🌙 Night Light")
        pkill hyprsunset || hyprsunset -t 2000
        ;;
    "🎧 Audio")
        kitty -e pulsemixer
        ;;
    "📶 Bluetooth")
        kitty --class bluetui -e bluetui
        ;;
    "🖥️  Display")
        kitty -e wdisplays
        ;;
esac
