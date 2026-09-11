#!/usr/bin/env bash

# Quit all running apps, then open Stremio on the current workspace.

"$HOME/.config/scripts/quit-all-apps.sh"

exec stremio-enhanced
