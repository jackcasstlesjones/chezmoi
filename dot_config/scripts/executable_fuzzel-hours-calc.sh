#!/usr/bin/env bash

# Takes a number from fuzzel, divides by 7.5, then multiplies by 300
# Formula: (input / 7.5) * 300 = input * 40

# Get input from fuzzel
INPUT=$(fuzzel --dmenu --prompt "Hours: ")

# Exit if cancelled or empty
[ $? -ne 0 ] || [ -z "$INPUT" ] && exit 0

# Calculate: (input / 7.5) * 300
RESULT=$(echo "scale=2; ($INPUT / 7.5) * 300" | bc)

# Show result in fuzzel
echo "$INPUT hours = £$RESULT" | fuzzel --dmenu --prompt "Result: "

# Copy result to clipboard
echo "$RESULT" | wl-copy

# Show notification
notify-send "Hours Calculator" "$INPUT hours = $RESULT (copied to clipboard)"
