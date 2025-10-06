#!/usr/bin/env bash

# Calculator using fuzzel dmenu mode with qalc
# Supports: basic math, unit conversion, hex/bin, functions, constants
# Shares history with wofi-calc

# History file (shared with wofi-calc)
HISTORY_FILE="$HOME/.config/qalculate/qalc.result.history"
mkdir -p "$(dirname "$HISTORY_FILE")"
touch "$HISTORY_FILE"

LAST_INPUT=""
while :
do
    # Show history (last 1000 entries)
    QALC_HIST=$(tac "$HISTORY_FILE" | head -1000)
    INPUT=$(fuzzel --dmenu --prompt "= " <<< "$QALC_HIST")

    # Exit if cancelled (Escape pressed)
    rtrn=$?
    if [ "$rtrn" != "0" ]; then
        # Copy last result on exit if exists
        if [ ! -z "$LAST_INPUT" ]; then
            RESULT=$(qalc -t "$LAST_INPUT")
            wl-copy "$RESULT"
        fi
        exit 0
    fi

    # Exit if empty
    [ -z "$INPUT" ] && exit 0

    # If selected from history (contains "="), copy result
    if [[ "$INPUT" =~ .*=.* ]]; then
        RESULT=$(echo "$INPUT" | awk '{print $NF}')
        wl-copy "$RESULT"
        exit 0
    fi

    # Calculate new expression
    QALC_RET=$(qalc "$INPUT")
    LAST_INPUT=$INPUT
    echo "$QALC_RET" >> "$HISTORY_FILE"
done
