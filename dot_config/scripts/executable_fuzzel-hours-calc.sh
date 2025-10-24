#!/usr/bin/env bash

# Takes a number from fuzzel, divides by 7.5, then multiplies by 300
# Formula: (input / 7.5) * 300 = input * 40

# Get input from fuzzel
INPUT=$(fuzzel --dmenu --prompt "Hours: ")

# Exit if cancelled or empty
[ $? -ne 0 ] || [ -z "$INPUT" ] && exit 0

# Calculate: (input / 7.5) * 300
DAYS=$(echo "scale=2; $INPUT / 7.5" | bc)
RESULT=$(echo "scale=2; $DAYS * 300" | bc)

# Show result in fuzzel
echo "$INPUT hours = $DAYS days = £$RESULT" | fuzzel --dmenu --prompt "Result: "

# Copy result to clipboard
echo "$RESULT" | wl-copy

# Show notification
notify-send "Hours Calculator" "$INPUT hours = $DAYS days = £$RESULT (copied to clipboard)"
