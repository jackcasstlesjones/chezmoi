#!/usr/bin/env python3
"""Write a qt6ct colour scheme from the current pywal colours.

Output: ~/.cache/wal/colors-qt6ct.conf (qt6ct.conf's color_scheme_path points here).
Run after `wal` (wallpaper-theme.sh does), so Qt apps follow the wallpaper too.
Roles match the rest of the desktop: color11 is the accent/selection colour.
"""

import json
from pathlib import Path

WAL = Path.home() / ".cache/wal"


def mix(a: str, b: str, t: float) -> str:
    """Blend hex colour a towards b by t (0..1)."""
    ca = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    cb = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(ca, cb))


def argb(hex_colour: str, alpha: str = "ff") -> str:
    return f"#{alpha}{hex_colour.lstrip('#')}"


def main():
    wal = json.loads((WAL / "colors.json").read_text())
    bg, fg = wal["special"]["background"], wal["special"]["foreground"]
    c = wal["colors"]
    surface, muted, accent = c["color0"], c["color8"], c["color11"]

    # QPalette roles, in qt6ct's order
    active = [
        fg,                          # WindowText
        surface,                     # Button
        mix(surface, "#ffffff", .2), # Light
        mix(surface, "#ffffff", .1), # Midlight
        mix(bg, "#000000", .3),      # Dark
        muted,                       # Mid
        fg,                          # Text
        c["color15"],                # BrightText
        fg,                          # ButtonText
        mix(bg, "#000000", .15),     # Base (inputs, lists)
        bg,                          # Window
        "#000000",                   # Shadow
        accent,                      # Highlight
        bg,                          # HighlightedText
        c["color4"],                 # Link
        c["color5"],                 # LinkVisited
        surface,                     # AlternateBase
        bg,                          # NoRole
        bg,                          # ToolTipBase
        fg,                          # ToolTipText
        muted,                       # PlaceholderText
    ]
    disabled = list(active)
    for i in (0, 6, 8, 13):  # WindowText, Text, ButtonText, HighlightedText
        disabled[i] = muted

    def line(colours):
        return ", ".join(argb(x) for x in colours)

    (WAL / "colors-qt6ct.conf").write_text(
        "[ColorScheme]\n"
        f"active_colors={line(active)}\n"
        f"disabled_colors={line(disabled)}\n"
        f"inactive_colors={line(active)}\n"
    )


if __name__ == "__main__":
    main()
