#!/bin/bash
# Script para verificar game.conf después de regeneración
# Uso: bash verificar-game-conf.sh

echo "=========================================="
echo "Verificación de game.conf"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Esperar un poco más para que el contenedor termine de iniciar
echo "Esperando 10 segundos para que el servidor termine de iniciar..."
sleep 10

# Verificar que el contenedor está corriendo
if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Error: El contenedor no está corriendo"
    exit 1
fi

echo "1. Verificando game.conf..."
echo ""

GAME_CONF="/opt/metin2/gamefiles/conf/game.conf"

# Leer valores importantes de game.conf
PUBLIC_IP=$(docker exec metin2-server cat "$GAME_CONF" 2>/dev/null | grep "^PUBLIC_IP:" | awk '{print $2}' || echo "")
PORT=$(docker exec metin2-server cat "$GAME_CONF" 2>/dev/null | grep "^PORT:" | awk '{print $2}' || echo "")
AUTH_SERVER=$(docker exec metin2-server cat "$GAME_CONF" 2>/dev/null | grep "^AUTH_SERVER:" | awk '{print $2}' || echo "")
HOSTNAME=$(docker exec metin2-server cat "$GAME_CONF" 2>/dev/null | grep "^HOSTNAME:" | awk '{print $2}' || echo "")

echo "   Valores en game.conf:"
echo "     PUBLIC_IP: $PUBLIC_IP"
echo "     PORT: $PORT"
echo "     AUTH_SERVER: $AUTH_SERVER"
echo "     HOSTNAME: $HOSTNAME"
echo ""

# Verificar valores esperados
EXPECTED_IP="72.61.12.2"
EXPECTED_PORT="12345"
EXPECTED_AUTH="master"

ERRORS=0

if [ "$PUBLIC_IP" = "$EXPECTED_IP" ]; then
    echo "   ✅ PUBLIC_IP correcto"
else
    echo "   ❌ PUBLIC_IP incorrecto (esperado: $EXPECTED_IP, actual: $PUBLIC_IP)"
    ERRORS=$((ERRORS + 1))
fi

if [ "$PORT" = "$EXPECTED_PORT" ]; then
    echo "   ✅ PORT correcto"
else
    echo "   ❌ PORT incorrecto (esperado: $EXPECTED_PORT, actual: $PORT)"
    ERRORS=$((ERRORS + 1))
fi

if [ "$AUTH_SERVER" = "$EXPECTED_AUTH" ]; then
    echo "   ✅ AUTH_SERVER correcto"
else
    echo "   ❌ AUTH_SERVER incorrecto (esperado: $EXPECTED_AUTH, actual: $AUTH_SERVER)"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "2. Verificando que el servidor está escuchando..."
echo ""

if ss -tuln | grep -q ":12345"; then
    echo "   ✅ Puerto 12345 está escuchando"
    ss -tuln | grep ":12345"
else
    echo "   ❌ Puerto 12345 NO está escuchando"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "3. Verificando logs del servidor..."
echo ""

if docker logs --tail 50 metin2-server 2>&1 | grep -q "TCP listening on.*12345"; then
    echo "   ✅ Servidor está escuchando en puerto 12345"
    docker logs --tail 50 metin2-server 2>&1 | grep "TCP listening" | tail -1
else
    echo "   ⚠️  No se encontró 'TCP listening' en los logs"
    echo "   Últimas líneas relevantes:"
    docker logs --tail 20 metin2-server 2>&1 | grep -E "TCP|PORT|PUBLIC_IP|AUTH" | tail -5
fi

echo ""
echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "✅ Todo está correctamente configurado"
    echo ""
    echo "📋 Configuración del servidor:"
    echo "   IP: $EXPECTED_IP"
    echo "   Puerto: $EXPECTED_PORT"
    echo "   AUTH_SERVER: $EXPECTED_AUTH"
    echo ""
    echo "🎮 El servidor está listo para recibir conexiones"
    echo ""
    echo "📝 Próximos pasos:"
    echo "   1. Asegúrate de que el cliente tenga PORT_AUTH = 12345 en serverinfo.py"
    echo "   2. Reempaqueta root/ con EterNexus"
    echo "   3. Ejecuta el cliente y prueba la conexión"
else
    echo "❌ Se encontraron $ERRORS problema(s)"
    echo ""
    echo "🔧 Soluciones:"
    echo "   1. Si game.conf está vacío, espera más tiempo y vuelve a ejecutar este script"
    echo "   2. Si los valores son incorrectos, verifica el archivo .env"
    echo "   3. Reinicia el contenedor: docker restart metin2-server"
fi
echo ""

