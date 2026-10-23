#!/bin/bash
# Display Claude plan usage (5h session + 7d weekly limits) for waybar

CREDS="$HOME/.claude/.credentials.json"
TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS" 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo '{"text":"--","class":"error","tooltip":"Claude: not logged in"}'
    exit 0
fi

RESP=$(curl -sf -m 10 https://api.anthropic.com/api/oauth/usage \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20")

if [ -z "$RESP" ]; then
    echo '{"text":"?","class":"error","tooltip":"Claude: usage request failed (token may need refreshing - run claude)"}'
    exit 0
fi

echo "$RESP" | jq -c '
    def pct: (.utilization // 0 | floor);
    def resets: (.resets_at // "" | .[0:19] + "Z" | fromdateiso8601? // null
        | if . then strflocaltime("%a %H:%M") else "?" end);
    (.five_hour | pct) as $s | (.seven_day | pct) as $w |
    ([$s, $w] | max) as $m |
    {
        text: "\($s)% · \($w)%",
        class: (if $m >= 90 then "critical" elif $m >= 70 then "warning" else "normal" end),
        percentage: $m,
        tooltip: "Claude usage\nSession (5h): \($s)% - resets \(.five_hour | resets)\nWeekly (7d): \($w)% - resets \(.seven_day | resets)"
    }'
