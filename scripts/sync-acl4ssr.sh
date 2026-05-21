#!/usr/bin/env bash
set -euo pipefail

source_ref="${SOURCE_REF:-master}"
base_url="https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/${source_ref}"

files=(
  "Clash/Apple.list"
  "Clash/BanAD.list"
  "Clash/BanProgramAD.list"
  "Clash/Bing.list"
  "Clash/ChinaCompanyIp.list"
  "Clash/ChinaDomain.list"
  "Clash/ChinaMedia.list"
  "Clash/Download.list"
  "Clash/GoogleCN.list"
  "Clash/LocalAreaNetwork.list"
  "Clash/Microsoft.list"
  "Clash/OneDrive.list"
  "Clash/ProxyGFWlist.list"
  "Clash/ProxyMedia.list"
  "Clash/Ruleset/AI.list"
  "Clash/Ruleset/Bahamut.list"
  "Clash/Ruleset/Bilibili.list"
  "Clash/Ruleset/BilibiliHMT.list"
  "Clash/Ruleset/Epic.list"
  "Clash/Ruleset/GoogleFCM.list"
  "Clash/Ruleset/NetEaseMusic.list"
  "Clash/Ruleset/Netflix.list"
  "Clash/Ruleset/Nintendo.list"
  "Clash/Ruleset/OpenAi.list"
  "Clash/Ruleset/Origin.list"
  "Clash/Ruleset/Sony.list"
  "Clash/Ruleset/Steam.list"
  "Clash/Ruleset/SteamCN.list"
  "Clash/Ruleset/TikTok.list"
  "Clash/Ruleset/YouTube.list"
  "Clash/Telegram.list"
  "Clash/UnBan.list"
)

for file in "${files[@]}"; do
  destination="ACL4SSR/${file}"
  temporary="${destination}.tmp"

  mkdir -p "$(dirname "${destination}")"
  curl --fail --silent --show-error --location --retry 3 --connect-timeout 10 --max-time 60 \
    "${base_url}/${file}" \
    --output "${temporary}"

  if [[ ! -s "${temporary}" ]]; then
    echo "Downloaded empty rule file: ${file}" >&2
    exit 1
  fi

  mv "${temporary}" "${destination}"
  echo "synced ${destination}"
done

google_cn_file="ACL4SSR/Clash/GoogleCN.list"
google_cn_temporary="${google_cn_file}.tmp"
grep -vE '^DOMAIN-SUFFIX,(alt[1-8]-)?mtalk\.google\.com$' "${google_cn_file}" > "${google_cn_temporary}"
mv "${google_cn_temporary}" "${google_cn_file}"

cat > "ACL4SSR/Clash/Ruleset/GoogleFCM.list" <<'RULES'
# Google FCM local override
#
# The hosted R4S OpenClash profile currently maps GoogleFCM_list to a
# DIRECT-first policy group. Direct mtalk.google.com egress times out on the
# home network, so keep this provider intentionally no-op and let FCM domains
# fall through to ProxyGFWlist's google.com rule.
DOMAIN,google-fcm-disabled.invalid
RULES

echo "applied local Google FCM routing override"
echo "Synced ${#files[@]} ACL4SSR files from ${base_url}"
