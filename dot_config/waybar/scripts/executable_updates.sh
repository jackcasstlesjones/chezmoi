#!/bin/bash
# Waybar: days since the last full system upgrade (pacman -Syu / yay), plus pending updates.
# Cyber Essentials wants critical/high updates applied within 14 days, so:
#   < 7 days ok, 7-13 warning, >= 14 critical.
# Refreshes hourly; `pkill -RTMIN+10 -x waybar` refreshes it now (signal in modules/updates.jsonc).
LOG=/var/log/pacman.log

# "starting full system upgrade" is logged by every -Syu (also when there was nothing to do)
last=$(grep -F "starting full system upgrade" "$LOG" | tail -1 | sed -E 's/^\[([^]]+)\].*/\1/')
if [[ -z "$last" ]]; then
    echo '{"text":" ?","class":"critical","tooltip":"No full system upgrade found in pacman.log"}'
    exit
fi
last_epoch=$(date -d "$last" +%s)
days=$(( ($(date +%s) - last_epoch) / 86400 ))
# checkupdates syncs a temp db (needs network; fails if another run holds its lock).
# Exit 0 = updates listed, 2 = none, anything else = error: then reuse the last good count.
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-updates-count"
list=$(timeout 60 checkupdates 2>/dev/null); status=$?
stale=""
case $status in
    0) pending=$(grep -c . <<<"$list"); echo "$pending" > "$CACHE" ;;
    2) pending=0; echo 0 > "$CACHE" ;;
    *) pending=$(cat "$CACHE" 2>/dev/null || echo 0); stale="?" ;;
esac

class=ok
((days >= 7)) && class=warning
((days >= 14)) && class=critical

text="${days}d"
((pending > 0)) && text+=" · $pending$stale"
when=$(date -d "$last" '+%a %d %b %H:%M')
ago=$([[ $days == 1 ]] && echo "1 day" || echo "$days days")
tooltip="Last full upgrade: $when ($ago ago)\\n$pending updates pending${stale:+ (last check failed, showing previous count)}\\nCyber Essentials: apply within 14 days"
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tooltip"
