#!/bin/bash
# Waybar widget for hypridle's lock and suspend timeouts.
#   no args: print status JSON
#   menu:    pick a timeout with fuzzel, save it and restart hypridle

CONF="$HOME/.config/hypr/hypridle.conf"
LOCK_CMD="loginctl lock-session"
SUSPEND_CMD="systemctl suspend"
WAYBAR_SIGNAL=9 # matches "signal" in modules/hypridle.jsonc

# Line number of the `timeout` belonging to the listener running $1
timeout_line() {
    awk -v cmd="on-timeout = $1" '
        $1 == "timeout" { line = NR }
        index($0, cmd)  { print line; exit }
    ' "$CONF"
}

get_timeout() {
    sed -n "$(timeout_line "$1")s/.*= *//p" "$CONF"
}

set_timeout() {
    sed -i "$(timeout_line "$1")s/=.*/= $2/" "$CONF"
}

format_duration() {
    if (($1 % 60 == 0)); then echo "$(($1 / 60))m"; else echo "$1s"; fi
}

status() {
    local lock suspend
    lock=$(format_duration "$(get_timeout "$LOCK_CMD")")
    suspend=$(format_duration "$(get_timeout "$SUSPEND_CMD")")
    jq -cn --arg text "$lock/$suspend" --arg tooltip "Lock after $lock, suspend after $suspend" \
        '{text: $text, tooltip: $tooltip}'
}

menu() {
    local choice cmd label minutes
    choice=$(printf '%s\n' \
        "Lock: $(format_duration "$(get_timeout "$LOCK_CMD")")" \
        "Suspend: $(format_duration "$(get_timeout "$SUSPEND_CMD")")" |
        fuzzel --dmenu --hide-prompt --only-match --lines 2)

    case "$choice" in
        Lock:*) cmd=$LOCK_CMD label="Lock" ;;
        Suspend:*) cmd=$SUSPEND_CMD label="Suspend" ;;
        *) exit 0 ;;
    esac

    # Pick a preset or type any whole number of minutes
    minutes=$(printf '%s\n' 1 2 3 5 8 10 15 20 30 45 60 120 |
        fuzzel --dmenu --prompt "$label after (minutes): " --lines 12)
    [[ -z "$minutes" ]] && exit 0
    if ! [[ "$minutes" =~ ^[1-9][0-9]*$ ]]; then
        notify-send "Hypridle" "Not a number of minutes: $minutes" -t 3000
        exit 1
    fi

    set_timeout "$cmd" "$((minutes * 60))"

    # hypridle only reads its config at startup
    pkill -x hypridle
    setsid -f hypridle >/dev/null 2>&1

    pkill -RTMIN+"$WAYBAR_SIGNAL" -x waybar
    notify-send "Hypridle" "$label after $minutes min" -t 2000
}

case "$1" in
    menu) menu ;;
    *) status ;;
esac
