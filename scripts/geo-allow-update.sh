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
  cc=""); then
    true
  fi

  # Merge per-country manual ranges if there are any valid lines
  if [[ -f "$manual" ]]; then
    matches=$(grep -Ev '^
  # Download country ranges: wrap pipeline in an if so the script doesn't exit when grep finds no matches
  if curl -fsSL "$url" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' | while read -r net; do
       ipset add "$ALLOW_TMP" "$net" -exist
     done; then
    true
  fi

  # Merge per-country manual ranges if there are any valid lines
  if [[ -f "$manual" ]]; then
    matches=$(grep -Ev '^
  fi

EXTRA="/etc/ipset/geo_allow_extra.txt"

if [[ -f "$EXTRA" ]]; then
  matches=$(grep -Ev '^
  fi

# Ensure the iptables rules are set
iptables -N "$CHAIN" 2>/dev/null || true
iptables -F "$CHAIN"
iptables -A "$CHAIN" -m set --match-set "$ALLOW_SET" src -j ACCEPT
iptables -A "$CHAIN" -j DROP

for p in "${PORTS[@]}"; do
  if ! iptables -C INPUT -p tcp --dport "$p" -j "$CHAIN" >/dev/null 2>&1; then
    iptables -I INPUT 1 -p tcp --dport "$p" -j "$CHAIN"
  fi
done

echo "OK: geo_allow updated for: ${COUNTRIES[*]}"