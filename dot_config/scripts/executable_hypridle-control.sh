#!/bin/bash
# Read or change hypridle's lock and suspend timeouts (used by hypr-settings).
#   get:                         print "<lock seconds> <suspend seconds>"
#   set lock|suspend <minutes>:  save the timeout and restart hypridle if it's running

CONF="$HOME/.config/hypr/hypridle.conf"
declare -A CMDS=([lock]="loginctl lock-session" [suspend]="systemctl suspend")

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

case "$1" in
    get)
        echo "$(get_timeout "${CMDS[lock]}") $(get_timeout "${CMDS[suspend]}")"
        ;;
    set)
        cmd=${CMDS[$2]}
        if [[ -z "$cmd" || ! "$3" =~ ^[1-9][0-9]*$ ]]; then
            echo "usage: $0 set lock|suspend <minutes>" >&2
            exit 1
        fi
        sed -i "$(timeout_line "$cmd")s/=.*/= $(($3 * 60))/" "$CONF"
        # hypridle only reads its config at startup; leave it off if it was turned off
        if pkill -x hypridle; then
            setsid -f hypridle >/dev/null 2>&1
        fi
        ;;
    *)
        echo "usage: $0 get | set lock|suspend <minutes>" >&2
        exit 1
        ;;
esac
