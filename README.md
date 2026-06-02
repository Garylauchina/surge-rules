# Surge Rules

Read this first when maintaining the home proxy rules. This repository is the
public-safe source for shared rule intent and maintenance notes. Do not commit
proxy subscriptions, API tokens, controller secrets, dashboard passwords,
generated R2 object keys, or private device credentials.

## Architecture

The proxy system has one public rule source, one hosted configuration delivery
layer, one private VPS endpoint, and two active clients.

```text
GitHub: Garylauchina/surge-rules
  Public-safe rule sets, shared rule order, fake-ip compatibility notes,
  and operational documentation.

        ->

Cloudflare R2: surge-configs
  Hosts generated full client profiles behind update URLs.
  This solves client-side config fetching; it is not the source of truth.

        ->

Private VPS: Vultr Los Angeles
  Runs the self-hosted proxy services used by the R4S and phone profiles.
  Node credentials stay out of this repository.

        ->

Home client: R4S OpenClash main router
  Used on the home LAN.
  Provides DHCP, gateway, DNS, fake-ip, transparent proxy, and policy routing.

Away client: iPhone Surge
  Used when the phone is outside home.
  Pulls its hosted Surge profile URL from Cloudflare R2.
```

The key rule: GitHub stores public rules and docs; R2 stores generated full
profiles for clients to fetch. Keep private subscriptions and node parameters in
local private templates or client-side configuration sources, not in this repo.

## Current Proxy Structure

Verified on 2026-06-02 after the R4S main-router migration.

```text
GitHub surge-rules
  Public-safe rule overlays, shared rule order, fake-ip compatibility notes,
  and operating documentation.

        -> publish/generate full profiles

Cloudflare R2 surge-configs
  R4S OpenClash full profile
  iPhone Surge home/away full profile

        -> profile auto-update

R4S OpenClash at home
  Primary LAN gateway, DHCP, DNS, fake-ip, transparent proxy, and policy
  routing.
  Current home self-hosted exit: Vultr LA VLESS Reality on TCP 443.

TP-Link TL-R479GP-AC
  Downstream LAN device at 192.168.0.2.
  Used for switching, PoE, and AP/AC management; it no longer owns DHCP,
  NAT, or the LAN default gateway.

ISP gateway / ONT
  Upstream router at 192.168.1.1.
  R4S WAN receives 192.168.1.2 by DHCP, so the current Internet path is
  double-NAT. This is acceptable while there is no inbound service requirement.

iPhone Surge away profile
  Cellular/outside-home profile.
  Current self-hosted nodes: Vultr LA Trojan on TCP 8443 and Hysteria2 on UDP
  8443. The phone profile does not currently include the VLESS Reality 443 node.

Vultr LA VPS
  Public host: vps.prometheusclothing.net
  Address: 45.32.87.131
  Services: VLESS Reality 443, Trojan TLS 8443, Hysteria2 8443.
  Kernel transport tuning: BBR enabled with fq qdisc.
```

Current R4S policy selections, as verified through the OpenClash controller:

- `🚀 节点选择` -> `自建 Vultr LA Reality`
- `🐟 漏网之鱼` -> `自建 Vultr LA Reality`
- `🇺🇲 美国节点` -> `自建 Vultr LA Reality`
- `💬 Ai平台` -> `🇺🇲 美国节点`
- `📹 油管视频` -> `🇺🇲 美国节点`
- `🎥 奈飞视频` -> dedicated US streaming node selection
- `🎮 游戏平台` -> `DIRECT`
- `🎯 全球直连` -> `DIRECT`
- `🍎 苹果服务` -> `DIRECT`
- `Ⓜ️ 微软服务` -> `DIRECT`

Practical result:

- Apple TV YouTube high-bitrate `3840x2160@60` playback is smooth on the current
  home routing path.
- IPPure now sees the home exit as `45.32.87.131` in Los Angeles with a `37%`
  neutral score, down from the previous extreme-risk result on the old exit.
- IPPure VPN trace reports no IP leak.
- DNS leak testing no longer shows domestic resolver exits; DNS resolver exits
  are now Vultr/Los Angeles adjacent.
- WebRTC testing no longer exposes the local public address through the Chinese
  STUN checks; those checks now see the Vultr exit.

R4S DNS is intentionally split: default external resolution uses Cloudflare and
Google DoH, while China, Apple, and Microsoft direct-routing domains keep
domestic DNS policy where stable local CDN answers matter.

## Maintenance Flow

Most routine work should follow this model:

```text
Change public rule intent
  -> edit GitHub rule files or SharedRules.dconf
  -> regenerate or update the full profile
  -> publish the full profile to Cloudflare R2
  -> clients update from their R2 URLs
```

Use this decision table:

- Change a public routing rule: edit this repository.
- Change shared rule order: edit `SharedRules.dconf`.
- Change fake-ip compatibility behavior: edit `OpenClashFakeIPFilter.list`, then
  copy the same entries into the R4S hosted OpenClash profile on R2.
- Change a complete client profile behavior that is not public-safe source:
  update the generated profile on R2.
- Change subscriptions, nodes, passwords, or private parameters: edit the local
  private template/source, regenerate the full profile, and upload it to R2.
- Diagnose a live issue: temporary R4S-side edits are fine, but successful fixes
  must be written back to this repo and/or the R2 profile.

Now that R4S uses R2 distribution, normal day-to-day maintenance should usually
be only:

- edit GitHub public rules, or
- update the appropriate full profile on R2,

then wait for R4S OpenClash and iPhone Surge to update from their URLs. Only
subscription or private-node changes should require touching private templates.

## Current R4S Status

Verified after the R4S main-router migration on 2026-06-02:

- R4S LAN address: `192.168.0.1`.
- R4S WAN address: DHCP from upstream, currently `192.168.1.2/24`.
- R4S default route: upstream ISP gateway `192.168.1.1`.
- R4S is the DHCP authority for `192.168.0.0/24`.
- TP-Link TL-R479GP-AC management address: `192.168.0.2`.
- R4S OpenClash runtime file: `/etc/openclash/r2s-surge.yaml`.
- R4S source profile path: `/etc/openclash/config/r2s-surge.yaml`.
- R4S has an enabled subscription named `r2s-surge` pointed at the public R2
  host.
- `auto_update=1`, appointment mode is enabled, and cron pulls the subscription
  every day at 04:00.
- The running OpenClash file is still locally generated by OpenClash, with
  custom fake-ip filters merged in.
- The R2-hosted profile includes the Vultr LA Reality node and the
  IPPure/DNS/WebRTC leak-test routing fixes.
- The current local runtime also includes a Netflix stability adjustment that
  pins Netflix to a dedicated US streaming path; keep this behavior when the
  generated R2 profile is next refreshed.
- The migration backup is on the R4S at
  `/etc/openclash/backup/r2-migration-20260521-163946`.

R4S is now R2-backed for profile delivery. Do not keep long-term manual edits in
`/etc/openclash/config/r2s-surge.yaml`; put public-safe rule intent in this repo
and generated full profile changes in R2.

To check that R4S is still using R2 distribution:

```sh
uci get openclash.config.config_path
uci get openclash.config.auto_update
uci get openclash.config.auto_update_time
uci get openclash.@config_subscribe[0].enabled
sha256sum /etc/openclash/config/r2s-surge.yaml
crontab -l | grep openclash.sh
```

Compare the local source profile hash with the current R2-hosted profile. They
will differ between an R2 profile update and the next scheduled R4S pull; after
the 04:00 auto-update they should match again.

## R4S R2 Migration Notes

Completed on 2026-05-21:

- Backed up `/etc/openclash/config/r2s-surge.yaml`,
  `/etc/openclash/r2s-surge.yaml`, and `/etc/config/openclash`.
- Downloaded the R2-hosted R4S profile to a temporary file on the R4S.
- Syntax-tested the temporary profile with the OpenClash/Mihomo core.
- Confirmed required fake-ip filters were present.
- Replaced `/etc/openclash/config/r2s-surge.yaml` with the R2-hosted profile.
- Restarted OpenClash and verified DNS behavior, ports, process health, and
  basic browsing.
- Enabled OpenClash subscription auto-update for 04:00 every day.

Recovery path: restore the backed-up source profile and UCI config from the
backup directory, then restart OpenClash. Keep `custom_fakeip_filter=1` unless
there is a specific reason to move those compatibility entries entirely into
the hosted profile and stop using OpenClash's custom merge behavior.

## Repository Files

- `SharedRules.dconf`: public shared rule intent promoted from the current
  stable R4S profile. It is split into local overlay/routing-safeguard rules
  and ACL4SSR mirror rules.
- Top-level `.list` files: local public-safe rule overlays.
- `ACL4SSR/`: mirrored upstream ACL4SSR rule files used by local profiles.
- `GoogleFCMProxyOverlay.list`: local overlay that forces Google FCM traffic to
  the proxy path before ACL4SSR's Google FCM and Google CN rules can match it.
- `OpenClashFakeIPFilter.list`: public-safe fake-ip compatibility entries that
  must also be reflected in the R4S hosted profile.
- `scripts/sync-acl4ssr.sh`: refreshes mirrored ACL4SSR files.
- `.github/workflows/sync-acl4ssr.yml`: daily ACL4SSR mirror sync at 04:15
  Asia/Shanghai.
- `docs/home-network-overview.md`: more detailed network topology notes.

## Network Summary

Home LAN clients get DHCP, gateway, and DNS from the R4S.

- R4S main router: `192.168.0.1`
- TP-Link AP/AC/switch: `192.168.0.2`
- Upstream ISP gateway / ONT: `192.168.1.1`
- R4S WAN: DHCP on `eth0`, currently `192.168.1.2/24`
- R4S DNS entry point: dnsmasq forwarding into OpenClash DNS
- OpenClash DNS port: `7874`
- OpenClash controller port: `9090`
- Fake-IP range: `198.18.0.0/16`

Do not re-enable DHCP or NAT on the TP-Link while the R4S is the main router.
If the ISP gateway is later changed to bridge mode, update the R4S WAN access
model and this document together.

## Compatibility Notes

Diablo IV China resources need real DNS answers for the NetEase Leihuo CDN. The
current working fake-ip filter entries are:

```text
+.leihuo.netease.com
+.necdn.leihuo.netease.com
+.163jiasu.com
+.ctlcdn.cn
```

These are DNS compatibility entries, not ordinary routing rules. Keep them in
`OpenClashFakeIPFilter.list` and in the R4S hosted profile's
`dns.fake-ip-filter`. The matching direct-routing overlay lives in
`BattleNetCN.list`.

Do not broaden this to `+.netease.com` unless a real failure requires it.

Google FCM (`mtalk.google.com`) should not be treated as a China-direct Google
service on the R4S. Keep `GoogleFCMProxyOverlay.list` before the ACL4SSR
Google FCM and Google CN rules in `SharedRules.dconf`, so FCM uses the normal
proxy path without modifying the mirrored ACL4SSR files.

Apple and Microsoft direct groups need stable real-IP DNS answers. The R4S
hosted profile keeps a `dns.nameserver-policy` for Apple and Microsoft domains,
pointing them at domestic DNS resolvers. Without that policy, these direct
groups may fall back to `dns.google` or `cloudflare-dns.com`, producing noisy
`dns resolve failed` warnings before the traffic can dial.

IPPure and similar leak-test endpoints should be forced through the normal proxy
path when testing an exit node. Otherwise helper APIs such as `myip.ipip.net` or
STUN probes can be matched by domestic direct rules and contaminate the result
with the local public address. Keep these narrow leak-test routing overrides in
the generated R4S profile rather than broadening China-domain behavior.

## Quick Checks

From a Mac on the LAN:

```sh
route -n get default
scutil --dns
ping 192.168.0.1
ping 192.168.0.2
curl -I http://192.168.0.2
```

From the R4S:

```sh
ip route
uci show network
uci show dhcp
uci show openclash
ps w | grep -Ei 'openclash|clash|mihomo|dnsmasq'
tail -n 80 /tmp/openclash.log
```

For Cloudflare R2:

```sh
wrangler whoami
wrangler r2 bucket info surge-configs
```

## Maintenance Rules

- Keep `SharedRules.dconf` as the source of truth for public shared rule order.
- Keep R2 as the full-profile delivery channel for clients.
- Keep private subscriptions and generated full profiles out of this public
  repository.
- Keep R4S and iPhone Surge aligned in rule intent.
- Keep Mac/Surge hosted config as standby.
- Keep Hong Kong policy groups and Hong Kong nodes excluded unless the routing
  policy changes.
- Keep fake-ip compatibility filters narrow and documented.
