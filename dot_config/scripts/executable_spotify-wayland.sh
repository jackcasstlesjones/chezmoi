#!/bin/bash
# Launch Spotify with Wayland scaling fix

# Force Spotify to use correct scaling on Wayland
spotify --enable-features=UseOzonePlatform --ozone-platform=wayland
