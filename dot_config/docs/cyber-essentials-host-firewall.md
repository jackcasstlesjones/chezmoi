# Cyber Essentials: Host Firewall & Exposed Dev Services

## Question

Does this machine support the Cyber Essentials scope statement:

> Company-configured laptops accessing cloud services (Google Workspace, GitHub,
> Monday.com, hosting) over the internet via home broadband; device-level
> software firewalls provide the boundary.

Checked 2026-09-15. Answer at the time of checking: **no**. Now partially
remediated — see [Actions taken](#actions-taken).

## System details

- kernel 7.2.4-arch1-2
- `ufw` installed, `nftables` installed, `iptables` (iptables-nft) installed
- Docker running an 11-container Supabase local stack (`ozeaon-v2`) plus a
  standalone Meilisearch (`ssc-meilisearch`)
- Network: WiFi, home broadband (see `mt7925-wifi-roaming-disconnects.md`)

## Findings

### 1. No host firewall was running

All three firewall packages were installed but none was active:

```
/etc/ufw/ufw.conf          ENABLED=no
/etc/systemd/system/multi-user.target.wants/   no ufw/nftables/iptables symlinks
/etc/iptables/iptables.rules   stock empty file (INPUT ACCEPT, FORWARD ACCEPT)
/etc/nftables.conf             unmodified Arch example, never loaded
```

`sudo nft list ruleset` confirmed it. The `filter` table contained only
Docker-generated chains — `DOCKER`, `DOCKER-FORWARD`, `DOCKER-BRIDGE`,
`DOCKER-CT`, `DOCKER-USER`, `FORWARD`. **There was no `input` chain at all**,
so inbound traffic to the host was entirely unfiltered. The
`FORWARD ... policy drop` present in the dump is Docker isolating its bridge
networks, not a host boundary.

### 2. Dev services published on all interfaces

`sudo docker ps` — every published port bound to `0.0.0.0` *and* `[::]`:

| Port  | Service                          | Authentication                                    |
|-------|----------------------------------|---------------------------------------------------|
| 54321 | Kong → PostgREST / Auth / Storage | Supabase local default `anon` / `service_role` JWTs (publicly documented) |
| 54322 | Postgres 17.6.1.159              | Default local password                            |
| 54323 | Supabase Studio                  | **None**                                          |
| 54324 | Mailpit                          | **None** — every email the app sends              |
| 54327 | Logflare analytics               | Default local key                                 |
| 7700  | Meilisearch v1.5                 | Depends on `MEILI_MASTER_KEY`                     |

These are Supabase CLI local-dev defaults, so the credentials are not secret.

Two consequences:

- The bindings are `0.0.0.0`, not LAN-scoped. They follow the laptop onto any
  other network it joins — client office, hotel, hotspot.
- `[::]` bindings depend on the router's inbound IPv6 filtering, which is a
  separate thing to verify.

### 3. ufw does not cover the Docker ports

Docker's DNAT rules live in `nat PREROUTING`, which the kernel traverses
**before** the `filter INPUT` chain where ufw's rules sit. Enabling ufw with a
default-deny inbound policy therefore does not close any of the ports in the
table above. This is the well-known Docker/ufw interaction.

## Actions taken

2026-09-15 — enabled ufw:

```sh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo systemctl enable ufw
```

Result:

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), deny (routed)
New profiles: skip
```

`ufw.service` is symlinked into `multi-user.target.wants`, so it persists across
reboot. `nftables.service` and `iptables.service` remain disabled — they would
contend for the same tables.

No inbound allow rules were added. In particular **no `ufw allow ssh`**; under CE
every permitted inbound service needs a documented business case.

## Outstanding

- [ ] `sudo systemctl restart docker` — enabling ufw rebuilt the `filter` table
      Docker's chains live in, and set the routed policy to drop. Verify
      containers still have outbound networking afterwards.
- [ ] Confirm the Docker ports are still exposed, from a second device on the
      LAN (testing from the laptop itself proves nothing — loopback skips the
      filtered path):
      ```sh
      nc -vz <laptop-lan-ip> 54322 54323 54324
      ```
- [ ] Scope the dev stack to loopback. Meilisearch is under our own compose file,
      so change the mapping to `127.0.0.1:7700:7700`. For the Supabase stack the
      ports come from `supabase/config.toml`; unconfirmed whether it exposes a
      bind-address setting. General fix, keeps localhost access working:
      ```sh
      sudo iptables -I DOCKER-USER -i <wifi-iface> -m conntrack --ctstate NEW -j DROP
      ```
      `DOCKER-USER` is the chain Docker leaves empty for this purpose and *is*
      traversed for forwarded traffic. Does not survive reboot or a Docker
      restart — needs a systemd unit ordered `After=docker.service`.
- [ ] Check the router's inbound IPv6 filtering.

## Notes on the CE position

CE treats home and public networks as untrusted by definition — that is why the
scope statement nominates the device firewall as the boundary. "The LAN is
secure" is the premise CE rejects, not an argument it accepts.

With ufw enabled the scope statement is now true as written. The Docker ports are
the arguable part: whether an assessor treats a DNAT'd container port as
"permitted inbound" requiring a business case. Some would look only at
`ufw status`; a stricter one running a port scan against the laptop on its home
network would find Postgres and Studio.

## Verification

```sh
sudo ufw status verbose          # expect: active, deny (incoming)
systemctl is-enabled ufw         # expect: enabled
sudo nft list ruleset            # expect: an input chain with policy drop
sudo ss -tulnp                   # what is actually listening
sudo docker ps --format '{{.Names}}\t{{.Ports}}'
```
