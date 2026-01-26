#!/usr/bin/env bash
set -euo pipefail

# Installer for geo-allow-firewall
# - Installs geo-allow-update.sh into /usr/local/sbin
# - Creates /etc/ipset and example allowlist files (if missing)
# - Optionally installs a cron job (daily 04:20) with the countries you pass
#
# Usage:
#   sudo ./install.sh es pt ie
#   sudo ./install.sh es
#   sudo ./install.sh --no-cron es pt ie

NO_CRON=0
if [[ "
${1:-}" == "--no-cron" ]]; then
  NO_CRON=1
  shift
fi

COUNTRIES=("$@")
if [[ "${#COUNTRIES[@]}" -eq 0 ]]; then
  COUNTRIES=("es")
fi

SCRIPT_SRC="";cd "
$(dirname "
${BASH_SOURCE[0]}"
)" && pwd)/scripts/geo-allow-update.sh"
SCRIPT_DST="/usr/local/sbin/geo-allow-update.sh"

if [[ ! -f "$SCRIPT_SRC" ]]; then
  echo "ERROR: source script not found: $SCRIPT_SRC" >&2
  exit 1
fi

mkdir -p /usr/local/sbin
install -m 0755 "$SCRIPT_SRC" "$SCRIPT_DST"

mkdir -p /etc/ipset

# Create example files if missing (do not overwrite)
for cc in "${COUNTRIES[@]}"; do
  cc="
$(echo "$cc" | tr '[:upper:]' '[:lower:]')
"
  f="/etc/ipset/geo_${cc}_manual.txt"
  if [[ ! -f "$f" ]]; then
    cat >"$f" <<EOF
# Manual ranges for country: ${cc}
# One CIDR per line. Examples:
# 92.177.0.0/16
EOF
    chmod 0644 "$f"
  fi
done

EXTRA="/etc/ipset/geo_allow_extra.txt"
if [[ ! -f "$EXTRA" ]]; then
  cat >"$EXTRA" <<'EOF'
# Global allowlist ranges (always allowed, regardless of country list)
# One CIDR per line. Examples:
# 92.177.0.0/16
# 185.247.124.83/32
EOF
  chmod 0644 "$EXTRA"
fi

# Try to run once to populate ipset + iptables (non-fatal)
if ! "$SCRIPT_DST" "${COUNTRIES[@]}"; then
  echo "Warning: initial update failed. The script was installed but the initial IP update failed." >&2
  echo "You can re-run: $SCRIPT_DST ${COUNTRIES[*]}" >&2
fi

if [[ "$NO_CRON" -eq 0 ]]; then
  CRON_FILE="/etc/cron.d/geo-allow-update"
  # Use 04:20 local time
  printf "20 4 * * * root %s %s >/dev/null 2>&1\n" "$SCRIPT_DST" "${COUNTRIES[*]}" > "$CRON_FILE"
  chmod 0644 "$CRON_FILE"
  echo "Installed cron: $CRON_FILE"
else
  echo "Cron not installed (--no-cron)."
fi

cat <<EOF

Installed:
- Script: $SCRIPT_DST
- ipset allowlist: geo_allow
- iptables chain: GEO_ALLOW_ONLY (hooked to INPUT tcp/80 and tcp/443)

Manual allowlists:
- Per-country: /etc/ipset/geo_<cc>_manual.txt
- Global extra: /etc/ipset/geo_allow_extra.txt

EOF
