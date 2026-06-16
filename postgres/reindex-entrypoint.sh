#!/usr/bin/env bash
# Custom entrypoint. Runs the stock Postgres entrypoint unchanged, but also
# fires a one-shot background task that waits for Postgres to accept
# connections and then runs the online reindex (see reindex.sh).
#
# Backgrounding keeps the deploy non-blocking — startup is never held up waiting
# for the reindex. exec'ing the real entrypoint keeps Postgres as PID 1 so
# signal handling and the existing CMD are preserved.
set -euo pipefail

(
  export PGPASSWORD="$POSTGRES_PASSWORD"
  # Wait until Postgres is genuinely accepting TCP connections. During first-
  # time cluster init the stock entrypoint runs a socket-only temporary server,
  # so this TCP probe correctly waits for the real server.
  for _ in $(seq 1 60); do
    if pg_isready -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -q; then
      /usr/local/bin/reindex.sh \
        || echo "[reindex-entrypoint] reindex.sh failed (non-fatal)."
      break
    fi
    sleep 2
  done
) &

exec docker-entrypoint.sh "$@"
