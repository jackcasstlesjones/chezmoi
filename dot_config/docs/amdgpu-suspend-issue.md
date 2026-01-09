# AMD GPU VPE Suspend/Resume Issue

**Date**: 2026-01-05
**System**: Lenovo ThinkPad T14 Gen 6 (21QJCTO1WW)
**Kernel**: 6.18.2-arch2-1 → 6.18.3-arch1-1
**BIOS**: R2XET35W (1.15)

## Problem Description

When unplugging laptop from monitor/dock, the system automatically triggers suspend but hangs during the suspend process, resulting in:
- Complete black screen
- System unresponsive (no cursor, no keyboard/mouse response)
- Requires hard reset via power button

## What Happened (Log Analysis)

### Timeline - 2026-01-05 11:29:55

1. **USB disconnection detected** - Dock/monitor unplugged
2. **Auto-suspend triggered** - systemd-logind initiated suspend
3. **System entered suspend** - `PM: suspend entry (s2idle)`
4. **System hung** - No resume logs, system never woke up
5. **Hard reset required** - Next boot at 11:31:47

### Key Errors Found

From earlier suspend cycle at 10:06:04:
```
amdgpu 0000:c4:00.0: amdgpu: Register(0) [regVPEC_QUEUE_RESET_REQ] failed to reach value 0x00000000 != 0x00000001n
amdgpu 0000:c4:00.0: amdgpu: VPE queue reset failed
amdgpu 0000:c4:00.0: [drm:amdgpu_ib_ring_tests [amdgpu]] *ERROR* IB test failed on vpe (-110)
amdgpu 0000:c4:00.0: amdgpu: ib ring test failed (-110)
xhci_hcd 0000:c4:00.4: xHCI host not responding to stop endpoint command
xhci_hcd 0000:c4:00.4: xHCI host controller not responding, assume dead
xhci_hcd 0000:c4:00.4: HC died; cleaning up
```

**Error -110** = Timeout (system kept trying until it hit retry limit)

## Root Cause

### VPE (Video Processing Engine) Suspend Bug

The AMD GPU's VPE hardware block fails to reset properly during suspend operations, causing the system to hang.

### Known Issue - Kernel Patch Available

A kernel patch was submitted in **December 2025** that addresses this specific issue:
- Reverts commit `31ab31433c9bd` which was causing VPE queue reset failures
- The underlying s2idle issue will be fixed in BIOS instead of kernel workarounds
- Patch referenced in kernel bugzilla bug #220812

**Sources**:
- [[PATCH] Revert "drm/amd: Skip power ungate during suspend for VPE"](https://lists.freedesktop.org/archives/amd-gfx/2025-December/134729.html)

### ThinkPad-Specific Dock Issues

Multiple reports of Lenovo ThinkPad AMD GPU suspend/resume issues when docking/undocking:

- **GitLab Issue #2846**: ThinkPad P14s AMD Gen1 - "depending on the sequence of suspending and removing the USB-C docking cable... resuming the laptop renders it pretty much unusable"
- **Arch Forum**: ThinkPad T14s - suspend works when staying connected OR when removed, but re-attaching causes next wakeup to fail
- **Debian Bug #1033637**: External displays through ThinkPad dock don't turn on after suspend

**Sources**:
- [USB devices 'stuck' on resume after suspend while removing USB-C cable](https://gitlab.freedesktop.org/drm/amd/-/issues/2846)
- [[SOLVED] Thinkpad T14s: no wakeup after suspend](https://bbs.archlinux.org/viewtopic.php?id=285784)
- [Debian Bug #1033637](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1033637)

### IB Test Failures

The -110 error (IB test failed) during resume has documented fixes:
- Ubuntu fixes in kernel 5.9-rc1: "drm/amdgpu: asd function needs to be unloaded in suspend phase"
- Resource leakage fix: commit 73469585510d "drm/amdgpu: fix&cleanups for wb_clear"

**Sources**:
- [Bug #1909453 - S3 stress test fails with amdgpu errors](https://bugs.launchpad.net/ubuntu/+source/linux-oem-5.6/+bug/1909453)
- [*ERROR* IB test failed on gfx (-110) on P14s Gen2](https://gitlab.freedesktop.org/drm/amd/-/issues/1824)

## Current Status

### BIOS
✅ **Already at latest version**: R2XET35W (1.15)

### Kernel
❌ **Kernel 6.18.3 does NOT contain the VPE fix**

Checked the official [Linux 6.18.3 changelog](https://cdn.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.18.3) - only contains:
- Display fixes for DCN35/DCN351 scratch registers
- Memory allocation flag changes
- DisplayPort MST revert

No amdgpu VPE or suspend/resume fixes included.

### Next Steps
⏳ **Wait for kernel update** - The December 2025 VPE patch needs to be backported to stable kernels (likely 6.19+ or later 6.18.x updates)

## Potential Workarounds

Until the kernel fix arrives, consider these options:

### 1. Prevent Auto-Suspend on Dock Unplug

Check current settings:
```bash
cat /etc/systemd/logind.conf | grep -E "HandleLidSwitch|HandleDock"
```

Modify `/etc/systemd/logind.conf`:
```ini
[Login]
HandleDockSwitch=ignore
# or
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
```

Restart logind:
```bash
sudo systemctl restart systemd-logind
```

### 2. Disable Specific AMD GPU Power Features

Try kernel parameters in `/etc/default/grub`:
```
GRUB_CMDLINE_LINUX_DEFAULT="... amdgpu.runpm=0"
```

Or:
```
GRUB_CMDLINE_LINUX_DEFAULT="... amdgpu.dcdebugmask=0x10"
```

Update grub:
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 3. Manual Disconnect Workflow

Before unplugging from dock:
1. Save work
2. Manually close laptop lid to suspend while still docked
3. Wait for suspend to complete
4. Unplug dock
5. Open lid to resume

This may avoid the specific timing issue.

### 4. Monitor Kernel Updates

Watch for:
- Kernel 6.19 release
- Later 6.18.x stable updates
- Check changelogs for VPE or suspend fixes

Check available updates:
```bash
checkupdates
# or
yay -Qu
```

### 5. Check fwupd for Firmware Updates

```bash
fwupdmgr get-devices
fwupdmgr refresh
fwupdmgr get-updates
```

## Additional Resources

### Official Lenovo Support
- [ThinkPad T14 Gen 6 Support Page](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/thinkpad-t-series-laptops/thinkpad-t14-gen-6-type-21qj-21qk/21qj)
- [BIOS Update for T14 Gen 6](https://support.lenovo.com/fr/fr/downloads/ds574808-bios-update-utility-bootable-cd-for-windows-11-thinkpad)

### Kernel/Driver Information
- [AMD Linux Graphics Drivers](https://www.phoronix.com/news/AMDGPU-Linux-6.18-Start)
- [Linux Kernel 6.18 Release Notes](https://kernelnewbies.org/Linux_6.18)

## Monitoring Commands

Check for similar errors after resume:
```bash
# View journal for current boot
journalctl -b 0 --no-pager | grep -i amdgpu

# Check for VPE errors specifically
journalctl -b 0 --no-pager | grep -i "vpe\|suspend\|resume"

# Monitor real-time during suspend/resume
sudo journalctl -f
```

Check BIOS version:
```bash
sudo dmidecode -s bios-version
```

Check kernel version:
```bash
uname -r
```

---

**Last Updated**: 2026-01-05
**Status**: Awaiting kernel patch backport to stable releases
