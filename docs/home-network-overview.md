# Home Network Overview

Last verified: 2026-05-21

This document records the current home-network operating model so future maintenance does not need the topology explained from scratch. Keep credentials, proxy subscription URLs, API tokens, controller secrets, and full hosted object names out of this file.

## Topology

```text
LAN clients
  DHCP server: main router
  DHCP-provided gateway: R4S
  DHCP-provided DNS: R4S

        ->

FriendlyElec R4S side router
  Runs iStoreOS + OpenClash / Mihomo
  Handles DNS interception, fake-ip, transparent proxy, and policy routing

        ->

Main router
  Handles DHCP leases and the real upstream Internet path
```

## Current Addresses And Roles

- Main router: `192.168.0.1`
  - Owns DHCP for the `192.168.0.0/24` LAN.
  - DHCP leases point clients at the R4S for both gateway and DNS.
  - Web UI is reachable from the Mac over HTTP on port `80`; HTTPS on port `443` is not expected to be available unless enabled separately.

- R4S side router: `192.168.0.4`
  - Device: FriendlyElec R4S.
  - OS observed: iStoreOS `22.03.6` / rockchip armv8 / aarch64.
  - LAN bridge: `br-lan` on `192.168.0.4/24`.
  - Default route: via main router `192.168.0.1`.
  - DHCP service on the R4S LAN is disabled; the main router remains the DHCP authority.
  - DNS entry point for LAN clients is the R4S dnsmasq service, which forwards to OpenClash DNS.

## Proxy And DNS Path

The R4S is the active home proxy path.

- OpenClash is enabled on the R4S.
- Current runtime core observed: Mihomo Meta `v1.19.25` linux arm64.
- Runtime config on the R4S: `/etc/openclash/r2s-surge.yaml`.
- Mode: rule mode with fake-ip behavior.
- IPv6 is disabled in the OpenClash profile.
- DNS flow:
  - LAN clients query `192.168.0.4`.
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

- `SharedRules.dconf` is the shared rule-order source for Mac, iOS, and router profiles.
- Top-level `.list` files are local overlays.
- `ACL4SSR/` mirrors the upstream ACL4SSR rule files used by the local profiles.
- GitHub Actions syncs mirrored ACL4SSR files daily at 04:15 Asia/Shanghai.

Observed consistency and migration status:

- The iOS hosted profile `[Rule]` section matched `SharedRules.dconf` exactly.
- The Mac hosted profile `[Rule]` section matched `SharedRules.dconf` exactly.
- The R4S OpenClash profile referenced the same set of GitHub rule URLs as `SharedRules.dconf`.
- On 2026-05-21, R4S was migrated to the R2-hosted source profile and OpenClash
  subscription auto-update was enabled.

## Operational Intent

- Normal home LAN clients should receive DHCP from the main router, but use the R4S as gateway and DNS.
- The R4S is responsible for policy routing, DNS handling, ad blocking, direct/proxy split, and fallback handling.
- iPhone outside-home use should load the Cloudflare-hosted iOS Surge profile.
- Mac/Surge should remain as a backup profile path, not the default primary path.
- Rule changes should start in `surge-rules`, then be reflected into generated/hosted profiles.

## Quick Checks

From a Mac on the LAN:

```sh
route -n get default
scutil --dns
ping 192.168.0.1
ping 192.168.0.4
curl -I http://192.168.0.1
```

Expected shape:

- Default gateway should be the R4S.
- DNS server should be the R4S.
- Main router and R4S should both be reachable.

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

- R4S default route goes through the main router.
- R4S DHCP on LAN remains ignored/disabled.
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

- Do not move DHCP authority from the main router unless deliberately redesigning the network.
- Do not enable R4S DHCP while the main router is still serving DHCP on the same LAN.
- Keep R4S and iOS hosted configs as the active Cloudflare profile pair.
- Keep Mac/Surge hosted config as standby.
- Keep Hong Kong policy groups/nodes excluded unless the local routing policy changes.
- Keep `SharedRules.dconf` as the source of truth for shared rule ordering.
- If a rule behaves differently across clients, compare the generated hosted profile against `SharedRules.dconf` before changing individual device configs.
- For R4S, automatic config updates are now enabled. Do not make long-term
  manual edits on the router; update GitHub public rules or the R2-hosted full
  profile instead.
