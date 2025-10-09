#!/usr/bin/env bash

# SSH launcher using fuzzel dmenu mode
# Reads SSH config and launches kitty with kitten ssh

SSH_CONFIG="$HOME/.ssh/config"

# Exit if SSH config doesn't exist
if [ ! -f "$SSH_CONFIG" ]; then
    notify-send "SSH Launcher" "SSH config not found at $SSH_CONFIG"
    exit 1
fi

# Parse SSH config for Host entries (excluding wildcards)
HOSTS=$(grep "^Host " "$SSH_CONFIG" | awk '{print $2}' | grep -v '\*')

# Exit if no hosts found
if [ -z "$HOSTS" ]; then
    notify-send "SSH Launcher" "No hosts found in SSH config"
    exit 1
fi

# Show fuzzel menu with hosts
SELECTED=$(echo "$HOSTS" | fuzzel --dmenu --prompt "ssh > ")

# Exit if cancelled (Escape pressed)
if [ $? -ne 0 ] || [ -z "$SELECTED" ]; then
    exit 0
fi

# Launch kitty with kitten ssh
kitty --detach kitten ssh "$SELECTED"
