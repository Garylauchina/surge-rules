# Surge Rules

Public-safe overlay rule sets for Surge. Keep proxy subscriptions, API keys,
controller addresses, LAN addresses, and device information out of this repo.

Surge usage:

```ini
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/AI.list,💬 Ai平台,update-interval=3600
RULE-SET,https://raw.githubusercontent.com/Garylauchina/surge-rules/main/YouTube.list,📹 油管视频,update-interval=3600
```

Place these `RULE-SET` lines before broad ACL4SSR rule sets so local overlays
take priority.
