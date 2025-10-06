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
        TEMP_OPTIONS="❌ Off
🔥 1000K (Extra Warm)
🕯️ 2000K (Warm)
🌅 3000K (Moderate)
🌆 4000K (Mild)
☀️ 6500K (Neutral)"

        TEMP_CHOICE=$(echo "$TEMP_OPTIONS" | fuzzel --dmenu --hide-prompt --lines 6 --prompt "Night Light: ")

        case "$TEMP_CHOICE" in
            "❌ Off")
                pkill hyprsunset
                ;;
            "🔥 1000K (Extra Warm)")
                pkill hyprsunset; hyprsunset -t 1000
                ;;
            "🕯️  2000K (Warm)")
                pkill hyprsunset; hyprsunset -t 2000
                ;;
            "🌅 3000K (Moderate)")
                pkill hyprsunset; hyprsunset -t 3000
                ;;
            "🌆 4000K (Mild)")
                pkill hyprsunset; hyprsunset -t 4000
                ;;
            "☀️  6500K (Neutral)")
                pkill hyprsunset; hyprsunset -t 6500
                ;;
        esac
        ;;
    "🎧 Audio")
        pavucontrol
        ;;
    "📶 Bluetooth")
        kitty --class bluetui -e bluetui
        ;;
    "🖥️  Display")
        kitty -e wdisplays
        ;;
esac
