# Private Exit Policy

Last verified: 2026-07-01

## Endpoint Roles

| Endpoint | Monthly quota | Billing model | Role |
| --- | ---: | --- | --- |
| Vultr Los Angeles | 1 TB | Monthly | Primary daily and primary US exit |
| BitsFlow Tokyo | 600 GB | Annual prepaid | Low-latency manual/last fallback |
| Bandwagon GIG-2 Los Angeles | 1 TB | Quarterly prepaid | Secondary daily and secondary US exit |
| 红杏 | Metered | Usage based | Manual cold standby only |

Vultr stays first because it has the best verified combination of throughput,
stability, US egress location, and operational flexibility. Bandwagon is second
for general traffic and US traffic because its 1 TB quota is better suited to
household video fallback. Tokyo is kept for low-latency manual use and last
fallback because its 600 GB quota can be consumed quickly by video traffic.

On 2026-07-01, BitsFlow reported 70% monthly quota usage before the
2026-07-18 reset. Until the reset, Tokyo should not be used as an automatic
high-probability fallback for large household traffic.

## Automatic Groups

- `♻️ 私有主备`: Vultr first, Bandwagon second, Tokyo last.
- `🇺🇸 美国主备`: Vultr first, Bandwagon second.
- `🇯🇵 日本低延迟`: Tokyo Hysteria2 first, Tokyo TCP alternative second.
- `🚀 节点选择`: manual entry point for the three automatic groups, individual
  private paths, 红杏 cold standby, and `DIRECT`.

Automatic groups use ordered fallback rather than load balancing. This keeps a
stable egress IP for each service, preserves streaming regions and account risk
controls, and avoids consuming several quotas unpredictably.

## Service Mapping

- US-specific: AI, Netflix, TikTok, and generic foreign media use
  `🇺🇸 美国主备`.
- General proxy traffic: YouTube, X, Telegram, Google FCM, OneDrive, Emby, and
  final unmatched traffic use `♻️ 私有主备`.
- Apple, Microsoft core services, games, and China services remain direct
  unless a narrow verified exception requires proxying.

## Client Differences

The R4S uses Vultr Reality, Bandwagon Reality/Hysteria2, and Tokyo
Trojan/Hysteria2. The iPhone Surge profile uses protocols supported by Surge:
Vultr Trojan/Hysteria2, Bandwagon Hysteria2, and Tokyo Trojan/Hysteria2.

All private VPS endpoint addresses must have explicit `DIRECT,no-resolve`
rules before general proxy rules. This prevents proxy recursion.

红杏 must not appear in automatic testing, fallback, or load-balancing groups.
悠兔 remains excluded from active R4S, iOS, and Mac paths.

Private node credentials and complete generated profiles belong in Cloudflare
R2 or private local sources, not in this repository.
