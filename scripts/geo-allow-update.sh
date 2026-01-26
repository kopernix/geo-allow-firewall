#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   geo-allow-update.sh es pt ie
#   geo-allow-update.sh es
# If no args -> default to ES only
#
# This script:
# - Downloads aggregated IPv4 ranges per country from ipdeny
# - Merges optional per-country manual ranges:
#     /etc/ipset/geo_<cc>_manual.txt
# - Merges optional global extra allowlist:
#     /etc/ipset/geo_allow_extra.txt
# - Atomically swaps into ipset: geo_allow
# - Ensures iptables chain GEO_ALLOW_ONLY is present and hooked to INPUT:80/443

if [[ "$#" -ge 1 ]]; then
  COUNTRIES=("$@")
else
  COUNTRIES=("es")
fi

ALLOW_SET="geo_allow"
ALLOW_TMP="geo_allow_tmp"
CHAIN="GEO_ALLOW_ONLY"
PORTS=(80 443)

BASE_URL="https://www.ipdeny.com/ipblocks/data/aggregated"

mkdir -p /etc/ipset

ipset create "$ALLOW_SET" hash:net -exist
ipset create "$ALLOW_TMP" hash:net -exist

ipset flush "$ALLOW_TMP"

for cc in "${COUNTRIES[@]}"; do
  cc="","$(echo "$cc" | tr '[:upper:]' '[:lower:]')"
  url="${BASE_URL}/${cc}-aggregated.zone"
  manual="/etc/ipset/geo_${cc}_manual.txt"

  # Download country ranges; tolerate empty or missing results
  if curl -fsSL "$url" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' | while read -r net; do
       ipset add "$ALLOW_TMP" "$net" -exist
     done; then
    :
  fi

  # Merge per-country manual ranges if there are any valid lines
  if [[ -f "$manual" ]]; then
    if grep -Ev '^\s*($|#)' "$manual" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' 2>/dev/null | while read -r net; do
         ipset add "$ALLOW_TMP" "$net" -exist
       done; then
      :
    fi
  fi
done

EXTRA="/etc/ipset/geo_allow_extra.txt"

if [[ -f "$EXTRA" ]]; then
  if grep -Ev '^\s*($|#)' "$EXTRA" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' 2>/dev/null | while read -r net; do
       ipset add "$ALLOW_TMP" "$net" -exist
     done; then
    :
  fi
fi

ipset swap "$ALLOW_TMP" "$ALLOW_SET"
ipset flush "$ALLOW_TMP"

iptables -N "$CHAIN" 2>/dev/null || true
iptables -F "$CHAIN"
ipset -A "$CHAIN" -m set --match-set "$ALLOW_SET" src -j ACCEPT
iptables -A "$CHAIN" -j DROP

for p in "${PORTS[@]}"; do
  if ! iptables -C INPUT -p tcp --dport "$p" -j "$CHAIN" >/dev/null 2>&1; then
    iptables -I INPUT 1 -p tcp --dport "$p" -j "$CHAIN"
  fi
done

echo "OK: geo_allow updated for: ${COUNTRIES[*]}"