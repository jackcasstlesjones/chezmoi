-- Ignore maximize requests from apps
hl.window_rule({
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "xwayland-no-initial-focus",
    match = { xwayland = true },
    no_initial_focus = true,
})

-- Force applications to specific workspaces
hl.window_rule({ name = "discord-ws", match = { class = "^(discord)$" }, workspace = "name:D" })
hl.window_rule({ name = "spotify-ws", match = { class = "^(Spotify)$" }, workspace = "name:W" })

-- Kitty transparency
hl.window_rule({ name = "kitty-opacity", match = { class = "(kitty)" }, opacity = "0.95 0.8" })

-- Fast animation for the scratchpad
hl.window_rule({ name = "scratchpad-anim", match = { title = ".*scratchpad.md.*" }, animation = "popin" })

-- No border or blur for ulauncher
hl.window_rule({
    name  = "ulauncher-bare",
    match = { class = "^(ulauncher)$" },
    border_size = 0,
    no_blur     = true,
})

-- No border on fullscreen windows
hl.window_rule({
    name  = "fullscreen-no-border",
    match = { fullscreen = true },
    border_size = 0,
    -- border_color = "rgba(ff0000ff)",
})

-- Floating utility windows
hl.window_rule({
    name  = "calculator-float",
    match = { class = "^(calculator)$" },
    float     = true,
    size      = "400 300",
    center    = true,
    animation = "none",
})

hl.window_rule({
    name  = "pavucontrol-float",
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    float  = true,
    size   = "800 600",
    center = true,
})

hl.window_rule({
    name  = "bluetui-float",
    match = { class = "^(bluetui)$" },
    float  = true,
    size   = "600 500",
    center = true,
})

hl.window_rule({
    name  = "wallpaper-picker-float",
    match = { class = "^(wallpaper-picker)$" },
    float  = true,
    size   = "1400 800",
    center = true,
})

hl.window_rule({
    name  = "clipboard-history-float",
    match = { class = "^(clipboard-history)$" },
    float  = true,
    size   = "1200 700",
    center = true,
})

hl.window_rule({
    name  = "yazi-float",
    match = { class = "^(yazi-float)$" },
    float   = true,
    size    = "1200 800",
    center  = true,
    opacity = "0.95 0.8",
})

hl.window_rule({
    name  = "hypr-settings-float",
    match = { class = "^(hypr-settings)$" },
    float  = true,
    size   = "1100 720",
    center = true,
})
