#!/usr/bin/env bash
# uninstall-postgres.sh
# Removes PostgreSQL 17, PostGIS, and postgres_exporter.
# Pass --purge-data to also delete /var/lib/postgresql.
#
# Usage: sudo ./uninstall-postgres.sh [--purge-data]

set -euo pipefail

PURGE_DATA=false
[[ "${1:-}" == "--purge-data" ]] && PURGE_DATA=true

log() { echo ""; echo "==> $*"; }
ok()  { echo "    [ok]   $*"; }

[[ $EUID -ne 0 ]] && { echo "ERROR: Run with sudo." >&2; exit 1; }

log "Removing postgres_exporter"
for f in postgres_exporter; do
  systemctl stop "$f"    2>/dev/null || true
  systemctl disable "$f" 2>/dev/null || true
  rm -f "/etc/systemd/system/${f}.service" "/etc/default/${f}"
done
rm -f /usr/local/bin/postgres_exporter
userdel postgres_exporter 2>/dev/null || true
systemctl daemon-reload
ok "postgres_exporter removed."

log "Removing PostgreSQL"
systemctl stop postgresql    2>/dev/null || true
systemctl disable postgresql 2>/dev/null || true
apt-get remove -y postgresql-18 postgresql-18-postgis-3 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true
rm -f /etc/apt/sources.list.d/pgdg.list

if $PURGE_DATA; then
  rm -rf /var/lib/postgresql
  ok "PostgreSQL data directory removed."
fi

ok "PostgreSQL removed."
echo ""
$PURGE_DATA && echo "Done. All data removed." || echo "Done. Data preserved. Pass --purge-data to also remove /var/lib/postgresql."