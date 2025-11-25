#!/usr/bin/env bash

if [[ $1 == "open" ]]; then
  # Always re-enable laptop screen when lid opens
  hyprctl keyword monitor "desc:Lenovo Group Limited NE140WUM-N6M,1920x1200@60,2887x0,1"
else
  # Only disable laptop screen when lid closes if external monitor is connected
  if hyprctl monitors -j | jq -e '.[] | select(.description | contains("Samsung") or contains("Dell"))' > /dev/null; then
    hyprctl keyword monitor "desc:Lenovo Group Limited NE140WUM-N6M,disable"
  fi
fi
