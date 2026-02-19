#!/bin/bash

CLAUDE_DIR="/home/jack/.claude"
SETTINGS_JSON="$CLAUDE_DIR/settings.json"
ACTIVE_FILE="$CLAUDE_DIR/.active"

current=$(cat "$ACTIVE_FILE" 2>/dev/null || echo "claude")

if [ "$current" = "claude" ]; then
    cp "$CLAUDE_DIR/settings.glm.json" "$SETTINGS_JSON"
    echo "glm" > "$ACTIVE_FILE"
    echo "Switched to GLM"
else
    cp "$CLAUDE_DIR/settings.claude.json" "$SETTINGS_JSON"
    echo "claude" > "$ACTIVE_FILE"
    echo "Switched to Claude"
fi
