#!/usr/bin/env bash
set -euo pipefail

# Uninstaller for geo-allow-firewall
# - Removes iptables hooks for 80/443
# - Deletes GEO_ALLOW_ONLY chain
# - Deletes geo_allow ipset sets
# - Removes installed script and cron file
#
# Usage:
#   sudo ./uninstall.sh

CHAIN="GEO_ALLOW_ONLY"
SET="geo_allow"
TMP="geo_allow_tmp"
SCRIPT_DST="/usr/local/sbin/geo-allow-update.sh"
CRON_FILE="/etc/cron.d/geo-allow-update"

# Remove hooks (ignore errors)
iptables -D INPUT -p tcp --dport 80  -j "$CHAIN" 2>/dev/null || true
iptables -D INPUT -p tcp --dport 443 -j "$CHAIN" 2>/dev/null || true

# Remove chain
iptables -F "$CHAIN" 2>/dev/null || true
iptables -X "$CHAIN" 2>/dev/null || true

# Remove sets
ipset destroy "$SET" 2>/dev/null || true
ipset destroy "$TMP" 2>/dev/null || true

# Remove files
rm -f "$SCRIPT_DST" "$CRON_FILE"

cat <<EOF
Removed:
- iptables chain $CHAIN and hooks for ports 80/443
- ipset sets: $SET, $TMP
- script: $SCRIPT_DST
- cron: $CRON_FILE

Note:
- Manual files under /etc/ipset/ were NOT deleted (kept by design).
EOF
