#!/usr/bin/env bash

# Check if an external monitor is connected
if hyprctl monitors -j | jq -e '.[] | select(.description | contains("Samsung") or contains("Dell"))' > /dev/null; then
  if [[ $1 == "open" ]]; then
    # Re-enable laptop screen when lid opens
    hyprctl keyword monitor "desc:Lenovo Group Limited NE140WUM-N6M,1920x1200@60,2887x0,1"
  else
    # Disable laptop screen when lid closes
    hyprctl keyword monitor "desc:Lenovo Group Limited NE140WUM-N6M,disable"
  fi
fi
