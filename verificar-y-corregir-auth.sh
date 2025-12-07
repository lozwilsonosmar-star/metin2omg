#!/bin/bash
# Script para verificar y corregir AUTH_SERVER definitivamente
# Uso: bash verificar-y-corregir-auth.sh

set -e

echo "=========================================="
echo "Verificación y Corrección de AUTH_SERVER"
echo "=========================================="
echo ""

cd /opt/metin2omg

# 1. Verificar .env
echo "1. Verificando .env..."
if grep -q "^GAME_AUTH_SERVER=master" .env; then
    echo "   ✅ GAME_AUTH_SERVER=master en .env"
else
    echo "   ⚠️  Corrigiendo GAME_AUTH_SERVER en .env..."
    if grep -q "^GAME_AUTH_SERVER=" .env; then
        sed -i 's/^GAME_AUTH_SERVER=.*/GAME_AUTH_SERVER=master/' .env
    else
        echo "GAME_AUTH_SERVER=master" >> .env
    fi
    echo "   ✅ Corregido"
fi
echo ""

# 2. Verificar game.conf dentro del contenedor
echo "2. Verificando game.conf dentro del contenedor..."
AUTH_IN_CONF=$(docker exec metin2-server cat /app/game.conf 2>/dev/null | grep "^AUTH_SERVER:" || echo "")

if [ -n "$AUTH_IN_CONF" ]; then
    echo "   Contenido actual: $AUTH_IN_CONF"
    if echo "$AUTH_IN_CONF" | grep -q "AUTH_SERVER: master"; then
        echo "   ✅ game.conf tiene AUTH_SERVER: master"
    else
        echo "   ❌ game.conf NO tiene 'master', tiene: $AUTH_IN_CONF"
        echo "   ⚠️  Forzando regeneración..."
        
        # Detener contenedor
        docker stop metin2-server
        
        # Eliminar game.conf del contenedor (se regenerará al iniciar)
        docker rm metin2-server 2>/dev/null || true
        
        # Recrear contenedor con las variables de entorno correctas
        echo "   ✅ Contenedor eliminado, se recreará con configuración correcta"
    fi
else
    echo "   ⚠️  No se pudo leer game.conf del contenedor"
    echo "   ⚠️  Forzando recreación del contenedor..."
    docker stop metin2-server 2>/dev/null || true
    docker rm metin2-server 2>/dev/null || true
fi
echo ""

# 3. Verificar que el contenedor existe o recrearlo
if ! docker ps -a | grep -q "metin2-server"; then
    echo "3. Recreando contenedor..."
    # Obtener imagen
    IMAGE=$(docker images | grep "metin2/server" | awk '{print $1":"$2}' | head -1)
    if [ -z "$IMAGE" ]; then
        IMAGE="metin2/server:latest"
    fi
    
    # Recrear contenedor
    docker run -d \
        --name metin2-server \
        --restart unless-stopped \
        --network host \
        --env-file .env \
        "$IMAGE"
    echo "   ✅ Contenedor recreado"
else
    echo "3. Iniciando contenedor..."
    docker start metin2-server
    echo "   ✅ Contenedor iniciado"
fi
echo ""

# 4. Esperar y verificar
echo "4. Esperando 10 segundos para que se genere game.conf..."
sleep 10

# Verificar nuevamente
AUTH_IN_CONF=$(docker exec metin2-server cat /app/game.conf 2>/dev/null | grep "^AUTH_SERVER:" || echo "")
if [ -n "$AUTH_IN_CONF" ]; then
    echo "   Contenido después de regenerar: $AUTH_IN_CONF"
    if echo "$AUTH_IN_CONF" | grep -q "AUTH_SERVER: master"; then
        echo "   ✅ game.conf ahora tiene AUTH_SERVER: master"
    else
        echo "   ❌ game.conf aún no tiene 'master'"
        echo "   ⚠️  Verifica manualmente: docker exec metin2-server cat /app/game.conf | grep AUTH"
    fi
fi
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
echo ""
echo "Espera 30 segundos más y verifica los logs:"
echo "   docker logs --tail 30 metin2-server | grep -E 'AUTH_SERVER|TCP listening'"
echo ""

