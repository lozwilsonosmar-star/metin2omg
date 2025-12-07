#!/bin/bash
# Script para verificar game.conf dentro del contenedor

echo "=========================================="
echo "Verificación de game.conf en el Contenedor"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "1. Buscando game.conf en el contenedor..."
echo ""

# Buscar game.conf en varias ubicaciones
PATHS=(
    "/app/game.conf"
    "/app/conf/game.conf"
    "/usr/metin2/server/game99/CONFIG"
    "/usr/metin2/server/channel1/first/CONFIG"
    "/opt/metin2/game.conf"
    "/etc/metin2/game.conf"
    "/root/game.conf"
)

FOUND=false
for path in "${PATHS[@]}"; do
    if docker exec metin2-server test -f "$path" 2>/dev/null; then
        echo "✅ Encontrado: $path"
        echo ""
        echo "Contenido completo:"
        echo "═══════════════════════════════════════════"
        docker exec metin2-server cat "$path" 2>/dev/null
        echo "═══════════════════════════════════════════"
        FOUND=true
        break
    fi
done

if [ "$FOUND" = false ]; then
    echo "⚠️ game.conf no encontrado en rutas comunes"
    echo ""
    echo "2. Buscando en todo el contenedor..."
    docker exec metin2-server find / -name "game.conf" -o -name "CONFIG" 2>/dev/null | head -10
    echo ""
    echo "3. Listando archivos en /app:"
    docker exec metin2-server ls -la /app 2>/dev/null | head -20
    echo ""
    echo "4. Listando archivos en /app/conf:"
    docker exec metin2-server ls -la /app/conf 2>/dev/null 2>/dev/null | head -20
fi

echo ""
echo "5. Verificando variables de entorno relacionadas con IPs:"
docker exec metin2-server env 2>/dev/null | grep -E "PUBLIC_IP|INTERNAL_IP|GAME_PORT|AUTH_SERVER" | sort

echo ""
echo "6. Verificando logs de inicialización de IPs:"
docker logs metin2-server 2>&1 | grep -E "Setting.*IP|Public IP|Internal IP|PUBLIC_IP|INTERNAL_IP" | tail -5

