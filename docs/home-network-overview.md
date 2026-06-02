# Home Network Overview

Last verified: 2026-06-02

This document records the current home-network operating model so future maintenance does not need the topology explained from scratch. Keep credentials, proxy subscription URLs, API tokens, controller secrets, and full hosted object names out of this file.

## Topology

```text
LAN clients
  DHCP server: R4S
  DHCP-provided gateway: R4S
  DHCP-provided DNS: R4S

        ->

FriendlyElec R4S main router
  Runs iStoreOS + OpenClash / Mihomo
  Handles DHCP, DNS interception, fake-ip, transparent proxy, and policy routing

        ->

TP-Link TL-R479GP-AC
  Downstream AP/AC/switch at 192.168.0.2
  DHCP, NAT, and WAN routing are disabled/not used

        ->

ISP gateway / ONT
  Upstream router at 192.168.1.1
```

## Current Addresses And Roles

- R4S main router: `192.168.0.1`
  - Device: FriendlyElec R4S.
  - OS observed: iStoreOS `22.03.6` / rockchip armv8 / aarch64.
  - LAN bridge: `br-lan` on `192.168.0.1/24`.
  - WAN: DHCP on `eth0`, currently `192.168.1.2/24`.
  - Default route: via upstream ISP gateway `192.168.1.1`.
  - DHCP service on the R4S LAN is enabled and authoritative for `192.168.0.0/24`.
  - DNS entry point for LAN clients is the R4S dnsmasq service, which forwards to OpenClash DNS.
  - Static DHCP bindings currently include the TP-Link management address, the game PC, and a known high-upload device.

- TP-Link TL-R479GP-AC: `192.168.0.2`
  - Used for switching, PoE, and AP/AC management.
  - Does not own LAN DHCP, DNS, NAT, or the default gateway in the current topology.

- ISP gateway / ONT: `192.168.1.1`
  - Still running as the upstream router.
  - The network is currently double-NAT, which is acceptable while no inbound service exposure is required.

## Proxy And DNS Path

The R4S is the active home proxy path.

- OpenClash is enabled on the R4S.
- Current runtime core observed: Mihomo Meta `v1.19.25` linux arm64.
- Runtime config on the R4S: `/etc/openclash/r2s-surge.yaml`.
- Mode: rule mode with fake-ip behavior.
- IPv6 is disabled in the OpenClash profile.
- DNS flow:
  - LAN clients query `192.168.0.1`.
  - dnsmasq on the R4S forwards to OpenClash DNS at `127.0.0.1:7874`.
  - fake-ip answers use the `198.18.0.0/16` range.
- Transparent proxy behavior observed:
  - TCP traffic is redirected to the OpenClash redir port.
  - UDP traffic is handled through TPROXY.
  - DNS hijack rules are active so client DNS remains under the R4S policy path.

Common local OpenClash ports observed on the R4S:

- HTTP proxy: `7890`
- SOCKS proxy: `7891`
- redir: `7892`
- mixed: `7893`
- TPROXY: `7895`
- DNS: `7874`
- dashboard/controller: `9090`

Do not commit dashboard secrets or controller passwords.

## Cloudflare R2 Hosted Profiles

Cloudflare R2 bucket: `surge-configs`

The bucket currently carries three hosted profile types:

- R4S OpenClash profile
- iOS Surge home/away profile
- Mac Surge router profile

Current operating status:

- Active: Cloudflare-hosted R4S profile. OpenClash subscription auto-update is
  enabled and runs daily at 04:00.
- Active: Cloudflare-hosted iOS phone outside-home profile.
- Standby: Mac/Surge profile. Keep it available as a fallback path, but it is not the primary operating path right now.

Public profile host observed:

- `https://surge.prometheusclothing.net/`

Avoid committing full R2 object keys if they contain generated identifiers.

## GitHub Rule Source

Rules repository:

- `Garylauchina/surge-rules`

Rule-source model:

- `SharedRules.dconf` records the public shared rule intent promoted from the
  current stable R4S profile. It is split into local overlays and ACL4SSR mirror
  rules.
- Top-level `.list` files are local overlays.
- `ACL4SSR/` mirrors the upstream ACL4SSR rule files used by the local profiles.
- GitHub Actions syncs mirrored ACL4SSR files daily at 04:15 Asia/Shanghai.

Observed consistency and migration status:

- The R4S OpenClash profile references the same public rule URL set as
  `SharedRules.dconf`; full private node/group details stay in the hosted R2
  profile.
- iOS and Mac hosted profiles should be compared against the same public rule
  intent, but may not match `SharedRules.dconf` line-for-line while device-
  specific profile generation remains separate.
- On 2026-05-21, R4S was migrated to the R2-hosted source profile and OpenClash
  subscription auto-update was enabled.

## Operational Intent

- Normal home LAN clients should receive DHCP, gateway, and DNS from the R4S.
- The R4S is responsible for policy routing, DNS handling, ad blocking, direct/proxy split, and fallback handling.
- The TP-Link should remain a downstream AP/AC/switch device, not a router.
- iPhone outside-home use should load the Cloudflare-hosted iOS Surge profile.
- Mac/Surge should remain as a backup profile path, not the default primary path.
- Rule changes should start in `surge-rules`, then be reflected into generated/hosted profiles.

## Quick Checks

From a Mac on the LAN:

```sh
route -n get default
scutil --dns
ping 192.168.0.1
ping 192.168.0.2
curl -I http://192.168.0.1
curl -I http://192.168.0.2
```

Expected shape:

- Default gateway should be the R4S at `192.168.0.1`.
- DNS server should be the R4S.
- TP-Link management at `192.168.0.2` should be reachable.

From the R4S:

```sh
ip route
uci show network
uci show dhcp
uci show openclash
ps w | grep -Ei 'openclash|clash|mihomo|dnsmasq'
tail -n 80 /tmp/openclash.log
```

Expected shape:

- R4S default route goes through the upstream ISP gateway.
- R4S DHCP on LAN is enabled and serves `192.168.0.0/24`.
- OpenClash and dnsmasq are running.
- OpenClash logs show rule hits for direct, proxy, and reject policies.

For Cloudflare R2:

```sh
wrangler whoami
wrangler r2 bucket info surge-configs
```

For GitHub rules:

```sh
git clone https://github.com/Garylauchina/surge-rules.git
```

## Maintenance Notes

- Do not re-enable DHCP or NAT on the TP-Link while the R4S is the main router.
- If the ISP gateway is later changed to bridge mode, update this document and the R4S WAN access model together.
- Keep R4S and iOS hosted configs as the active Cloudflare profile pair.
- Keep Mac/Surge profile as standby.
- Keep Hong Kong policy groups/nodes excluded unless the local routing policy changes.
- Keep `SharedRules.dconf` as the public source of truth for shared rule intent:
  local overlays first, ACL4SSR mirror rules second.
- If a rule behaves differently across clients, compare the generated hosted
  profile against `SharedRules.dconf` before changing individual device configs.
- For R4S, automatic config updates are now enabled. Do not make long-term
  manual edits on the router; update GitHub public rules or the R2-hosted full
  profile instead.
