# geo-allow-firewall

Country-based allowlist for web traffic (80/443) using **ipset** + **iptables**.

It builds an allowlist `ipset` (default name: `geo_allow`) from aggregated IPv4 ranges per country and enforces it via an iptables chain (`GEO_ALLOW_ONLY`) on ports **80/443**.

## Why
When you're under a distributed botnet attack, per-IP bans can become noisy. If your service is intended for a limited set of countries, a country allowlist can reduce the attack surface quickly.

## Features
- Uses **ipset** (`hash:net`) for scale and speed.
- Atomic updates via `ipset swap` (minimal traffic disruption).
- Optional manual allowlists:
  - Per country: `/etc/ipset/geo_<cc>_manual.txt`
  - Global: `/etc/ipset/geo_allow_extra.txt`
- Idempotent: safe to run multiple times.
- Installer and uninstaller included.

## Requirements
- Linux with `iptables` and `ipset` available
- `curl`, `grep`, `awk` (standard)
- Root privileges

Tested on Debian 10 with `iptables v1.8.x (nf_tables)`.

## Install
```bash
sudo ./install.sh es pt ie
```

Install without cron:
```bash
sudo ./install.sh --no-cron es pt ie
```

## Update manually
```bash
sudo /usr/local/sbin/geo-allow-update.sh es pt ie
```

## Allowlist files
- Per-country:
  - `/etc/ipset/geo_es_manual.txt`
  - `/etc/ipset/geo_pt_manual.txt`
  - `/etc/ipset/geo_ie_manual.txt`
- Global extra:
  - `/etc/ipset/geo_allow_extra.txt`

One CIDR per line. Comments start with `#`.

## Verify
Check if an IP is allowed:
```bash
ipset test geo_allow 8.8.8.8 && echo OK || echo BLOCKED
```

View counters:
```bash
iptables -L GEO_ALLOW_ONLY -n -v
```

## Rollback / Uninstall
```bash
sudo ./uninstall.sh
```

## Notes / Caveats
- This filters at L3/L4. It does **not** understand hostnames or URLs.
- Country IP ranges are fetched from ipdeny aggregated lists:
  - `https://www.ipdeny.com/ipblocks/data/aggregated/<cc>-aggregated.zone`
- GeoIP and IP allocations can change; keep the cron update enabled.

## TODO / Roadmap

- [ ] Persistence across reboot without running `install.sh` (systemd service/timer or iptables/ipset-persistent).
- [ ] Optional denylist mode (block selected countries instead of allowlisting).


## License
MIT
