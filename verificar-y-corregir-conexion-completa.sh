#!/bin/bash
# Script completo para verificar y corregir problemas de conexión
# Basado en la guía de metin2.dev
# Uso: bash verificar-y-corregir-conexion-completa.sh

echo "=========================================="
echo "Verificación Completa de Conexión"
echo "Basado en guía metin2.dev"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

EXPECTED_IP="72.61.12.2"
EXPECTED_PORT="12345"

echo "1. Verificando servidor (VPS)..."
echo ""

# Verificar contenedor
if docker ps | grep -q "metin2-server"; then
    echo -e "   ${GREEN}✅ Contenedor corriendo${NC}"
    CONTAINER_ID=$(docker ps | grep "metin2-server" | awk '{print $1}')
else
    echo -e "   ${RED}❌ Contenedor NO está corriendo${NC}"
    echo "   Ejecutando: docker start metin2-server"
    docker start metin2-server
    echo "   Esperando 30 segundos..."
    sleep 30
fi
echo ""

# Verificar puerto
echo "2. Verificando puerto $EXPECTED_PORT..."
if ss -tuln | grep -q ":$EXPECTED_PORT"; then
    echo -e "   ${GREEN}✅ Puerto $EXPECTED_PORT está escuchando${NC}"
    ss -tuln | grep ":$EXPECTED_PORT"
else
    echo -e "   ${RED}❌ Puerto $EXPECTED_PORT NO está escuchando${NC}"
    echo "   Verificando logs..."
    docker logs --tail 30 metin2-server | grep -E "TCP listening|ERROR|CRITICAL" | tail -5
fi
echo ""

# Verificar configuración del servidor
echo "3. Verificando configuración del servidor..."
echo ""

# Verificar .env
if [ -f ".env" ]; then
    ENV_IP=$(grep "^PUBLIC_IP=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    ENV_PORT=$(grep "^GAME_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    ENV_AUTH=$(grep "^GAME_AUTH_SERVER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    
    echo "   .env:"
    echo "     PUBLIC_IP: $ENV_IP"
    echo "     GAME_PORT: $ENV_PORT"
    echo "     GAME_AUTH_SERVER: $ENV_AUTH"
    
    if [ "$ENV_IP" != "$EXPECTED_IP" ]; then
        echo -e "     ${RED}❌ IP incorrecta${NC}"
        echo "     Corrigiendo..."
        sed -i "s/^PUBLIC_IP=.*/PUBLIC_IP=$EXPECTED_IP/" .env
        echo -e "     ${GREEN}✅ IP corregida${NC}"
    else
        echo -e "     ${GREEN}✅ IP correcta${NC}"
    fi
    
    if [ "$ENV_PORT" != "$EXPECTED_PORT" ]; then
        echo -e "     ${RED}❌ Puerto incorrecto${NC}"
    else
        echo -e "     ${GREEN}✅ Puerto correcto${NC}"
    fi
    
    if [ -z "$ENV_AUTH" ] || [ "$ENV_AUTH" != "master" ]; then
        echo -e "     ${YELLOW}⚠️  AUTH_SERVER no está en 'master'${NC}"
        echo "     Corrigiendo..."
        if ! grep -q "^GAME_AUTH_SERVER=" .env; then
            echo "GAME_AUTH_SERVER=master" >> .env
        else
            sed -i "s/^GAME_AUTH_SERVER=.*/GAME_AUTH_SERVER=master/" .env
        fi
        echo -e "     ${GREEN}✅ AUTH_SERVER corregido a 'master'${NC}"
    else
        echo -e "     ${GREEN}✅ AUTH_SERVER correcto${NC}"
    fi
else
    echo -e "   ${RED}❌ Archivo .env no encontrado${NC}"
fi
echo ""

# Verificar game.conf dentro del contenedor
echo "4. Verificando game.conf en el contenedor..."
if docker ps | grep -q "metin2-server"; then
    GAME_CONF_IP=$(docker exec metin2-server cat /opt/metin2/gamefiles/conf/game.conf 2>/dev/null | grep "^PUBLIC_IP:" | awk '{print $2}' || echo "")
    GAME_CONF_PORT=$(docker exec metin2-server cat /opt/metin2/gamefiles/conf/game.conf 2>/dev/null | grep "^PORT:" | awk '{print $2}' || echo "")
    GAME_CONF_AUTH=$(docker exec metin2-server cat /opt/metin2/gamefiles/conf/game.conf 2>/dev/null | grep "^AUTH_SERVER:" | awk '{print $2}' || echo "")
    
    echo "   game.conf:"
    echo "     PUBLIC_IP: $GAME_CONF_IP"
    echo "     PORT: $GAME_CONF_PORT"
    echo "     AUTH_SERVER: $GAME_CONF_AUTH"
    
    if [ "$GAME_CONF_IP" != "$EXPECTED_IP" ] || [ "$GAME_CONF_PORT" != "$EXPECTED_PORT" ] || [ "$GAME_CONF_AUTH" != "master" ]; then
        echo -e "     ${YELLOW}⚠️  game.conf necesita regenerarse${NC}"
        echo "     Reiniciando contenedor para regenerar game.conf..."
        docker restart metin2-server
        echo "     Esperando 30 segundos..."
        sleep 30
    else
        echo -e "     ${GREEN}✅ game.conf correcto${NC}"
    fi
fi
echo ""

# Verificar firewall
echo "5. Verificando firewall..."
if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "$EXPECTED_PORT"; then
        echo -e "   ${GREEN}✅ Puerto $EXPECTED_PORT permitido en firewall${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Puerto $EXPECTED_PORT no aparece en reglas del firewall${NC}"
        echo "   ¿Deseas abrir el puerto? (s/N): "
        read -r respuesta
        if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
            sudo ufw allow $EXPECTED_PORT/tcp
            echo -e "   ${GREEN}✅ Puerto abierto${NC}"
        fi
    fi
else
    echo -e "   ${YELLOW}⚠️  UFW no disponible, verifica el firewall manualmente${NC}"
fi
echo ""

# Verificar logs del servidor
echo "6. Verificando logs del servidor (últimas líneas críticas)..."
if docker ps | grep -q "metin2-server"; then
    echo "   Buscando 'TCP listening'..."
    if docker logs --tail 100 metin2-server 2>&1 | grep -q "TCP listening on.*$EXPECTED_PORT"; then
        echo -e "   ${GREEN}✅ Servidor está escuchando en puerto $EXPECTED_PORT${NC}"
        docker logs --tail 100 metin2-server 2>&1 | grep "TCP listening" | tail -1
    else
        echo -e "   ${RED}❌ No se encontró 'TCP listening' en los logs${NC}"
        echo "   Últimas líneas de error:"
        docker logs --tail 20 metin2-server 2>&1 | grep -E "ERROR|CRITICAL" | tail -5
    fi
fi
echo ""

# Verificar conectividad
echo "7. Verificando conectividad..."
if timeout 3 bash -c "echo > /dev/tcp/$EXPECTED_IP/$EXPECTED_PORT" 2>/dev/null; then
    echo -e "   ${GREEN}✅ Puerto $EXPECTED_PORT es accesible desde el VPS${NC}"
else
    echo -e "   ${YELLOW}⚠️  No se pudo verificar conectividad (puede ser normal)${NC}"
fi
echo ""

# Resumen y recomendaciones para el cliente
echo "=========================================="
echo "RESUMEN Y CONFIGURACIÓN DEL CLIENTE"
echo "=========================================="
echo ""
echo "📋 Configuración del servidor:"
echo "   IP: $EXPECTED_IP"
echo "   Puerto del juego: $EXPECTED_PORT"
echo "   AUTH_SERVER: master (modo standalone)"
echo ""
echo "📋 Configuración requerida en el cliente (serverinfo.py):"
echo "   SERVER_IP = \"$EXPECTED_IP\""
echo "   PORT_1 = $EXPECTED_PORT"
echo "   PORT_AUTH = $EXPECTED_PORT  ← ⚠️ IMPORTANTE: Debe ser el mismo que PORT_1"
echo ""
echo "⚠️  NOTA CRÍTICA:"
echo "   El servidor está en modo standalone (AUTH_SERVER=master)."
echo "   El cliente NO debe intentar conectarse a un servidor de autenticación separado."
echo "   PORT_AUTH en serverinfo.py debe apuntar al mismo puerto que el juego (12345)."
echo ""
echo "🔧 Para corregir en el cliente:"
echo "   1. Abre: Eternexus\\root\\serverinfo.py"
echo "   2. Cambia: PORT_AUTH = 11000"
echo "   3. A: PORT_AUTH = 12345"
echo "   4. También cambia en REGION_AUTH_SERVER_DICT el puerto a 12345"
echo "   5. Reempaqueta con EterNexus"
echo ""

