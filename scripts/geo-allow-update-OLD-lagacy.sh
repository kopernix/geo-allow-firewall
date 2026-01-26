#!/usr/bin/env bash
set -euo pipefail

# OLD Legacy simple verion
#
# Usage:
#   geo-allow-update.sh es pt ie
#   geo-allow-update.sh es
# If no args -> default to ES only

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
  cc="$(echo "$cc" | tr '[:upper:]' '[:lower:]')"
  url="${BASE_URL}/${cc}-aggregated.zone"
  manual="/etc/ipset/geo_${cc}_manual.txt"

  curl -fsSL "$url" \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' \
    | while read -r net; do
        ipset add "$ALLOW_TMP" "$net" -exist
      done

  if [[ -f "$manual" ]]; then
    grep -Ev '^\s*($|#)' "$manual" \
      | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' \
      | while read -r net; do
          ipset add "$ALLOW_TMP" "$net" -exist
        done
  fi
done

EXTRA="/etc/ipset/geo_allow_extra.txt"

if [[ -f "$EXTRA" ]]; then
  grep -Ev '^\s*($|#)' "$EXTRA" \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' \
    | while read -r net; do
        ipset add "$ALLOW_TMP" "$net" -exist
      done
fi

ipset swap "$ALLOW_TMP" "$ALLOW_SET"
ipset flush "$ALLOW_TMP"

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

