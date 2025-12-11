# Hyprland Crash on HDMI Connect + Suspend/Resume

## Summary
Hyprland crashes with signal 6 (ABRT) when HDMI cable is plugged in, triggering lid detection and system suspend, followed by resume with session lock.

## Environment
- **OS**: Arch Linux (kernel 6.17.9-arch1-1)
- **Hyprland Version**: 0.52.2 (commit 386376400119dd46a767c9f8c8791fd22c7b6e61)
- **Hyprlock**: 0.9.2-7
- **Hypridle**: 0.1.7-6
- **GPU**: AMD (amdgpu driver)
- **Display Manager**: Unknown (using Hyprland with seat0)

## Steps to Reproduce
1. Running Hyprland session on laptop
2. Plug in HDMI cable
3. System detects "Lid closed" event
4. System suspends automatically
5. System resumes
6. Hyprland attempts to restore session lock surface
7. **Hyprland crashes immediately**

## Expected Behavior
Hyprland should handle display hotplug during suspend/resume without crashing, properly restoring the session lock screen.

## Actual Behavior
Hyprland crashes with SIGABRT (signal 6), terminating the entire graphical session and logging out the user.

## Crash Details

### Timestamp
December 9, 2025 at 16:17:21

### Signal
Process 1329 (Hyprland) terminated abnormally with signal 6/ABRT

### Stack Trace
```
Stack trace of thread 1329:
#0  0x00007f545ea9890c n/a (libc.so.6 + 0x9890c)
#1  0x00007f545ea3e3a0 raise (libc.so.6 + 0x3e3a0)
#2  0x00007f545ea2557a abort (libc.so.6 + 0x2557a)
#3  0x0000557e48610ac8 n/a (/usr/bin/Hyprland + 0x2b0ac8)
#4  0x00007f545ea3e4d0 n/a (libc.so.6 + 0x3e4d0)
#5  0x00007f545f854c59 _ZN9Hyprutils6Signal11CSignalBase24registerListenerInternalESt8functionIFvPvEE (libhyprutils.so.10 + 0x38c59)
#6  0x0000557e486f9abd _ZN9Hyprutils6Signal8CSignalTIJEE6listenESt8functionIFvvEE (/usr/bin/Hyprland + 0x399abd)
#7  0x0000557e48a456ee _ZN19CSessionLockSurfaceC1EN9Hyprutils6Memory14CSharedPointerI24CExtSessionLockSurfaceV1EENS2_I18CWLSurfaceResourceEENS2_I8CMonitorEENS1_12CWeakPointerI12CSessionLockEE (/usr/bin/Hyprland + 0x6e56ee)
#8  0x0000557e48a45ed5 _ZN20CSessionLockProtocol16onGetLockSurfaceEP17CExtSessionLockV1jP11wl_resourceS3_ (/usr/bin/Hyprland + 0x6e5ed5)
#9  0x0000557e48bfed01 n/a (/usr/bin/Hyprland + 0x89ed01)
#10 0x00007f545ec29ac6 n/a (libffi.so.8 + 0x7ac6)
#11 0x00007f545ec2676b n/a (libffi.so.8 + 0x476b)
#12 0x00007f545ec2906e ffi_call (libffi.so.8 + 0x706e)
#13 0x00007f545f717532 n/a (libwayland-server.so.0 + 0x6532)
#14 0x00007f545f71cd30 n/a (libwayland-server.so.0 + 0xbd30)
#15 0x00007f545f71b182 wl_event_loop_dispatch (libwayland-server.so.0 + 0xa182)
#16 0x00007f545f71d297 wl_display_run (libwayland-server.so.0 + 0xc297)
#17 0x0000557e488af151 _ZN17CEventLoopManager9enterLoopEv (/usr/bin/Hyprland + 0x54f151)
#18 0x0000557e485874d4 main (/usr/bin/Hyprland + 0x2274d4)
#19 0x00007f545ea27635 n/a (libc.so.6 + 0x27635)
#20 0x00007f545ea276e9 __libc_start_main (libc.so.6 + 0x276e9)
#21 0x0000557e4860ff65 _start (/usr/bin/Hyprland + 0x2aff65)
```

### Key Functions Involved
- `CSessionLockSurface` constructor (frame #7)
- `CSessionLockProtocol::onGetLockSurface` (frame #8)
- Signal listener registration in libhyprutils (frame #5-6)

## System Logs Context

### Lid Event Detection
```
Dec 09 16:17:14 bix systemd-logind[996]: Lid closed.
```
System incorrectly detected lid closure when HDMI was plugged in.

### Suspend/Resume Cycle
```
Dec 09 16:17:14 bix kernel: Freezing user space processes
[... suspend process ...]
Dec 09 16:17:14 bix systemd-logind[996]: Lid opened.
Dec 09 16:17:14 bix systemd-sleep[242334]: System returned from sleep operation 'suspend'.
```

### Crash Immediately After Resume
```
Dec 09 16:17:21 bix systemd-coredump[242827]: Process 1329 (Hyprland) of user 1000 terminated abnormally with signal 6/ABRT, processing...
```

## Analysis
The crash occurs in `CSessionLockSurface` constructor when Hyprland attempts to restore or create a session lock surface after resume. The stack trace suggests a signal listener registration fails or encounters an assertion failure in libhyprutils during the session lock surface initialization.

This appears to be a race condition or lifecycle issue where the session lock protocol handler (`onGetLockSurface`) attempts to create a lock surface for a monitor that may be in an inconsistent state due to the HDMI hotplug event occurring during suspend/resume.

## Workarounds
1. Configure systemd-logind to ignore lid switch when external power/displays are connected:
   ```ini
   # /etc/systemd/logind.conf
   HandleLidSwitchExternalPower=ignore
   HandleLidSwitchDocked=ignore
   ```

2. Disable automatic suspend on lid close

## Related Issues
- Similar crashes reported with session lock surfaces during display state changes
- HDMI disconnect/connect crashes documented in other issues
- Suspend/resume instability reported by multiple users

## Additional Information
- Full coredump available if needed
- Crash is reproducible with the exact sequence of events
- No custom Hyprland patches applied
- Standard Arch Linux packages from official repositories
