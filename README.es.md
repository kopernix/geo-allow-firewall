# geo-allow-firewall

Allowlist por país para tráfico web (80/443) usando **ipset** + **iptables**.

Construye un `ipset` allowlist (por defecto `geo_allow`) a partir de rangos IPv4 agregados por país y lo aplica con una chain de iptables (`GEO_ALLOW_ONLY`) en los puertos **80/443**.

## Para qué sirve
Cuando estás bajo un ataque distribuido (botnet), banear por IP puede ser inútil o muy ruidoso. Si tu servicio está pensado para un conjunto limitado de países, una allowlist por país reduce el ruido rápidamente.

## Características
- Usa **ipset** (`hash:net`) para escalar bien.
- Actualización atómica con `ipset swap` (sin “ventanas raras”).
- Allowlists manuales opcionales:
  - Por país: `/etc/ipset/geo_<cc>_manual.txt`
  - Global: `/etc/ipset/geo_allow_extra.txt`
- Idempotente: puedes ejecutarlo varias veces sin duplicar reglas.
- Incluye instalador y desinstalador.

## Requisitos
- Linux con `iptables` e `ipset`
- `curl`, `grep`, `awk`
- Permisos de root

Probado en Debian 10 con `iptables v1.8.x (nf_tables)`.

## Instalación
```bash
sudo ./install.sh es pt ie
```

Instalar sin cron:
```bash
sudo ./install.sh --no-cron es pt ie
```

## Actualizar manualmente
```bash
sudo /usr/local/sbin/geo-allow-update.sh es pt ie
```
o

```bash
sudo iptables -F GEO_ALLOW_ONLY 2>/dev/null || true
sudo iptables -X GEO_ALLOW_ONLY 2>/dev/null || true
sudo ipset destroy geo_allow 2>/dev/null || true
sudo ipset destroy geo_allow_tmp 2>/dev/null || tru
```
y borra cron

## Ficheros de allowlist
- Por país:
  - `/etc/ipset/geo_es_manual.txt`
  - `/etc/ipset/geo_pt_manual.txt`
  - `/etc/ipset/geo_ie_manual.txt`
- Extra global:
  - `/etc/ipset/geo_allow_extra.txt`

Un CIDR por línea. Comentarios con `#`.

## Verificación
Comprobar si una IP está permitida:
```bash
ipset test geo_allow 8.8.8.8 && echo OK || echo BLOCKED
```

Ver contadores:
```bash
iptables -L GEO_ALLOW_ONLY -n -v
```

## Rollback / Desinstalar
```bash
sudo ./uninstall.sh
```

## Notas
- Esto filtra a nivel L3/L4. No entiende hostnames ni URLs.
- Los rangos por país se descargan de ipdeny (lista agregada):
  - `https://www.ipdeny.com/ipblocks/data/aggregated/<cc>-aggregated.zone`
- Las asignaciones GeoIP cambian; es recomendable dejar el cron de actualización.

## TODO / Roadmap

- [ ] Persistencia al reinicio sin necesidad de ejecutar `install.sh` (systemd service/timer o iptables/ipset-persistent).
- [ ] Modo alternativo: denylist por países (bloquear países concretos en vez de allowlist).

## Licencia
MIT
