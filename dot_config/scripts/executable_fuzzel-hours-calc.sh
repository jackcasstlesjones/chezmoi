#!/usr/bin/env bash

# Takes a number or expression from fuzzel, divides by 7.5, then multiplies by 300
# Formula: (input / 7.5) * 300 = input * 40
# Supports expressions like: 8 + 8 + 20

# Get input from fuzzel
INPUT=$(fuzzel --dmenu --prompt "Hours: ")

# Exit if cancelled or empty
[ $? -ne 0 ] || [ -z "$INPUT" ] && exit 0

# Evaluate the expression first (if it contains operators)
HOURS=$(echo "scale=2; $INPUT" | bc)

# Calculate: (hours / 7.5) * 300
DAYS=$(echo "scale=2; $HOURS / 7.5" | bc)
RESULT=$(echo "scale=2; ($DAYS * 300)" | bc)

# Format output based on whether it's an expression or single value
if [[ "$INPUT" =~ [+\-*/] ]]; then
    OUTPUT="$INPUT = $HOURS hours = $DAYS days = £$RESULT"
else
    OUTPUT="$HOURS hours = $DAYS days = £$RESULT"
fi

# Show result in fuzzel
echo "$OUTPUT" | fuzzel --dmenu --width=50 --prompt "Result: "

# Copy result to clipboard
echo "$RESULT" | wl-copy

# Show notification
notify-send "Hours Calculator" "$OUTPUT (copied to clipboard)"
