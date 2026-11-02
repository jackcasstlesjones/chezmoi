hl.on("hyprland.start", function()
    hl.exec_cmd("wal -R -n -q & pgrep -x waybar || waybar & hypridle & hyprpaper & nm-applet & wl-paste --type text --watch cliphist store & swayosd-server")
    hl.exec_cmd("udiskie --automount --notify")

    -- hl.exec_cmd("discord", { workspace = "name:D silent" })
    hl.exec_cmd([[kitty -e zsh -c 'cd ~/obsidian/jacks-vault/ && nvim -O scratchpad.md home.md']], { workspace = "name:N silent" })
    -- hl.exec_cmd("kitty", { workspace = "name:V silent" })
    -- hl.exec_cmd("spotify-launcher", { workspace = "name:W silent" })

    hl.exec_cmd("wl-paste --type text --watch cliphist store")  -- text only
    hl.exec_cmd("wl-paste --type image --watch cliphist store") -- image only

    -- was: exec-once = hyprctl dispatch workspace name:N
    hl.dispatch(hl.dsp.focus({ workspace = "name:N" }))
end)
