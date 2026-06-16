#!/usr/bin/env bash
# Rebuild every index in the application database on each startup, online.
#
# Why: glibc collation drift across a base-image rebuild can silently corrupt
# text btree indexes — the classic symptom is `WHERE col = 'foo-bar'` returning
# 0 rows even though the row exists, because the hyphen's collation weight
# shifted. REINDEX ... CONCURRENTLY rebuilds the indexes with the live
# collation and never takes a blocking lock (reads and writes continue), so it
# is safe to run on every deploy.
#
# This runs unconditionally for simplicity. A plain restart has nothing to fix,
# but an online reindex is cheap insurance and the whole mechanism is temporary
# — Postgres is moving off Docker, at which point this goes away.
set -euo pipefail

export PGPASSWORD="$POSTGRES_PASSWORD"

echo "[reindex] Rebuilding indexes for \"$POSTGRES_DB\" (CONCURRENTLY, non-blocking)."
psql -v ON_ERROR_STOP=1 -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "REINDEX DATABASE CONCURRENTLY \"$POSTGRES_DB\";"
echo "[reindex] Done."
