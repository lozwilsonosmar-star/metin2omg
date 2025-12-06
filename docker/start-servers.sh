#!/bin/bash
# Script para iniciar los servidores DB y Game

set -e

cd /app

# Iniciar DB server en background
echo "Iniciando DB Server..."
/bin/db &
DB_PID=$!

# Esperar un poco para que el DB server se inicie
sleep 2

# Verificar que el DB server esté corriendo
if ! kill -0 $DB_PID 2>/dev/null; then
    echo "Error: DB Server no pudo iniciarse"
    exit 1
fi

echo "DB Server iniciado (PID: $DB_PID)"

# Iniciar Game server en foreground (para que Docker vea los logs)
echo "Iniciando Game Server..."
exec /bin/game

