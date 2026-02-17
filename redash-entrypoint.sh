#!/bin/bash
set -e

# Run create_db only on first run (avoid resetting DB on every restart)
if [ ! -f /app/data/.redash_initialized ]; then
  /app/bin/docker-entrypoint create_db && touch /app/data/.redash_initialized || true
fi

exec /app/bin/docker-entrypoint server
