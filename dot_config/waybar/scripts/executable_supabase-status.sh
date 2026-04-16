#!/bin/bash
# Display Supabase local dev status for waybar

RUNNING=$(docker ps --filter "name=supabase_" --format "{{.Names}}" 2>/dev/null | head -1)

if [ -n "$RUNNING" ]; then
    echo "{\"text\":\"on\",\"class\":\"running\",\"tooltip\":\"Supabase: running\"}"
else
    echo "{\"text\":\"off\",\"class\":\"stopped\",\"tooltip\":\"Supabase: stopped\"}"
fi
