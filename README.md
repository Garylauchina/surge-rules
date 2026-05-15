# Surge Rules

Public-safe rule sets for Surge. Keep proxy subscriptions, API keys, controller
addresses, LAN addresses, and device information out of this repo.

The top-level files are local overlays. The `ACL4SSR/` directory mirrors the
upstream ACL4SSR rule files currently used by the local Surge profiles, so Mac
and iOS can load rule content from this repository.

`scripts/sync-acl4ssr.sh` mirrors the upstream ACL4SSR files listed in the
current Surge profiles. GitHub Actions runs it every day at 04:15 Asia/Shanghai
and commits changes only when the mirrored files differ from upstream.

Overlay usage:

```ini
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/AI.list,💬 Ai平台,update-interval=3600
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/YouTube.list,📹 油管视频,update-interval=3600
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/BattleNetCN.list,🎯 全球直连,update-interval=3600
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/TikTokOverlay.list,🎵 TikTok,update-interval=3600
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/TerminusEmby.list,🇸🇬🇺🇲 新美节点,update-interval=3600
```

Place overlay `RULE-SET` lines before broad mirrored ACL4SSR rule sets so local
overrides take priority.
