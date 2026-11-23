#!/bin/bash
# Starts the IronCalc server and Caddy, and exits non-zero if either one stops,
# so Railway's ON_FAILURE restart policy brings the service back.
set -euo pipefail

DATA_DIR="${IRONCALC_DATA_DIR:-/data}"
USERNAME="${IRONCALC_USERNAME:-admin}"
PASSWORD="${IRONCALC_PASSWORD:-}"
export PORT="${PORT:-8080}"

mkdir -p "$DATA_DIR" /tmp/caddy/config /tmp/caddy/data

# First boot: put the empty share database (one "models" table) on the volume.
if [ ! -s "$DATA_DIR/ironcalc.sqlite" ]; then
  echo "ironcalc: creating $DATA_DIR/ironcalc.sqlite"
  cp /app/ironcalc.seed.sqlite "$DATA_DIR/ironcalc.sqlite.tmp"
  mv "$DATA_DIR/ironcalc.sqlite.tmp" "$DATA_DIR/ironcalc.sqlite"
fi

# Login for the whole site (except /healthz).
if [ -n "$PASSWORD" ]; then
  if [[ ! "$USERNAME" =~ ^[A-Za-z0-9._@-]+$ ]]; then
    echo "ironcalc: IRONCALC_USERNAME may only contain letters, digits and . _ @ -" >&2
    exit 1
  fi
  HASH="$(caddy hash-password --plaintext "$PASSWORD")"
  printf 'basic_auth {\n\t%s %s\n}\n' "$USERNAME" "$HASH" > /tmp/caddy/auth.caddy
  echo "ironcalc: login enabled for user '$USERNAME'"
else
  : > /tmp/caddy/auth.caddy
  echo "ironcalc: WARNING: IRONCALC_PASSWORD is empty, the site is public" >&2
fi

pids=()
stop() {
  trap - TERM INT
  kill -TERM "${pids[@]}" 2>/dev/null || true
  wait || true
  exit 0
}
trap stop TERM INT

cd /app
./ironcalc_server &
pids+=($!)

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
pids+=($!)

# Whichever process stops first ends the container with a non-zero code.
set +e
wait -n "${pids[@]}"
code=$?
set -e
echo "ironcalc: a process exited (code $code), stopping the container" >&2
kill -TERM "${pids[@]}" 2>/dev/null || true
wait || true
if [ "$code" -eq 0 ]; then code=1; fi
exit "$code"
