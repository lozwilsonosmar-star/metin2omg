#!/bin/sh
# docker-entrypoint.sh

set -e

# Generate configuration files based on environment variables
if [ -f "/app/conf/db.conf.tmpl" ]; then
    envsubst <"/app/conf/db.conf.tmpl" >"/app/db.conf"
else
    echo "Warning: /app/conf/db.conf.tmpl not found, skipping db.conf generation"
fi

if [ -f "/app/conf/game.conf.tmpl" ]; then
    envsubst <"/app/conf/game.conf.tmpl" >"/app/game.conf"
else
    echo "Warning: /app/conf/game.conf.tmpl not found, skipping game.conf generation"
fi

# Run the standard container command.
exec "$@"
