#!/usr/bin/env bash

# The laptop panel, matched by description so it survives eDP-N renumbering.
INTERNAL_DESC="Lenovo Group Limited NE140WUM-N6M"

# Under the Lua config manager `hyprctl keyword` is rejected
# ("keyword can't work with non-legacy parsers. Use eval."), so monitor changes
# go through `hyprctl eval` + hl.monitor. Position mirrors hyprland.lua.
# `disabled` is sticky: re-enabling needs an explicit `disabled = false`, since
# setting mode/position alone leaves the monitor off.
if [[ $1 == "open" ]]; then
  hyprctl eval "hl.monitor({ output = \"desc:$INTERNAL_DESC\", mode = \"preferred\", position = \"320x1440\", scale = 1, disabled = false })" >/dev/null
else
  # Only blank the panel if some *other* monitor is still lit — `hyprctl monitors`
  # lists enabled outputs only, so this is any-external rather than a brand list.
  if hyprctl monitors -j | jq -e --arg d "$INTERNAL_DESC" 'any(.[]; .description != $d)' >/dev/null; then
    hyprctl eval "hl.monitor({ output = \"desc:$INTERNAL_DESC\", disabled = true })" >/dev/null
  fi
fi
