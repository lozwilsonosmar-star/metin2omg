#!/bin/bash
# Script para verificar la configuración completa del servidor

echo "=========================================="
echo "Verificación de Configuración Completa"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "═══════════════════════════════════════════"
echo "1. CONFIGURACIÓN DE .env"
echo "═══════════════════════════════════════════"
echo ""

if [ -f ".env" ]; then
    echo "✅ .env encontrado:"
    echo ""
    grep -E "PUBLIC_IP|INTERNAL_IP|GAME_PORT|DB_PORT|AUTH_SERVER|MYSQL" .env | grep -v "^#" | head -15
else
    echo "❌ .env no encontrado"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "2. CONFIGURACIÓN DE game.conf EN EL CONTENEDOR"
echo "═══════════════════════════════════════════"
echo ""

echo "Buscando game.conf en el contenedor..."
CONFIG_PATHS=(
    "/app/game.conf"
    "/usr/metin2/server/game99/CONFIG"
    "/usr/metin2/server/channel1/first/CONFIG"
    "/opt/metin2/game.conf"
    "/etc/metin2/game.conf"
)

FOUND_CONFIG=""
for path in "${CONFIG_PATHS[@]}"; do
    if docker exec metin2-server test -f "$path" 2>/dev/null; then
        FOUND_CONFIG="$path"
        echo "✅ game.conf encontrado en: $path"
        echo ""
        break
    fi
done

if [ -z "$FOUND_CONFIG" ]; then
    echo "⚠️ game.conf no encontrado en rutas comunes"
    echo "Buscando en todo el contenedor..."
    docker exec metin2-server find / -name "game.conf" -o -name "CONFIG" 2>/dev/null | head -5
    echo ""
    echo "Listando archivos en /app:"
    docker exec metin2-server ls -la /app 2>/dev/null | head -10
else
    echo "Contenido de $FOUND_CONFIG:"
    echo ""
    docker exec metin2-server cat "$FOUND_CONFIG" 2>/dev/null | grep -E "PUBLIC_IP|INTERNAL_IP|PROXY_IP|BIND_IP|PORT|AUTH_SERVER|PLAYER_SQL|COMMON_SQL|LOG_SQL" | head -20
fi

echo ""
echo "═══════════════════════════════════════════"
echo "3. VARIABLES DE ENTORNO EN EL CONTENEDOR"
echo "═══════════════════════════════════════════"
echo ""

docker exec metin2-server env 2>/dev/null | grep -E "PUBLIC_IP|INTERNAL_IP|GAME_PORT|DB_PORT|AUTH_SERVER|MYSQL" | head -15

echo ""
echo "═══════════════════════════════════════════"
echo "4. LOGS DE INICIALIZACIÓN (IPs configuradas)"
echo "═══════════════════════════════════════════"
echo ""

docker logs metin2-server 2>&1 | grep -E "Setting.*IP|Public IP|Internal IP|PUBLIC_IP|INTERNAL_IP|automatically configured" | tail -10

echo ""
echo "═══════════════════════════════════════════"
echo "5. COMPARACIÓN CON CONFIGURACIÓN OFICIAL"
echo "═══════════════════════════════════════════"
echo ""

echo "Según basesfiles/FAQ.txt:"
echo "- BIND_IP: IP privada/interna (ej: 192.168.0.150)"
echo "- PROXY_IP: IP pública/externa (ej: 77.88.99.111)"
echo ""
echo "Nuestra configuración debería tener:"
echo "- PUBLIC_IP: 72.61.12.2 (IP pública)"
echo "- INTERNAL_IP: 127.0.0.1 o IP privada (IP interna)"
echo ""

echo "═══════════════════════════════════════════"
echo "6. VERIFICACIÓN DE PUERTOS"
echo "═══════════════════════════════════════════"
echo ""

echo "Puertos escuchando en el contenedor:"
docker exec metin2-server netstat -tuln 2>/dev/null | grep -E "12345|8888|13200" || \
docker exec metin2-server ss -tuln 2>/dev/null | grep -E "12345|8888|13200"

echo ""
echo "═══════════════════════════════════════════"
echo "RESUMEN"
echo "═══════════════════════════════════════════"
echo ""
echo "Verifica que:"
echo "1. PUBLIC_IP esté configurada como 72.61.12.2"
echo "2. INTERNAL_IP esté configurada correctamente"
echo "3. AUTH_SERVER esté configurado como 'master'"
echo "4. Los puertos estén escuchando correctamente"
echo ""
