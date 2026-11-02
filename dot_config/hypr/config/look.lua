local wal = require("config.colors")

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
