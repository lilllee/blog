#!/usr/bin/env bash
set -e

# If db doesn't exist, try restoring from object storage
if [ ! -f "$DATABASE_PATH" ] && [ -n "$BUCKET_NAME" ]; then
	litestream restore -if-replica-exists "$DATABASE_PATH"
fi

# Run migrations via shell so startup is robust even if execute bit is missing.
/bin/sh /app/bin/migrate

# Launch application
if [ -n "$BUCKET_NAME" ]; then
	exec litestream replicate -exec "${*}"
else
	exec "${@}"
fi
