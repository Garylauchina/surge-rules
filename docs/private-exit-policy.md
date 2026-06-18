# Private Exit Policy

Last verified: 2026-06-18

The R4S profile currently has three self-hosted VPS endpoints:

- Vultr remains the automatic daily exit.
- Bandwagon GIG-2 is available through the manual
  `Bandwagon GIG-2 候选` group.
- Within the Bandwagon group, Hysteria2 is preferred over Reality based on the
  current peak-hour tests.
- The Tokyo VPS is available through the manual `日本 VPS 候选` group.
- Within the Tokyo group, Hysteria2 is the default and Trojan TLS is the TCP
  alternative. The single sing-box service is intentionally used to keep
  memory consumption low.
- 红杏 remains manual cold standby and must not be placed in automatic testing,
  fallback, or load-balancing groups.
- 悠兔 remains excluded from active R4S, iOS, and Mac paths.

All private VPS endpoint addresses must have explicit `DIRECT,no-resolve`
rules before general proxy rules. This prevents a private proxy connection from
being sent through another proxy endpoint.

Private node credentials and complete generated profiles belong in Cloudflare
R2 or private local sources, not in this repository.
