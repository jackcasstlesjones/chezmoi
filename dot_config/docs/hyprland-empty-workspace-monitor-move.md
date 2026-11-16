# Period binds don't move workspaces between monitors

**Date:** 2026-11-10, updated 2026-11-11 · **Hyprland:** 0.56.2 (Lua config) · **Status:** open, cause unknown

## Symptom

| Bind | Action (`dot_config/hypr/binds/workspaces.lua`) |
| --- | --- |
| `mainMod + period` | `hl.dsp.workspace.move({ monitor = "+1" })`: move the current workspace to the next monitor |
| `hyperKey + period` | `~/.config/scripts/toggle-workspaces-monitors.sh`: move every workspace onto one monitor |

Seen on 2026-11-11: workspace N (`hyperKey + R`, with the nts windows) was on the laptop
screen (eDP-1) and wasn't focused. Neither bind moved it, even after its window was focused.

The workspace had a window, so the first theory, that Hyprland won't move an *empty* workspace, doesn't
explain this. That theory is dropped.

Both modifiers fail, so the hyperkey setup isn't the cause.

## What the state showed afterwards

A query a while later (not while the bug was happening) showed:

| Monitor | Active workspace | Windows |
| --- | --- | --- |
| DP-8 (external, focused) | F | 1 |
| eDP-1 (laptop) | 2 | 0 |

- Workspace N was listed on **DP-8** (inactive there), but its kitty window was still at
  `at=[2583,319]`, which is inside eDP-1 (x starts at 2560). So N was last laid out on the laptop, then
  reassigned to DP-8 without its window being moved.
- eDP-1 was showing a workspace "2", which looks like one Hyprland made when N left.
- A `grim -o eDP-1` screenshot showed an empty laptop screen, which matches Hyprland's state.

Something did eventually move N off the laptop: the toggle script, the monitor layout change below, or
something else. Debug logging was off, so it's unknown what, or whether it came before or after the
failed presses.

Possibly related: on 2026-11-10 eDP-1 was moved in `dot_config/hypr/config/monitors.lua`
from `320x1440` (below the external monitor) to `2560x240` (to its right).

## What the v0.56.2 source says

There's no window-count or "empty workspace" check in the move path:

- `src/config/lua/bindings/LuaBindingsDispatchers.cpp` `dsp_moveCurrentWorkspaceToMonitor`
  bails out only when the monitor isn't found or the focused monitor has no active workspace.
- `src/config/shared/actions/ConfigActions.cpp` `Actions::moveToMonitor` bails out only on a null
  workspace or monitor.
- `src/state/WorkspacePlacementController.cpp` `moveWorkspaceToMonitor` returns early only for
  null arguments or when the workspace is already on the target monitor.

That last check is a candidate: if Hyprland thinks the workspace is already on the target monitor,
the move silently does nothing. Other candidates are focus not landing where expected (so the bind
acts on a different workspace) and the `"+1"` monitor lookup.

## Side issue: toggle script and numbered workspaces

`toggle-workspaces-monitors.sh` targets every workspace as `name:$ws`. For a numbered workspace like
"2" that's `name:2`, which may not refer to workspace ID 2. That's worth checking, but it doesn't
explain workspace N.

## How to capture it next time

Don't test dispatchers on the live session with Claude; that caused a blank screen before. Do it by hand,
**while the bug is happening**, before pressing anything:

```sh
hyprctl keyword debug:disable_logs false
hyprctl monitors -j     | jq -r '.[] | "\(.name) active=\(.activeWorkspace.name) focused=\(.focused)"'
hyprctl workspaces -j   | jq -r '.[] | "\(.name) \(.monitor) windows=\(.windows)"'
hyprctl activewindow -j | jq -r '"\(.class) ws=\(.workspace.name) mon=\(.monitor)"'
```

Then focus the window, press `mainMod + period`, and run the `activewindow` and `workspaces` lines
again. Check the log:

```sh
grep -nE "moveWorkspaceToMonitor|Destroying workspace" \
  "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log" | tail
```

What to look for:

- **`activewindow` isn't on N:** focus never reached the workspace, so the bind acted on another one.
- **N's monitor in `workspaces` doesn't match the screen you see it on:** Hyprland's state and the
  display disagree. That's the same mismatch as above, caught while the bug is happening.
- **No `moveWorkspaceToMonitor: Moving ...` line:** the dispatcher returned early. Check the bind with
  `hyprctl binds -j | jq '.[] | select(.key=="period")'`.
