#!/bin/bash
# Script completo para verificar TODO: servidor y configuración del cliente
# Uso: bash verificar-todo-completo.sh

echo "=========================================="
echo "VERIFICACIÓN COMPLETA - SERVIDOR Y CLIENTE"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

EXPECTED_IP="72.61.12.2"
EXPECTED_PORT="12345"
EXPECTED_AUTH="master"

ERRORS=0
WARNINGS=0

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}PARTE 1: VERIFICACIÓN DEL SERVIDOR (VPS)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# 1. Verificar contenedor
echo "1. Estado del contenedor..."
if docker ps | grep -q "metin2-server"; then
    echo -e "   ${GREEN}✅ Contenedor corriendo${NC}"
    CONTAINER_ID=$(docker ps | grep "metin2-server" | awk '{print $1}')
    echo "   ID: $CONTAINER_ID"
else
    echo -e "   ${RED}❌ Contenedor NO está corriendo${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 2. Verificar puerto
echo "2. Puerto $EXPECTED_PORT..."
if ss -tuln | grep -q ":$EXPECTED_PORT"; then
    echo -e "   ${GREEN}✅ Puerto $EXPECTED_PORT está escuchando${NC}"
    ss -tuln | grep ":$EXPECTED_PORT"
else
    echo -e "   ${RED}❌ Puerto $EXPECTED_PORT NO está escuchando${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 3. Verificar .env
echo "3. Configuración en .env..."
if [ -f ".env" ]; then
    ENV_IP=$(grep "^PUBLIC_IP=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    ENV_PORT=$(grep "^GAME_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    ENV_AUTH=$(grep "^GAME_AUTH_SERVER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    
    echo "   PUBLIC_IP: $ENV_IP"
    echo "   GAME_PORT: $ENV_PORT"
    echo "   GAME_AUTH_SERVER: $ENV_AUTH"
    
    if [ "$ENV_IP" = "$EXPECTED_IP" ]; then
        echo -e "   ${GREEN}✅ IP correcta${NC}"
    else
        echo -e "   ${RED}❌ IP incorrecta (esperada: $EXPECTED_IP)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ "$ENV_PORT" = "$EXPECTED_PORT" ]; then
        echo -e "   ${GREEN}✅ Puerto correcto${NC}"
    else
        echo -e "   ${RED}❌ Puerto incorrecto (esperado: $EXPECTED_PORT)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ "$ENV_AUTH" = "$EXPECTED_AUTH" ]; then
        echo -e "   ${GREEN}✅ AUTH_SERVER correcto${NC}"
    else
        echo -e "   ${RED}❌ AUTH_SERVER incorrecto (esperado: $EXPECTED_AUTH)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "   ${RED}❌ Archivo .env no encontrado${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 4. Verificar game.conf
echo "4. Configuración en game.conf..."
if docker ps | grep -q "metin2-server"; then
    GAME_CONF_IP=$(docker exec metin2-server cat /opt/metin2/gamefiles/conf/game.conf 2>/dev/null | grep "^PUBLIC_IP:" | awk '{print $2}' || echo "")
    GAME_CONF_PORT=$(docker exec metin2-server cat /opt/metin2/gamefiles/conf/game.conf 2>/dev/null | grep "^PORT:" | awk '{print $2}' || echo "")
    GAME_CONF_AUTH=$(docker exec metin2-server cat /opt/metin2/gamefiles/conf/game.conf 2>/dev/null | grep "^AUTH_SERVER:" | awk '{print $2}' || echo "")
    
    if [ -z "$GAME_CONF_IP" ] && [ -z "$GAME_CONF_PORT" ]; then
        echo -e "   ${YELLOW}⚠️  game.conf parece estar vacío o no se puede leer${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "   PUBLIC_IP: $GAME_CONF_IP"
        echo "   PORT: $GAME_CONF_PORT"
        echo "   AUTH_SERVER: $GAME_CONF_AUTH"
        
        if [ "$GAME_CONF_IP" = "$EXPECTED_IP" ]; then
            echo -e "   ${GREEN}✅ IP correcta${NC}"
        else
            echo -e "   ${YELLOW}⚠️  IP en game.conf diferente (puede ser normal si se auto-detecta)${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
        
        if [ "$GAME_CONF_PORT" = "$EXPECTED_PORT" ]; then
            echo -e "   ${GREEN}✅ Puerto correcto${NC}"
        else
            echo -e "   ${RED}❌ Puerto incorrecto${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        
        if [ "$GAME_CONF_AUTH" = "$EXPECTED_AUTH" ]; then
            echo -e "   ${GREEN}✅ AUTH_SERVER correcto${NC}"
        else
            echo -e "   ${YELLOW}⚠️  AUTH_SERVER diferente${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
else
    echo -e "   ${RED}❌ No se puede verificar (contenedor no está corriendo)${NC}"
fi
echo ""

# 5. Verificar firewall
echo "5. Firewall..."
if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "$EXPECTED_PORT"; then
        echo -e "   ${GREEN}✅ Puerto $EXPECTED_PORT permitido${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Puerto $EXPECTED_PORT no aparece en reglas (puede estar abierto de otra forma)${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "   ${YELLOW}⚠️  UFW no disponible${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 6. Verificar logs
echo "6. Logs del servidor..."
if docker ps | grep -q "metin2-server"; then
    if docker logs --tail 100 metin2-server 2>&1 | grep -q "TCP listening on.*$EXPECTED_PORT"; then
        echo -e "   ${GREEN}✅ Servidor está escuchando en puerto $EXPECTED_PORT${NC}"
        docker logs --tail 100 metin2-server 2>&1 | grep "TCP listening" | tail -1
    else
        echo -e "   ${RED}❌ No se encontró 'TCP listening' en los logs${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Verificar errores críticos
    CRITICAL_ERRORS=$(docker logs --tail 200 metin2-server 2>&1 | grep -E "CRITICAL|FATAL|FAILED" | wc -l)
    if [ "$CRITICAL_ERRORS" -gt 0 ]; then
        echo -e "   ${YELLOW}⚠️  Se encontraron $CRITICAL_ERRORS errores críticos en los logs${NC}"
        docker logs --tail 200 metin2-server 2>&1 | grep -E "CRITICAL|FATAL|FAILED" | tail -3
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "   ${RED}❌ No se pueden verificar logs (contenedor no está corriendo)${NC}"
fi
echo ""

# 7. Verificar conectividad
echo "7. Conectividad de red..."
if timeout 3 bash -c "echo > /dev/tcp/$EXPECTED_IP/$EXPECTED_PORT" 2>/dev/null; then
    echo -e "   ${GREEN}✅ Puerto $EXPECTED_PORT es accesible${NC}"
else
    echo -e "   ${YELLOW}⚠️  No se pudo verificar conectividad (puede ser normal)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 8. Verificar cuenta de prueba
echo "8. Cuenta de prueba..."
if docker ps | grep -q "metin2-server"; then
    MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2")
    MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "localhost")
    MYSQL_PORT=$(grep "^MYSQL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "3306")
    
    export MYSQL_PWD="$MYSQL_PASSWORD"
    ACCOUNT_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "SELECT COUNT(*) FROM account WHERE login='test';" 2>/dev/null | tail -1 || echo "0")
    unset MYSQL_PWD
    
    if [ "$ACCOUNT_EXISTS" -gt 0 ]; then
        echo -e "   ${GREEN}✅ Cuenta 'test' existe${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Cuenta 'test' no encontrada${NC}"
        echo "   Puedes crearla con: bash crear-cuenta-prueba.sh"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "   ${YELLOW}⚠️  No se puede verificar (contenedor no está corriendo)${NC}"
fi
echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}PARTE 2: VERIFICACIÓN DEL CLIENTE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# 9. Verificar serverinfo.py en el repositorio
echo "9. Configuración del cliente (serverinfo.py en repositorio)..."
SERVERINFO_FILE="Client-20251206T130044Z-3-001/Client/Client/Client/Eternexus/root/serverinfo.py"

if [ -f "$SERVERINFO_FILE" ]; then
    SERVERINFO_IP=$(grep "SERVER_IP[[:space:]]*=" "$SERVERINFO_FILE" | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "")
    SERVERINFO_PORT=$(grep "PORT_1[[:space:]]*=" "$SERVERINFO_FILE" | head -1 | sed 's/.*= *\([0-9]*\).*/\1/' || echo "")
    SERVERINFO_AUTH=$(grep "PORT_AUTH[[:space:]]*=" "$SERVERINFO_FILE" | head -1 | sed 's/.*= *\([0-9]*\).*/\1/' || echo "")
    
    echo "   SERVER_IP: $SERVERINFO_IP"
    echo "   PORT_1: $SERVERINFO_PORT"
    echo "   PORT_AUTH: $SERVERINFO_AUTH"
    
    if [ "$SERVERINFO_IP" = "$EXPECTED_IP" ]; then
        echo -e "   ${GREEN}✅ IP correcta${NC}"
    else
        echo -e "   ${RED}❌ IP incorrecta (esperada: $EXPECTED_IP)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ "$SERVERINFO_PORT" = "$EXPECTED_PORT" ]; then
        echo -e "   ${GREEN}✅ PORT_1 correcto${NC}"
    else
        echo -e "   ${RED}❌ PORT_1 incorrecto (esperado: $EXPECTED_PORT)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ "$SERVERINFO_AUTH" = "$EXPECTED_PORT" ]; then
        echo -e "   ${GREEN}✅ PORT_AUTH correcto (debe ser $EXPECTED_PORT)${NC}"
    else
        echo -e "   ${RED}❌ PORT_AUTH incorrecto (esperado: $EXPECTED_PORT, actual: $SERVERINFO_AUTH)${NC}"
        echo "   ⚠️  CRÍTICO: PORT_AUTH debe ser $EXPECTED_PORT, no 11000"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "   ${YELLOW}⚠️  serverinfo.py no encontrado en el repositorio${NC}"
    echo "   (Esto es normal si el cliente está en tu máquina Windows)"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Resumen final
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN FINAL${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ TODO ESTÁ CORRECTO${NC}"
    echo ""
    echo "📋 Configuración del servidor:"
    echo "   IP: $EXPECTED_IP"
    echo "   Puerto: $EXPECTED_PORT"
    echo "   AUTH_SERVER: $EXPECTED_AUTH"
    echo ""
    echo "📋 Configuración del cliente (en repositorio):"
    echo "   SERVER_IP: $SERVERINFO_IP"
    echo "   PORT_1: $SERVERINFO_PORT"
    echo "   PORT_AUTH: $SERVERINFO_AUTH"
    echo ""
    echo "🎮 El servidor está listo para recibir conexiones"
    echo ""
    echo "📝 Próximos pasos en Windows:"
    echo "   1. Verifica que serverinfo.py en tu cliente tenga PORT_AUTH = 12345"
    echo "   2. Reempaqueta root/ con EterNexus"
    echo "   3. Ejecuta Metin2Distribute.exe"
    echo "   4. Intenta conectarte con: test / test123"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  TODO CORRECTO PERO HAY $WARNINGS ADVERTENCIA(S)${NC}"
    echo ""
    echo "Las advertencias no son críticas, pero revisa los puntos mencionados arriba."
else
    echo -e "${RED}❌ SE ENCONTRARON $ERRORS ERROR(ES) Y $WARNINGS ADVERTENCIA(S)${NC}"
    echo ""
    echo "Revisa los errores mencionados arriba y corrígelos."
fi
echo ""

