-- Runs once at Hyprland startup (not on reload).
hl.on("hyprland.start", function()
    -- Daemons
    hl.exec_cmd("wal -R -n -q")
    hl.exec_cmd("pgrep -x waybar || waybar")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("nm-applet")
    -- Cursor theme chosen in hypr-settings (Appearance) is stored in gsettings
    hl.exec_cmd([[hyprctl setcursor "$(gsettings get org.gnome.desktop.interface cursor-theme | tr -d "'")" "$(gsettings get org.gnome.desktop.interface cursor-size)"]])
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("udiskie --automount --notify")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Apps
    -- hl.exec_cmd("discord", { workspace = "name:D silent" })
    hl.exec_cmd([[kitty -e zsh -c 'cd ~/obsidian/jacks-vault/ && nvim -O scratchpad.md home.md']], { workspace = "name:N silent" })
    -- hl.exec_cmd("kitty", { workspace = "name:V silent" })
    -- hl.exec_cmd("spotify-launcher", { workspace = "name:W silent" })

    hl.dispatch(hl.dsp.focus({ workspace = "name:N" }))
end)
