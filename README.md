# Surge Rules

Read this first when maintaining the home routing rules. This repository is the
public-safe rule source for the home Surge/OpenClash profiles; keep proxy
subscriptions, API tokens, controller secrets, dashboard passwords, generated
R2 object keys, and private device credentials out of git.

## Architecture Overview

This proxy system has one rule source, one hosted configuration distribution
layer, and two active clients:

```text
GitHub: Garylauchina/surge-rules
  Public-safe rule sets, shared rule order, and maintenance notes
  Source of truth for rule changes and fake-ip compatibility entries

        ->

Cloudflare R2: surge-configs
  Hosts generated full profile files behind stable update URLs
  Distribution layer only; do not treat hosted files as the long-term source

        ->

Home: R4S OpenClash side gateway
  Used while on the home LAN
  Handles gateway, DNS, fake-ip, transparent proxy, and policy routing for LAN clients

Away: iPhone Surge profile
  Used when the phone is outside home
  Consumes a Cloudflare-hosted Surge profile URL and reuses the same rule logic
```

The important mental model:

- GitHub is the rule and documentation source of truth.
- Cloudflare R2 serves complete generated profiles by URL.
- R4S OpenClash is the home gateway consumer.
- iPhone Surge is the outside-home consumer.
- R4S and iPhone should share the same rule intent through `SharedRules.dconf`,
  but device-specific proxy subscriptions, secrets, and generated profiles stay
  out of this public repository.
- Temporary router-side fixes are allowed for diagnosis, but successful fixes
  must be copied back here and into the hosted R2 profile.

## Current Home Network

Normal LAN clients get DHCP from the main router, but use the R4S as both
gateway and DNS.

```text
LAN clients
  DHCP server: main router
  DHCP-provided gateway: R4S
  DHCP-provided DNS: R4S

        ->

FriendlyElec R4S side router
  iStoreOS + OpenClash / Mihomo
  DNS interception, fake-ip, transparent proxy, and policy routing

        ->

Main router
  DHCP authority and real upstream Internet path
```

Important local roles:

- Main router: `192.168.0.1`
- R4S side router: `192.168.0.4`
- R4S runtime profile: `/etc/openclash/r2s-surge.yaml`
- R4S mode: OpenClash rule mode with fake-ip DNS behavior
- LAN DNS entry point: R4S dnsmasq, forwarding into OpenClash DNS
- Fake-IP range: `198.18.0.0/16`

OpenClash ports observed on the R4S:

- HTTP proxy: `7890`
- SOCKS proxy: `7891`
- redir: `7892`
- mixed: `7893`
- TPROXY: `7895`
- DNS: `7874`
- controller/dashboard: `9090`

Do not move DHCP authority from the main router or enable R4S DHCP unless the
network is being deliberately redesigned.

## Hosted Profiles

Cloudflare R2 bucket: `surge-configs`

Public profile host:

- `https://surge.prometheusclothing.net/`

The bucket carries three profile types:

- R4S OpenClash profile: active
- iOS Surge home/away profile: active
- Mac Surge router profile: standby fallback

Hosted profiles should be generated from the same rule order as
`SharedRules.dconf`. Do not commit full generated R2 object names if they contain
private identifiers; keep those in local notes or operational commands only.

## Repository Model

- `SharedRules.dconf` is the shared `[Rule]` source for Mac, iOS, and router
  profiles.
- Top-level `.list` files are local overlays and should appear before broad
  mirrored ACL4SSR rules.
- `ACL4SSR/` mirrors upstream ACL4SSR rule files used by local profiles.
- `scripts/sync-acl4ssr.sh` refreshes mirrored ACL4SSR files.
- `.github/workflows/sync-acl4ssr.yml` runs the mirror sync daily at 04:15
  Asia/Shanghai.
- `OpenClashFakeIPFilter.list` records router-side fake-ip compatibility
  filters that should also be copied into the R4S hosted OpenClash profile's
  `dns.fake-ip-filter` list.

Rule changes start in this repository, then are reflected into generated or
hosted profiles. If behavior differs across clients, compare the generated
profile against `SharedRules.dconf` before changing individual device configs.

## Recent Compatibility Notes

Diablo IV China resources need real DNS answers for the NetEase Leihuo CDN.
The working fake-ip filter set is:

```text
+.leihuo.netease.com
+.necdn.leihuo.netease.com
+.163jiasu.com
+.ctlcdn.cn
```

These entries are DNS compatibility filters, not traffic routing rules. Keep
them in `OpenClashFakeIPFilter.list` and in the R4S hosted profile's
`dns.fake-ip-filter`. The matching direct routing overlay lives in
`BattleNetCN.list`.

Do not broaden this to `+.netease.com` unless a real failure requires it.

## Overlay Usage

Example policy groups and overlay rules:

```ini
🚀 节点选择 = select,🇸🇬🇺🇲 新美节点,♻️ 自动选择,🔯 故障转移,🔮 负载均衡,🇨🇳 台湾节点,🇸🇬 狮城节点,🇯🇵 日本节点,🇺🇲 美国节点,🚀 手动切换,DIRECT
🎬 TerminusEmby = select,DIRECT,🇸🇬 狮城节点,🇺🇲 美国节点,🚀 节点选择,♻️ 自动选择,🚀 手动切换

RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/AI.list,💬 Ai平台,update-interval=3600
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/YouTube.list,📹 油管视频,update-interval=3600
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/TerminusEmbyDirect.list,DIRECT,update-interval=3600
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/TerminusEmby.list,🎬 TerminusEmby,update-interval=3600
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/BattleNetCN.list,🎯 全球直连,update-interval=3600
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/TikTokOverlay.list,🎵 TikTok,update-interval=3600
```

Place local overlay `RULE-SET` lines before broad mirrored ACL4SSR rule sets so
local overrides take priority.

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

- Default gateway is the R4S.
- DNS server is the R4S.
- Main router and R4S are both reachable.

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
- R4S DHCP on LAN remains ignored or disabled.
- OpenClash and dnsmasq are running.
- OpenClash logs show direct, proxy, and reject policy hits.

For Cloudflare R2:

```sh
wrangler whoami
wrangler r2 bucket info surge-configs
```

For GitHub rules:

```sh
git clone https://github.com/Garylauchina/surge-rules.git
```

## Maintenance Policy

- Keep `SharedRules.dconf` as the source of truth for rule order.
- Keep R4S and iOS hosted configs active.
- Keep Mac/Surge hosted config as standby.
- Keep Hong Kong policy groups and Hong Kong nodes excluded unless the routing
  policy changes.
- Keep subscription regex filters excluding Hong Kong node names.
- Keep fake-ip compatibility filters narrow and documented in
  `OpenClashFakeIPFilter.list`.
- When editing hosted R4S DNS behavior, update both this repository and the R2
  hosted OpenClash profile.

More detailed topology notes live in `docs/home-network-overview.md`, but this
README should be enough to resume normal maintenance without rereading that file
first.
