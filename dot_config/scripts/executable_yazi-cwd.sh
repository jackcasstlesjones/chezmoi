#!/usr/bin/env bash
# Open yazi (floating) in the working directory of the focused kitty window.
# Uses kitty remote control (listen_on in kitty.conf) to find the exact
# window, since one kitty process can host several windows and tabs.
# Falls back to the shell's /proc cwd for kitty instances started before
# the socket existed, and to $HOME for anything else.

dir="$HOME"
read -r class pid < <(hyprctl activewindow -j | jq -r '"\(.class) \(.pid)"')

if [[ "$class" == "kitty" ]]; then
    sock="${XDG_RUNTIME_DIR}/kitty-${pid}.sock"
    if [[ -S "$sock" ]]; then
        cwd=$(kitty @ --to "unix:$sock" ls 2>/dev/null | jq -r '
            first(.[] | select(.is_focused)
                  | .tabs[]    | select(.is_active)
                  | .windows[] | select(.is_active)
                  | .cwd) // empty')
    else
        # No socket: only trust /proc when kitty has a single shell child.
        children=($(ps -o pid=,comm= --ppid "$pid" | awk '$2 != "kitten" {print $1}'))
        if (( ${#children[@]} == 1 )); then
            cwd=$(readlink "/proc/${children[0]}/cwd")
        fi
    fi
    [[ -n "$cwd" && -d "$cwd" ]] && dir="$cwd"
fi

exec kitty --class yazi-float -d "$dir" -e yazi "$dir"
