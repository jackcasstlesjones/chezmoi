# External Monitor Not Detected Through HP Dock (MST Stuck at Boot)

## Issue
External monitor on the HP USB-C Dock G5 shows nothing. Hyprland only lists
`eDP-1`. Unplugging/replugging the dock and power-cycling the dock do not help.
Rebooting usually fixes it, but not always.

**Fix: suspend and wake** (`systemctl suspend`, then wake). Monitor comes back.

Not a Hyprland, monitor or dock problem. It's amdgpu's DisplayPort MST state on
the laptop getting stuck.

## System details

- kernel 7.2.8-arch1-1, amdgpu (card1, DRM minor 1)
- hyprland 0.56.2-3, aquamarine 0.15.1-1
- HP USB-C Dock G5 (`03f0:036b`), monitor reached via MST hub on `DP-2`
  (connector id 471)

## Symptoms

All external connectors report disconnected, even with the dock enumerated over
USB (keyboard, mouse, ethernet, audio all work):

```
$ for c in /sys/class/drm/card1-*/; do echo "$(basename $c): $(cat $c/status)"; done
card1-DP-1: disconnected
card1-DP-2: disconnected
...
card1-eDP-1: connected
```

Since the kernel sees no monitor, there's nothing for Hyprland to pick up.

## Diagnosis

The kernel log shows the MST sideband request failing **at boot**, before login:

```
19:32:08 [drm] DM_MST: Differing MST start on aconnector: ... [id: 471]
19:32:08 amdgpu: [drm] *ERROR* Sending link address failed with -5
```

`-5` is EIO: the dock didn't answer the "which monitors are behind you" query.
After that amdgpu never retries. Replugging only re-trains the link, with no MST
topology rebuild and no new connectors:

```
19:36:55 [drm] DM_MST: stopping TM on aconnector: ... [id: 471]
19:37:02 amdgpu: [drm] *ERROR* lttpr_caps phy_repeater_cnt is 0x0, forcing it to 0x80.
19:37:02 amdgpu: [drm] *ERROR* LTTPR count is nonzero but invalid lane count reported. Assuming no LTTPR present.
```

Boots earlier the same day (same kernel, no package updates) logged
`Differing MST start` with no `link address failed`, and the monitor worked.
So it's an intermittent race at boot, not a config regression.

Check for it:

```
journalctl -b -k | grep -E "link address|DM_MST"
```

## Fix

Suspend and wake with the dock plugged in:

```
systemctl suspend
```

On resume amdgpu re-runs the MST topology probe, which re-sends the link
address request and rebuilds the connectors. Verify:

```
grep -l '^connected' /sys/class/drm/card1-DP-*/status
```

### Untested alternative (root)

Force a hotplug on the MST root connector via debugfs:

```
sudo sh -c 'echo 0 > /sys/kernel/debug/dri/1/DP-2/trigger_hotplug; sleep 2; echo 1 > /sys/kernel/debug/dri/1/DP-2/trigger_hotplug'
```

## Things that did NOT help

- Replugging the dock's USB-C cable
- Power-cycling the dock
- Anything in Hyprland (it never gets a connector to configure)

## Related

- `amdgpu-suspend-issue.md`
- `hyprland-monitor-hotplug-wallpaper.md`
- Dock firmware update v1.0.26.0 was pending as of 2026-09-21. Worth applying
  if this keeps happening.
