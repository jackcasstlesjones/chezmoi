#!/usr/bin/env bash

if [[ $1 == "open" ]]; then
  # Always re-enable laptop screen when lid opens
  # Disabled: Lenovo eDP-1 spec is stale, and `hyprctl keyword` is rejected by the Lua
  # config ("keyword can't work with non-legacy parsers. Use eval."). Left unconverted.
  # hyprctl keyword monitor "desc:Lenovo Group Limited NE140WUM-N6M,1920x1200@60,2887x0,1"
  :
else
  # Only disable laptop screen when lid closes if external monitor is connected
  if hyprctl monitors -j | jq -e '.[] | select(.description | contains("Samsung") or contains("Dell") or contains("T24m") or contains("KTC"))' > /dev/null; then
    # Disabled: see above.
    # hyprctl keyword monitor "desc:Lenovo Group Limited NE140WUM-N6M,disable"
    :
  fi
fi
