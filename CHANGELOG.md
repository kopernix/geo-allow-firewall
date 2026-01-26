# Changelog
All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-01-26
### Added
- Country allowlist via ipset (ipdeny aggregated ranges)
- Optional manual allowlists per country and global extra file
- iptables chain GEO_ALLOW_ONLY hooked to 80/443
- Installer and uninstaller scripts

## [0.1.0] - 2026-01-26
### Added
- Initial release: country allowlist using ipset + iptables for ports 80/443.
- Installer/uninstaller.
- Per-country and global manual allowlists.
