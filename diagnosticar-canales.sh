#!/bin/bash
# Script para diagnosticar problemas con los canales del servidor
# Uso: bash diagnosticar-canales.sh

echo "=========================================="
echo "Diagnóstico de Canales del Servidor"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "1. Verificando estado del contenedor..."
if docker ps | grep -q "metin2-server"; then
    echo -e "   ${GREEN}✅ Contenedor corriendo${NC}"
else
    echo -e "   ${RED}❌ Contenedor NO está corriendo${NC}"
    exit 1
fi
echo ""

echo "2. Verificando puertos escuchando..."
echo "   Puerto 12345 (GAME):"
if ss -tuln | grep -q ":12345"; then
    echo -e "   ${GREEN}✅ Escuchando${NC}"
    ss -tuln | grep ":12345"
else
    echo -e "   ${RED}❌ NO está escuchando${NC}"
fi

echo "   Puerto 8888 (DB):"
if ss -tuln | grep -q ":8888"; then
    echo -e "   ${GREEN}✅ Escuchando${NC}"
else
    echo -e "   ${YELLOW}⚠️  NO está escuchando (puede ser normal)${NC}"
fi

echo "   Puerto 13200 (P2P):"
if ss -tuln | grep -q ":13200"; then
    echo -e "   ${GREEN}✅ Escuchando${NC}"
else
    echo -e "   ${YELLOW}⚠️  NO está escuchando (puede ser normal)${NC}"
fi
echo ""

echo "3. Verificando logs del servidor (últimas 50 líneas)..."
echo ""
docker logs --tail 50 metin2-server 2>&1 | tail -20
echo ""

echo "4. Buscando errores críticos en los logs..."
echo ""
CRITICAL=$(docker logs --tail 200 metin2-server 2>&1 | grep -E "CRITICAL|FATAL|FAILED|ERROR" | tail -10)
if [ -n "$CRITICAL" ]; then
    echo -e "   ${RED}❌ Errores encontrados:${NC}"
    echo "$CRITICAL"
else
    echo -e "   ${GREEN}✅ No se encontraron errores críticos${NC}"
fi
echo ""

echo "5. Verificando que el servidor esté completamente iniciado..."
echo ""
if docker logs --tail 100 metin2-server 2>&1 | grep -q "TCP listening on.*12345"; then
    echo -e "   ${GREEN}✅ Servidor está escuchando en puerto 12345${NC}"
    docker logs --tail 100 metin2-server 2>&1 | grep "TCP listening" | tail -1
else
    echo -e "   ${RED}❌ No se encontró 'TCP listening'${NC}"
fi
echo ""

echo "6. Verificando configuración del servidor..."
echo ""
if [ -f ".env" ]; then
    GAME_CHANNEL=$(grep "^GAME_CHANNEL=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    GAME_HOSTNAME=$(grep "^GAME_HOSTNAME=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    
    echo "   GAME_CHANNEL: $GAME_CHANNEL"
    echo "   GAME_HOSTNAME: $GAME_HOSTNAME"
    
    if [ -z "$GAME_CHANNEL" ]; then
        echo -e "   ${YELLOW}⚠️  GAME_CHANNEL no está configurado${NC}"
        echo "   Esto puede causar problemas con los canales"
    fi
fi
echo ""

echo "7. Verificando game.conf en el contenedor..."
echo ""
if docker ps | grep -q "metin2-server"; then
    GAME_CONF_CHANNEL=$(docker exec metin2-server cat /opt/metin2/gamefiles/conf/game.conf 2>/dev/null | grep "^CHANNEL:" | awk '{print $2}' || echo "")
    GAME_CONF_HOSTNAME=$(docker exec metin2-server cat /opt/metin2/gamefiles/conf/game.conf 2>/dev/null | grep "^HOSTNAME:" | awk '{print $2}' || echo "")
    
    echo "   CHANNEL: $GAME_CONF_CHANNEL"
    echo "   HOSTNAME: $GAME_CONF_HOSTNAME"
fi
echo ""

echo "8. Verificando conexiones activas..."
echo ""
ACTIVE_CONNECTIONS=$(ss -tn | grep ":12345" | grep ESTAB | wc -l)
echo "   Conexiones activas al puerto 12345: $ACTIVE_CONNECTIONS"
if [ "$ACTIVE_CONNECTIONS" -gt 0 ]; then
    echo -e "   ${GREEN}✅ Hay conexiones activas${NC}"
    ss -tn | grep ":12345" | grep ESTAB | head -5
else
    echo -e "   ${YELLOW}⚠️  No hay conexiones activas${NC}"
    echo "   Esto es normal si nadie está conectado"
fi
echo ""

echo "=========================================="
echo "RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""

echo "📋 Si los canales muestran '...' (STATE_NONE), puede ser porque:"
echo ""
echo "   1. El servidor no está completamente iniciado"
echo "      Solución: Espera 60 segundos después de iniciar el contenedor"
echo ""
echo "   2. El cliente no puede obtener el estado de los canales"
echo "      Solución: Verifica que el puerto 12345 esté abierto en el firewall"
echo ""
echo "   3. El servidor está en modo standalone y no responde a peticiones de estado"
echo "      Solución: Esto puede ser normal, intenta conectarte directamente"
echo ""
echo "   4. Hay un problema con la configuración de canales"
echo "      Solución: Verifica GAME_CHANNEL en .env"
echo ""
echo "🔧 Prueba conectarte directamente:"
echo "   1. Selecciona el servidor 'Metin2OMG'"
echo "   2. Selecciona el canal 'CH1'"
echo "   3. Intenta conectarte con: test / test123"
echo ""
echo "   Si puedes conectarte, el problema es solo visual (el estado no se actualiza)"
echo "   Si NO puedes conectarte, hay un problema real de conexión"
echo ""

