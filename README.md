# Surge Rules

Read this first when maintaining the home proxy rules. This repository is the
public-safe source for shared rule intent and maintenance notes. Do not commit
proxy subscriptions, API tokens, controller secrets, dashboard passwords,
generated R2 object keys, or private device credentials.

## Architecture

The proxy system has one public rule source, one hosted configuration delivery
layer, and two active clients.

```text
GitHub: Garylauchina/surge-rules
  Public-safe rule sets, shared rule order, fake-ip compatibility notes,
  and operational documentation.

        ->

Cloudflare R2: surge-configs
  Hosts generated full client profiles behind update URLs.
  This solves client-side config fetching; it is not the source of truth.

        ->

Home client: R4S OpenClash side gateway
  Used on the home LAN.
  Provides gateway, DNS, fake-ip, transparent proxy, and policy routing.

Away client: iPhone Surge
  Used when the phone is outside home.
  Pulls its hosted Surge profile URL from Cloudflare R2.
```

The key rule: GitHub stores public rules and docs; R2 stores generated full
profiles for clients to fetch. Keep private subscriptions and node parameters in
local private templates or client-side configuration sources, not in this repo.

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

After R4S fully moves to R2 distribution, normal day-to-day maintenance should
usually be only:

- edit GitHub public rules, or
- update the appropriate full profile on R2,

then wait for R4S OpenClash and iPhone Surge to update from their URLs. Only
subscription or private-node changes should require touching private templates.

## Current R4S Status

Verified on 2026-05-21:

- R4S address: `192.168.0.4`.
- R4S OpenClash runtime file: `/etc/openclash/r2s-surge.yaml`.
- R4S source profile path: `/etc/openclash/config/r2s-surge.yaml`.
- R4S has a subscription named `r2s-surge` pointed at the public R2 host.
- `auto_update=0`, so R4S is not yet automatically pulling R2 updates.
- The R4S local source profile differs from the current R2-hosted R4S profile.
- The running OpenClash file is locally generated, with custom fake-ip filters
  merged in.

So R4S is prepared for R2 distribution, but it is still effectively running
from a local cached source profile. Treat the R2-hosted R4S profile as the
transition target until a staged update is completed and verified.

To check whether R4S has fully moved to R2 distribution:

```sh
uci get openclash.config.config_path
uci get openclash.config.auto_update
uci get openclash.@config_subscribe[0].enabled
sha256sum /etc/openclash/config/r2s-surge.yaml
```

Compare the local source profile hash with the current R2-hosted profile. If
they differ, R4S is still on a local cached source even if the subscription URL
is configured.

## R4S R2 Transition Plan

Move R4S to R2 distribution in two phases.

1. Stage and verify manually.
   - Back up `/etc/openclash/config/r2s-surge.yaml`,
     `/etc/openclash/r2s-surge.yaml`, and `/etc/config/openclash`.
   - Download the R2-hosted R4S profile to a temporary file on the R4S.
   - Syntax-test the temporary profile with the OpenClash/Mihomo core.
   - Confirm required fake-ip filters are present.
   - Replace `/etc/openclash/config/r2s-surge.yaml` only after validation.
   - Restart OpenClash during a quiet window.
   - Verify DNS behavior, OpenClash logs, normal browsing, and game/resource
     loading.

2. Enable automation after stability.
   - Keep `custom_fakeip_filter=1` during the first successful R2-backed run.
   - After a stable day or two, enable OpenClash config auto-update at an
     off-hours time.
   - If anything breaks, restore the backed-up local source profile and restart
     OpenClash.

## Repository Files

- `SharedRules.dconf`: shared rule order for Mac, iOS, and router profiles.
- Top-level `.list` files: local public-safe rule overlays.
- `ACL4SSR/`: mirrored upstream ACL4SSR rule files used by local profiles.
- `OpenClashFakeIPFilter.list`: public-safe fake-ip compatibility entries that
  must also be reflected in the R4S hosted profile.
- `scripts/sync-acl4ssr.sh`: refreshes mirrored ACL4SSR files.
- `.github/workflows/sync-acl4ssr.yml`: daily ACL4SSR mirror sync at 04:15
  Asia/Shanghai.
- `docs/home-network-overview.md`: more detailed network topology notes.

## Network Summary

Home LAN clients get DHCP from the main router, but use the R4S as gateway and
DNS.

- Main router: `192.168.0.1`
- R4S side router: `192.168.0.4`
- R4S DNS entry point: dnsmasq forwarding into OpenClash DNS
- OpenClash DNS port: `7874`
- OpenClash controller port: `9090`
- Fake-IP range: `198.18.0.0/16`

Do not move DHCP authority from the main router or enable R4S DHCP unless the
network is being deliberately redesigned.

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

## Quick Checks

From a Mac on the LAN:

```sh
route -n get default
scutil --dns
ping 192.168.0.1
ping 192.168.0.4
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
