#!/usr/bin/env bash
set -e

# ── Fix volume and uploads directory permissions (runs as root) ──
chown nobody:nogroup /mnt/name 2>/dev/null || true
mkdir -p /mnt/name/uploads
chown -R nobody:nogroup /mnt/name/uploads 2>/dev/null || true
chmod -R u+rwX,go+rX /mnt/name/uploads 2>/dev/null || true

# If db doesn't exist, try restoring from object storage
if [ ! -f "$DATABASE_PATH" ] && [ -n "$BUCKET_NAME" ]; then
	litestream restore -if-replica-exists "$DATABASE_PATH"
fi

# Run migrations via shell so startup is robust even if execute bit is missing.
/bin/sh /app/bin/migrate

# Ensure DB files are owned by nobody after restore/migration
chown nobody:nogroup "$DATABASE_PATH" "${DATABASE_PATH}-wal" "${DATABASE_PATH}-shm" 2>/dev/null || true

# Launch application (drop privileges to nobody)
if [ -n "$BUCKET_NAME" ]; then
	exec gosu nobody litestream replicate -exec "${*}"
else
	exec gosu nobody "${@}"
fi
