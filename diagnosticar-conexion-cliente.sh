#!/bin/bash
# Script para diagnosticar problemas de conexión del cliente
# Uso: bash diagnosticar-conexion-cliente.sh

echo "=========================================="
echo "Diagnóstico de Conexión del Cliente"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# IP y puerto esperados
EXPECTED_IP="72.61.12.2"
EXPECTED_PORT="12345"
EXPECTED_NAME="Metin2OMG"

echo "1. Verificando configuración del servidor (.env)..."
echo ""

if [ -f ".env" ]; then
    ENV_IP=$(grep "^PUBLIC_IP=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    ENV_PORT=$(grep "^GAME_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    
    echo "   PUBLIC_IP en .env: $ENV_IP"
    echo "   GAME_PORT en .env: $ENV_PORT"
    
    if [ "$ENV_IP" = "$EXPECTED_IP" ]; then
        echo -e "   ${GREEN}✅ IP correcta${NC}"
    else
        echo -e "   ${RED}❌ IP incorrecta (esperada: $EXPECTED_IP)${NC}"
    fi
    
    if [ "$ENV_PORT" = "$EXPECTED_PORT" ]; then
        echo -e "   ${GREEN}✅ Puerto correcto${NC}"
    else
        echo -e "   ${RED}❌ Puerto incorrecto (esperado: $EXPECTED_PORT)${NC}"
    fi
else
    echo -e "   ${RED}❌ Archivo .env no encontrado${NC}"
fi
echo ""

echo "2. Verificando estado del contenedor..."
echo ""

if docker ps | grep -q "metin2-server"; then
    echo -e "   ${GREEN}✅ Contenedor está corriendo${NC}"
    CONTAINER_ID=$(docker ps | grep "metin2-server" | awk '{print $1}')
    echo "   ID del contenedor: $CONTAINER_ID"
else
    echo -e "   ${RED}❌ Contenedor NO está corriendo${NC}"
    echo "   Ejecuta: docker start metin2-server"
fi
echo ""

echo "3. Verificando puertos escuchando..."
echo ""

if ss -tuln | grep -q ":$EXPECTED_PORT"; then
    echo -e "   ${GREEN}✅ Puerto $EXPECTED_PORT está escuchando${NC}"
    ss -tuln | grep ":$EXPECTED_PORT"
else
    echo -e "   ${RED}❌ Puerto $EXPECTED_PORT NO está escuchando${NC}"
fi
echo ""

echo "4. Verificando logs del servidor (últimas 20 líneas)..."
echo ""

if docker ps | grep -q "metin2-server"; then
    echo "   Buscando indicadores clave en los logs:"
    docker logs --tail 50 metin2-server 2>&1 | grep -E "TCP listening|AUTH_SERVER|ERROR|CRITICAL" | tail -10
    echo ""
    
    if docker logs --tail 100 metin2-server 2>&1 | grep -q "TCP listening on.*$EXPECTED_PORT"; then
        echo -e "   ${GREEN}✅ Servidor está escuchando en puerto $EXPECTED_PORT${NC}"
    else
        echo -e "   ${YELLOW}⚠️  No se encontró 'TCP listening' en los logs${NC}"
    fi
else
    echo -e "   ${RED}❌ No se pueden verificar logs (contenedor no está corriendo)${NC}"
fi
echo ""

echo "5. Verificando configuración game.conf dentro del contenedor..."
echo ""

if docker ps | grep -q "metin2-server"; then
    echo "   Buscando PUBLIC_IP en game.conf:"
    docker exec metin2-server cat /opt/metin2/gamefiles/conf/game.conf 2>/dev/null | grep -E "PUBLIC_IP|AUTH_SERVER" | head -5 || echo "   No se pudo leer game.conf"
    echo ""
else
    echo -e "   ${RED}❌ No se puede verificar game.conf (contenedor no está corriendo)${NC}"
fi
echo ""

echo "6. Verificando firewall..."
echo ""

if command -v ufw >/dev/null 2>&1; then
    FIREWALL_STATUS=$(ufw status | head -1)
    echo "   Estado del firewall: $FIREWALL_STATUS"
    
    if ufw status | grep -q "$EXPECTED_PORT"; then
        echo -e "   ${GREEN}✅ Puerto $EXPECTED_PORT está permitido en el firewall${NC}"
        ufw status | grep "$EXPECTED_PORT"
    else
        echo -e "   ${YELLOW}⚠️  Puerto $EXPECTED_PORT no aparece en las reglas del firewall${NC}"
        echo "   Verifica manualmente: sudo ufw status"
    fi
else
    echo -e "   ${YELLOW}⚠️  UFW no está instalado o no se puede verificar${NC}"
fi
echo ""

echo "7. Verificando configuración del cliente (serverinfo.py)..."
echo ""

CLIENT_SERVERINFO="Client-20251206T130044Z-3-001/Client/Client/Client/Eternexus/root/serverinfo.py"

if [ -f "$CLIENT_SERVERINFO" ]; then
    echo "   Archivo encontrado: $CLIENT_SERVERINFO"
    echo ""
    echo "   Configuración actual:"
    grep -E "SERVER_IP|SERVER_NAME|PORT_1" "$CLIENT_SERVERINFO" | head -5
    
    CLIENT_IP=$(grep "SERVER_IP[[:space:]]*=" "$CLIENT_SERVERINFO" | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/')
    CLIENT_PORT=$(grep "PORT_1[[:space:]]*=" "$CLIENT_SERVERINFO" | head -1 | sed 's/.*= *\([0-9]*\).*/\1/')
    
    echo ""
    if [ "$CLIENT_IP" = "$EXPECTED_IP" ]; then
        echo -e "   ${GREEN}✅ IP del cliente correcta: $CLIENT_IP${NC}"
    else
        echo -e "   ${RED}❌ IP del cliente incorrecta: $CLIENT_IP (esperada: $EXPECTED_IP)${NC}"
    fi
    
    if [ "$CLIENT_PORT" = "$EXPECTED_PORT" ]; then
        echo -e "   ${GREEN}✅ Puerto del cliente correcto: $CLIENT_PORT${NC}"
    else
        echo -e "   ${RED}❌ Puerto del cliente incorrecto: $CLIENT_PORT (esperado: $EXPECTED_PORT)${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  Archivo serverinfo.py no encontrado en el VPS${NC}"
    echo "   (Esto es normal si el cliente está en tu máquina Windows)"
fi
echo ""

echo "8. Verificando conectividad de red..."
echo ""

if ping -c 1 -W 2 "$EXPECTED_IP" >/dev/null 2>&1; then
    echo -e "   ${GREEN}✅ La IP $EXPECTED_IP es alcanzable${NC}"
else
    echo -e "   ${YELLOW}⚠️  No se pudo hacer ping a $EXPECTED_IP${NC}"
    echo "   (Esto puede ser normal si el firewall bloquea ICMP)"
fi

if timeout 3 bash -c "echo > /dev/tcp/$EXPECTED_IP/$EXPECTED_PORT" 2>/dev/null; then
    echo -e "   ${GREEN}✅ El puerto $EXPECTED_PORT está abierto y accesible${NC}"
else
    echo -e "   ${RED}❌ No se puede conectar al puerto $EXPECTED_PORT en $EXPECTED_IP${NC}"
    echo "   Posibles causas:"
    echo "     - El servidor no está corriendo"
    echo "     - El firewall está bloqueando el puerto"
    echo "     - El puerto no está configurado correctamente"
fi
echo ""

echo "=========================================="
echo "RESUMEN DEL DIAGNÓSTICO"
echo "=========================================="
echo ""

# Contar problemas
PROBLEMAS=0

if ! docker ps | grep -q "metin2-server"; then
    echo -e "${RED}❌ PROBLEMA: Contenedor no está corriendo${NC}"
    PROBLEMAS=$((PROBLEMAS + 1))
fi

if ! ss -tuln | grep -q ":$EXPECTED_PORT"; then
    echo -e "${RED}❌ PROBLEMA: Puerto $EXPECTED_PORT no está escuchando${NC}"
    PROBLEMAS=$((PROBLEMAS + 1))
fi

if [ -f ".env" ]; then
    ENV_IP=$(grep "^PUBLIC_IP=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    if [ "$ENV_IP" != "$EXPECTED_IP" ]; then
        echo -e "${RED}❌ PROBLEMA: IP en .env incorrecta ($ENV_IP != $EXPECTED_IP)${NC}"
        PROBLEMAS=$((PROBLEMAS + 1))
    fi
fi

if [ $PROBLEMAS -eq 0 ]; then
    echo -e "${GREEN}✅ No se encontraron problemas críticos${NC}"
    echo ""
    echo "Si aún así no puedes conectarte, verifica:"
    echo "  1. Que el cliente tenga la IP correcta en serverinfo.py"
    echo "  2. Que el firewall de tu máquina Windows no esté bloqueando"
    echo "  3. Que el servidor esté completamente iniciado (espera 30-60 segundos)"
else
    echo -e "${RED}❌ Se encontraron $PROBLEMAS problema(s) crítico(s)${NC}"
    echo ""
    echo "Soluciones sugeridas:"
    echo "  1. Si el contenedor no está corriendo: docker start metin2-server"
    echo "  2. Si el puerto no está escuchando: docker restart metin2-server"
    echo "  3. Si la IP está mal: bash corregir-ip-publica.sh"
    echo "  4. Si el firewall bloquea: sudo ufw allow $EXPECTED_PORT/tcp"
fi
echo ""

