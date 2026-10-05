-- ~/.config/hypr/hyprland.lua
--
-- Ported from hyprland.conf (hyprlang) against Hyprland 0.56.2.
-- API reference: /usr/share/hypr/stubs/hl.meta.lua
-- Migration notes: ~/.config/docs/hyprland-lua.md
--
-- NOTE: hyprland.conf is still present next to this file. Hyprland picks the
-- format ONCE at startup and prefers hyprland.lua, so this file wins after a
-- full restart. To roll back, rename this file and restart.

------------------------------------------------------------------ pywal colors
-- hyprlang did `source = ~/.cache/wal/colors-hyprland.conf` and used $color11 etc.
-- Lua can't `require` a hyprlang file, so parse it. Falls back to the Nord
-- values pywal currently generates if the cache file is missing.
local function load_wal_colors()
    local defaults = {
        foreground = "rgba(d8dee9ff)",
        background = "rgba(2e3440ff)",
        color8     = "rgba(4c566aff)",
        color11    = "rgba(ebcb8bff)",
    }

    local colors = {}
    local f = io.open(os.getenv("HOME") .. "/.cache/wal/colors-hyprland.conf", "r")
    if f then
        for line in f:lines() do
            local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(%S+)")
            if name then colors[name] = value end
        end
        f:close()
    end

    return setmetatable(colors, { __index = defaults })
end

local wal = load_wal_colors()

------------------------------------------------------------------ variables
local mainMod     = "SUPER"                          -- "Windows" key
local hyperKey    = "CTRL + SHIFT + ALT + SUPER"     -- hyperkey (keyd)
local terminal    = "kitty"
local fileManager = "thunar"

------------------------------------------------------------------ monitors
hl.monitor({ output = "desc:Shenzhen KTC Technology Group H32D6",              mode = "2560x1440@99.97", position = "0x0",    scale = 1 })
hl.monitor({ output = "eDP-1",                                                 mode = "preferred",       position = "320x1440", scale = 1 })
hl.monitor({ output = "desc:Samsung Electric Company U32J59x HNMN600224",      mode = "3840x2160@60",    position = "0x0",    scale = 1.5 })
hl.monitor({ output = "desc:LG Electronics LG TV 0x01010101",                  mode = "1920x1080@60",    position = "2240x0", scale = 1 })

------------------------------------------------------------------ env
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
-- Fix for blurry Electron apps (Discord, Obsidian, etc.)
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

------------------------------------------------------------------ permissions
-- Permission changes require a full Hyprland restart, not a reload.
-- hl.config({ ecosystem = { enforce_permissions = true } })
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

------------------------------------------------------------------ look and feel
hl.config({
    general = {
        gaps_in     = 10,
        gaps_out    = 20,
        border_size = 3,

        col = {
            -- Previous static colors (kept for easy reversal):
            -- active_border   = "rgba(ebcb8bff)",
            -- inactive_border = "rgba(595959aa)",
            active_border   = wal.color11,
            inactive_border = wal.color8,
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 2,
        -- rounding_power = 20,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        -- Dim inactive windows
        dim_inactive = true,
        dim_strength = 0.1,

        shadow = {
            enabled      = false,
            range        = 4,
            render_power = 3,
            color        = wal.background,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 2,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        force_split    = 2,
    },

    master = {
        new_status = "master",
    },

    misc = {
        animate_manual_resizes    = true,
        force_default_wallpaper   = 0,
        disable_hyprland_logo     = true,
        on_focus_under_fullscreen = 2,    -- exit fullscreen when a new window opens
        focus_on_activate         = true, -- allow apps to request focus
    },

    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0, -- -1.0 - 1.0, 0 means no modification

        touchpad = {
            natural_scroll = true,
        },
    },

    -- Force zero scaling for XWayland apps to prevent blurriness on HiDPI
    xwayland = {
        force_zero_scaling = true,
    },
})

-- gestures: unused in the hyprlang config (workspace_swipe was commented out)
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

------------------------------------------------------------------ curves & animations
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}   } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}   } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}      } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}    } })
-- Custom bounce curve for the window bounce effect when new windows open
hl.curve("bounce",         { type = "bezier", points = { {0.1, 0.55},  {0.2, 1.2}  } })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
-- Bounce effect on existing windows when new ones appear (was: 4.79, easeOutQuint)
hl.animation({ leaf = "windows",       enabled = true,  speed = 6,    bezier = "bounce" })
-- Bounce for new window animations (was: 4.1, easeOutQuint, popin 87%)
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  bezier = "bounce",       style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = false, speed = 3,    bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = false, speed = 3,    bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = false, speed = 3,    bezier = "almostLinear", style = "slide" })

------------------------------------------------------------------ per-device input
hl.device({ name = "epic-mouse-v1",                    sensitivity = -0.5 })
hl.device({ name = "elan0678:00-04f3:3195-touchpad",   sensitivity = 0 })
hl.device({ name = "microsoft-surface-045e:09af-touchpad", sensitivity = 0.3 })

------------------------------------------------------------------ autostart
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

------------------------------------------------------------------ keybinds: apps
hl.bind(mainMod  .. " + I",     hl.dsp.exec_cmd(terminal))
hl.bind(mainMod  .. " + E",     hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod  .. " + M",     hl.dsp.exec_cmd("~/.config/scripts/system-menu.sh"))
hl.bind(mainMod  .. " + W",     hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod  .. " + space", hl.dsp.exec_cmd("fuzzel --hide-prompt -I"))
hl.bind(mainMod  .. " + P",     hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod  .. " + Y",     hl.dsp.exec_cmd("wofi-calc"))
hl.bind(mainMod  .. " + C",     hl.dsp.exec_cmd("/home/jack/.config/waybar/scripts/theme-sed-toggle.sh"))
hl.bind(mainMod  .. " + B",     hl.dsp.exec_cmd("kitty --class=bluetui -o remember_window_size=no -o initial_window_width=600 -o initial_window_height=500 bluetui"))
hl.bind(mainMod  .. " + R",     hl.dsp.exec_cmd("~/.config/scripts/toggle-samsung-res.sh"))
hl.bind(mainMod  .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(hyperKey .. " + Y",     hl.dsp.exec_cmd("kitty --class yazi-float -e yazi"))
hl.bind(hyperKey .. " + O",     hl.dsp.exec_cmd("~/.config/scripts/fuzzel-find-dir.sh"))
hl.bind(hyperKey .. " + N",     hl.dsp.exec_cmd("~/.config/hypr/scripts/scratchpad.sh"))
hl.bind(hyperKey .. " + space", hl.dsp.exec_cmd([[hyprctl clients -j | jq -e '.[] | select(.class == "calculator")' > /dev/null || kitty --class calculator -e ~/.local/bin/calc-memory]]))

-- Clipboard history
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | fuzzel --hide-prompt --dmenu --with-nth 2 | cliphist decode | wl-copy"))

-- Screenshots
hl.bind(hyperKey .. " + 3", hl.dsp.exec_cmd("hyprshot -m region --freeze --clipboard-only"))
hl.bind(hyperKey .. " + 5", hl.dsp.exec_cmd("hyprshot -m region --freeze --raw | tee >(wl-copy) | swappy -f -"))

-- Type characters the keyboard layout makes awkward
hl.bind(mainMod .. " + 1", hl.dsp.exec_cmd([[wtype "~"]]))
hl.bind(mainMod .. " + 2", hl.dsp.exec_cmd([[wtype '`']]))
hl.bind(mainMod .. " + 3", hl.dsp.exec_cmd([[wtype '£']]))
-- NOTE: `bind = $mainMod, B, exec, wtype n` was in hyprland.conf but never fired —
-- SUPER+B was already bound to bluetui above and the first match wins. Left out.

-- Hyprsunset (blue light filter)
hl.bind(mainMod .. " + U",         hl.dsp.exec_cmd("pkill hyprsunset || hyprsunset -t 2000"))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd("hyprsunset -t 2000"))

-- Alt + hjkl as arrow keys
hl.bind("ALT + h", hl.dsp.exec_cmd("wtype -k Left"))
hl.bind("ALT + j", hl.dsp.exec_cmd("wtype -k Down"))
hl.bind("ALT + k", hl.dsp.exec_cmd("wtype -k Up"))
hl.bind("ALT + l", hl.dsp.exec_cmd("wtype -k Right"))

-- Disable Ctrl+T in Chrome windows
hl.bind("CTRL + T", hl.dsp.exec_cmd([[hyprctl activewindow -j | jq -e '.class | contains("chrome")' > /dev/null || wtype -M ctrl -k t]]))

------------------------------------------------------------------ keybinds: windows
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + Z", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))  -- dwindle
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("~/.config/hypr/scripts/move-to-workspace.sh"))

hl.bind(hyperKey .. " + Return", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(hyperKey .. " + A",      hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

-- Close every window on the active workspace.
-- Was a `hyprctl clients | jq | xargs hyprctl dispatch closewindow` pipeline.
hl.bind(mainMod .. " + SHIFT + Q", function()
    local ws = hl.get_active_workspace()
    if ws == nil then return end
    for _, w in ipairs(hl.get_workspace_windows(ws.id)) do
        hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
        hl.dispatch(hl.dsp.window.close())
    end
end)

-- Float + pin the active window (stays visible on all workspaces), or undo that.
-- Was a `hyprctl activewindow | jq | hyprctl --batch` pipeline.
hl.bind(hyperKey .. " + P", function()
    local w = hl.get_active_window()
    if w == nil then return end
    if w.pinned then
        hl.dispatch(hl.dsp.window.pin({ action = "toggle" }))
        hl.dispatch(hl.dsp.window.float({ action = "unset" }))
    else
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.pin({ action = "toggle" }))
    end
end)

-- Navigate between windows with hyperkey + vim keys
hl.bind(hyperKey .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(hyperKey .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(hyperKey .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(hyperKey .. " + l", hl.dsp.focus({ direction = "right" }))

-- Swap windows with hyperkey + arrow keys
hl.bind(hyperKey .. " + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(hyperKey .. " + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(hyperKey .. " + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(hyperKey .. " + down",  hl.dsp.window.swap({ direction = "down" }))

-- Resize the active window with super + vim motions
hl.bind(mainMod .. " + h", hl.dsp.window.resize({ x = -50, y =   0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + l", hl.dsp.window.resize({ x =  50, y =   0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + k", hl.dsp.window.resize({ x =   0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + j", hl.dsp.window.resize({ x =   0, y =  50, relative = true }), { repeating = true })

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Swallow middle-click on the touchpad (was a bind nested in input:touchpad)
hl.bind("mouse:274", hl.dsp.no_op())

------------------------------------------------------------------ keybinds: workspaces
-- Letter workspaces: hyperkey focuses, ALT+SHIFT moves the active window there.
local letterWorkspaces = { "C", "E", "D", "F", "V", "W", "X", "Z", "T", "M", "G", "4" }
for _, key in ipairs(letterWorkspaces) do
    hl.bind(hyperKey .. " + " .. key, hl.dsp.focus({ workspace = "name:" .. key }))
    hl.bind("ALT + SHIFT + " .. key,  hl.dsp.window.move({ workspace = "name:" .. key, follow = true }))
end

-- Workspace N is deliberately not in the loop: hyperkey+N is the scratchpad
-- above, and in hyprland.conf its `workspace name:N` bind was shadowed and never
-- fired. hyperkey+R is the working way to reach workspace N.
hl.bind("ALT + SHIFT + N", hl.dsp.window.move({ workspace = "name:N", follow = true }))
hl.bind(hyperKey .. " + R", hl.dsp.focus({ workspace = "name:N" }))

-- Alias: S -> M
hl.bind(hyperKey .. " + S", hl.dsp.focus({ workspace = "name:M" }))
hl.bind("ALT + SHIFT + S",  hl.dsp.window.move({ workspace = "name:M", follow = true }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = true }))

-- Cycle workspaces
hl.bind(mainMod  .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod  .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(hyperKey .. " + minus",      hl.dsp.focus({ workspace = "e-1" }))
hl.bind(hyperKey .. " + equal",      hl.dsp.focus({ workspace = "e+1" }))

-- Monitors
hl.bind(mainMod  .. " + period", hl.dsp.workspace.move({ monitor = "+1" }))
hl.bind(hyperKey .. " + period", hl.dsp.exec_cmd("~/.config/scripts/toggle-workspaces-monitors.sh"))
-- hl.bind(mainMod .. " + comma",         hl.dsp.focus({ monitor = "-1" }))
-- hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.workspace.move({ monitor = "-1" }))

------------------------------------------------------------------ keybinds: media
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"),          { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"),          { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("swayosd-client --brightness raise"),             { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("swayosd-client --brightness lower"),             { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

hl.bind(hyperKey .. " + Q",   hl.dsp.exec_cmd("playerctl -p spotify play-pause"))
hl.bind(hyperKey .. " + tab", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("SHIFT + ALT + space", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind(mainMod .. " + left",  hl.dsp.exec_cmd("playerctl -p spotify previous"))
hl.bind(mainMod .. " + right", hl.dsp.exec_cmd("playerctl -p spotify next"))

-- Volume with super + alt + arrows, and hyperkey + 1/2
hl.bind(mainMod  .. " + ALT + up",   hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind(mainMod  .. " + ALT + down", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind(hyperKey .. " + 1",          hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind(hyperKey .. " + 2",          hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })

-- SK75 keyboard volume controls (device-scoped; was a `device { bindel = ... }` block)
local sk75 = { inclusive = true, list = { "telink-wireless-gaming-keyboard" } }
hl.bind("F11", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true, device = sk75 })
hl.bind("F12", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true, device = sk75 })

-- Clamshell mode: disable/enable the laptop screen when the lid closes/opens
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("~/.config/scripts/lid.sh open"),  { locked = true })
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("~/.config/scripts/lid.sh close"), { locked = true })

------------------------------------------------------------------ window rules
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
    name  = "yazi-float",
    match = { class = "^(yazi-float)$" },
    float   = true,
    size    = "1200 800",
    center  = true,
    opacity = "0.95 0.8",
})

------------------------------------------------------------------ workspace rules
-- Pin workspace 4 to the Lenovo monitor
hl.workspace_rule({ workspace = "name:4", monitor = "desc:Lenovo Group Limited T24m-10 VTG73855" })

-- "Smart gaps" / "no gaps when only" — uncomment all if you want it
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]"   }, border_size = 0, rounding = 0 })
