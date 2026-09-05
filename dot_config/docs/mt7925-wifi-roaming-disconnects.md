# MT7925 Wi-Fi Roaming Disconnects (Deep Rock Galactic)

## Issue
Deep Rock Galactic drops multiplayer sessions every few minutes, both as host
and as client. Back 4 Blood on the same machine appears unaffected.

Root cause is **not** the game. The Wi-Fi link dies for 10-20s at a time, which
logs out the Steam client, which tears down DRG's peer-to-peer session.

## System details

- kernel 7.1.6-arch1-1
- Wi-Fi: MediaTek MT7925E (`mt7925e`), ASIC rev 79250000
- WM firmware build 20260605184805, `linux-firmware` 20260622-1 (installed 2026-08-10)
- NetworkManager backend: **wpa_supplicant 2:2.11-5** (iwd 3.12-1 installed but
  `disabled` + `inactive`)
- AP: TELUS1784, multi-node mesh, WPA2-PSK (`wpa-psk`, pmf default, no 802.11r)
- Wired NIC `enp195s0f0` present, no cable (`carrier 0`)

## Diagnosis

### Three logs, one timeline

Correlating DRG, the Steam client, and journalctl for 2026-09-05:

```
12:34:23  wlan0: disconnect from AP ...87:8f:1a for new auth to ...06:95:b0
12:34:27  wlan0: deauthenticated from ...06:95:b0 (Reason: 15=4WAY_HANDSHAKE_TIMEOUT)
12:34:37  Steam: ConnectionDisconnected('I/O Operation Failed')
12:34:38  DRG:   BroadcastNetworkFailure: ConnectionLost, SteamSocketsNetDriver
12:34:40  wlan0: re-associating
```

Same sequence repeats at 12:20, 12:41, 12:50, 12:56, 13:04.

Log locations:
- DRG: `~/.local/share/Steam/steamapps/common/Deep Rock Galactic/FSD/Saved/Logs/FSD.log`
- Steam: `~/.local/share/Steam/logs/connection_log.txt`

DRG's own error, for reference:
```
LogNet: Warning: SteamSockets: LowLevelSend: Could not send 78 bytes of data got error 0
LogNet: Error: BroadcastNetworkFailure: FailureType = ConnectionLost,
        ErrorString = Your connection to the host has been lost.
```

### Cause 1: mesh roam ping-pong

Three TELUS1784 BSSIDs sit at near-identical signal (64 / 57 / 49), so
wpa_supplicant flips between them constantly. Roams per day:

| Day | Roams |
|---|---|
| Aug 31 | 36 |
| Sep 1 | 140 |
| Sep 2 | 35 |
| Sep 4 | 57 |
| Sep 5 | 35 |

### Cause 2: handshake failures confined to UNII-3

Not every roam breaks — only roams onto the upper 5GHz channels. All 13
`4WAY_HANDSHAKE_TIMEOUT` events in a 7-day window:

| BSSID | Freq | Channel | Failures |
|---|---|---|---|
| `84:90:0a:87:8f:1a` | 5785 MHz | 157 | 8 |
| `84:90:0a:06:95:b0` | 5745 MHz | 149 | 5 |
| `84:90:0a:87:8f:19` | 5240 MHz | 48 | 0 |
| `84:90:0a:87:8f:18` / `...06:95:ae` | 2462 MHz | 11 | 0 |

Zero failures on channel 48 or 2.4GHz. After the 12:56 outage the card only
recovered by falling back to 2.4GHz (`...87:8f:18`).

This matches a known upstream `mt7925e` regression where the card cannot
complete a WPA2-PSK 4-way handshake **when NetworkManager uses
wpa_supplicant**, with iwd reported as a workaround (see References). Local
firmware (20260622) and kernel (7.1.6) are newer than anything in those
reports, so the match is strong but not proven.

### Relevant config drift

`docs/iwd.txt` in this directory states iwd is configured via
`/etc/iwd/main.conf` and `/etc/NetworkManager/conf.d/iwd.conf`. **Both files no
longer exist**, `/etc/NetworkManager/conf.d/` is empty, and iwd is disabled and
inactive. NetworkManager has fallen back to its wpa_supplicant default — i.e.
exactly the configuration the upstream bug implicates. That note is stale.

### Why DRG breaks but Back 4 Blood does not

- **DRG**: SteamSockets P2P, no dedicated servers. The transport is bound to the
  Steam client's login session, so a Steam logoff kills the game session with no
  resume path. Mission over, host or client.
- **B4B**: dedicated servers (AWS `pdx`) plus a session-resume file. B4B *was*
  hit by the same outage on 2026-09-05 — it wrote
  `compatdata/924970/.../Back4Blood/Steam/Saved/ReconnectSettings.json`
  (sessionId, cluster, team) at 13:04, mid-outage — and offered a Reconnect
  prompt rather than dropping the run.

Not immune, just recoverable.

### Ruled out

- Wi-Fi power save: already off (`iw dev wlan0 get power_save` → off,
  `802-11-wireless.powersave: 0`)
- Signal strength: -63 dBm, 864 MBit/s rx — fine
- Steam relay / region: SteamPingLoc healthy, sea1 at 22-28ms
- DLSS and mod.io errors in `FSD.log` — unrelated noise

## Fixes, best first

1. **Ethernet.** Port is there, no cable in it. Sidesteps both causes, and is
   DRG's own community first-line advice for this symptom.

2. **Pin the BSSID** to channel 48 — strongest AP *and* the only 5GHz channel
   with zero handshake failures here:
   ```bash
   nmcli con mod TELUS1784 802-11-wireless.bssid 84:90:0A:87:8F:19
   nmcli con up TELUS1784
   ```
   Undo with `nmcli con mod TELUS1784 802-11-wireless.bssid ""`.
   Caveat: wpa_supplicant may keep background-scanning even with BSSID locked.

3. **Switch NM back to iwd** (restores the setup `iwd.txt` describes, and is the
   reported workaround for the handshake bug):
   ```bash
   sudo tee /etc/NetworkManager/conf.d/iwd.conf <<'EOF'
   [device]
   wifi.backend=iwd
   EOF
   sudo systemctl enable --now iwd
   sudo systemctl restart NetworkManager
   ```
   Then re-add the powersave setting in `/etc/iwd/main.conf` per `iwd.txt`, and
   update that note to match reality.

4. **Revert the mt7925 firmware blob** if the above doesn't settle it.

## Next steps
1. Try fix 2 or 3, then re-check `journalctl | grep 4WAY_HANDSHAKE_TIMEOUT`
   over a play session
2. Update or delete `docs/iwd.txt` once the backend question is settled

## References
- https://github.com/pop-os/pop/issues/3995 (mt7925e WPA2 4-way handshake regression, iwd workaround)
- https://discourse.nixos.org/t/unsolved-mt7921-iwd-4-way-handshake-timeout-reason-15-on-5ghz-wpa-supplicant-works-fine/77470
- https://zbowling.github.io/mt7925/issues/known-issues/
- https://bbs.archlinux.org/viewtopic.php?id=305588 (mt7925e Wi-Fi issues)
- https://discuss.cachyos.org/t/networkmanager-wpa-supplicant-still-scanning-with-bssid-locked/7414
- https://access.redhat.com/solutions/156593 (wpa_supplicant over-aggressive roaming)
- https://www.gearupbooster.com/blog/deep-rock-galactic-server-issue.html (DRG is pure P2P)
