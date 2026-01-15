#!/bin/bash

CLAUDE_DIR="/home/jack/.claude"
SETTINGS_JSON="$CLAUDE_DIR/settings.json"
GLM_JSON="$CLAUDE_DIR/glm.json"

# Check if settings.json is non-empty (has content beyond just whitespace/braces)
if [ -s "$SETTINGS_JSON" ] && [ "$(cat "$SETTINGS_JSON" | wc -l)" -gt 2 ]; then
    # Settings has content - save to glm.json and blank settings.json
    cp "$SETTINGS_JSON" "$GLM_JSON"
    echo "{}" > "$SETTINGS_JSON"
    echo "settings.json blanked (contents saved to glm.json)"
else
    # Settings is blank - restore from glm.json
    if [ -s "$GLM_JSON" ]; then
        cp "$GLM_JSON" "$SETTINGS_JSON"
        echo "settings.json restored from glm.json"
    else
        echo "Error: glm.json is empty, nothing to restore"
        exit 1
    fi
fi
