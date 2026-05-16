# Surge Rules

Public-safe rule sets for Surge. Keep proxy subscriptions, API keys, controller
addresses, LAN addresses, and device information out of this repo.

The top-level files are local overlays. The `ACL4SSR/` directory mirrors the
upstream ACL4SSR rule files currently used by the local Surge profiles, so Mac
and iOS can load rule content from this repository.

`SharedRules.dconf` is the shared hosted `[Rule]` layer used by Mac, iOS, and
router profiles. Device-specific settings and proxy subscription wiring stay in
the local profile; only the rule order is centralized here.

`scripts/sync-acl4ssr.sh` mirrors the upstream ACL4SSR files listed in the
current Surge profiles. GitHub Actions runs it every day at 04:15 Asia/Shanghai
and commits changes only when the mirrored files differ from upstream.

Overlay usage:

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

Place overlay `RULE-SET` lines before broad mirrored ACL4SSR rule sets so local
overrides take priority.

Profiles can also load the shared rule layer directly:

```ini
[Rule]
#!include https://raw.githubusercontent.com/Garylauchina/surge-rules/main/SharedRules.dconf
```

Policy notes:

- `🇸🇬🇺🇲 新美节点` is the preferred main proxy channel.
- Hong Kong policy groups and Hong Kong nodes are intentionally excluded from local profiles.
- Keep subscription regex filters excluding Hong Kong node names so Hong Kong nodes do not re-enter auto, fallback, load-balance, or manual groups.

Terminus+ notes:

- Prefer `7056789.xyz` with HTTPS 443.
- Keep `🎬 TerminusEmby` on `DIRECT` unless the direct path degrades.
- `c3.bjdekk.cn` is intentionally not included because it was unavailable in local tests.
