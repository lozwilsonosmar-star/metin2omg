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

# Auto-initialize database tables if they don't exist
if [ -f "/app/create-all-tables.sql" ]; then
    echo "Checking database tables..."
    
    # Get MySQL connection parameters from environment variables
    MYSQL_HOST="${MYSQL_HOST:-localhost}"
    MYSQL_PORT="${MYSQL_PORT:-3306}"
    MYSQL_USER="${MYSQL_USER:-metin2}"
    MYSQL_PASSWORD="${MYSQL_PASSWORD:-changeme}"
    MYSQL_DB_PLAYER="${MYSQL_DB_PLAYER:-metin2_player}"
    
    # Convert localhost to 127.0.0.1 for TCP/IP connection
    if [ "$MYSQL_HOST" = "localhost" ]; then
        MYSQL_HOST="127.0.0.1"
    fi
    
    # Check if item_proto table exists (key table that should exist)
    if command -v mysql >/dev/null 2>&1; then
        # Use MYSQL_PWD environment variable for password (more secure and handles special characters)
        export MYSQL_PWD="$MYSQL_PASSWORD"
        
        # Wait a bit for MySQL to be ready (if connecting to external MySQL)
        sleep 2
        
        if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" \
            -e "USE $MYSQL_DB_PLAYER; SHOW TABLES LIKE 'item_proto';" 2>/dev/null | grep -q "item_proto"; then
            echo "✅ Database tables already exist, skipping initialization."
        else
            echo "📦 Database tables not found. Creating tables automatically..."
            if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" < /app/create-all-tables.sql 2>/dev/null; then
                echo "✅ Database tables created successfully!"
            else
                echo "⚠️  Warning: Could not create database tables automatically."
                echo "   Please run the SQL script manually:"
                echo "   mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p < /app/create-all-tables.sql"
            fi
        fi
        unset MYSQL_PWD
    else
        echo "⚠️  Warning: mysql client not found. Skipping automatic table creation."
    fi
else
    echo "⚠️  Warning: /app/create-all-tables.sql not found. Skipping automatic table creation."
fi

# Run the standard container command.
exec "$@"
