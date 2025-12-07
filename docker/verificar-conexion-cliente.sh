#!/bin/bash
# Script para verificar que todo está listo para conectar el cliente
# Uso: bash docker/verificar-conexion-cliente.sh

set -e

echo "=========================================="
echo "Verificación de Conexión del Cliente"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Función para verificar
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        ERRORS=$((ERRORS + 1))
    fi
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

# 1. Verificar firewall
echo -e "${GREEN}🔍 Verificando firewall...${NC}"
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "12345/tcp"; then
        check "Puerto 12345 abierto en firewall"
    else
        warn "Puerto 12345 NO está abierto en firewall"
        echo "   Ejecutar: sudo ufw allow 12345/tcp"
    fi
    
    if ufw status | grep -q "13200/tcp"; then
        check "Puerto 13200 abierto en firewall"
    else
        warn "Puerto 13200 NO está abierto en firewall"
        echo "   Ejecutar: sudo ufw allow 13200/tcp"
    fi
    
    if ufw status | grep -q "8888/tcp"; then
        check "Puerto 8888 abierto en firewall"
    else
        warn "Puerto 8888 NO está abierto en firewall"
        echo "   Ejecutar: sudo ufw allow 8888/tcp"
    fi
else
    warn "UFW no está instalado. Verificar firewall manualmente"
fi
echo ""

# 2. Verificar archivo .env
echo -e "${GREEN}🔍 Verificando archivo .env...${NC}"
if [ -f ".env" ]; then
    check "Archivo .env existe"
    
    # Verificar PUBLIC_IP
    PUBLIC_IP=$(grep "^PUBLIC_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "")
    if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "127.0.0.1" ] && [ "$PUBLIC_IP" != "localhost" ]; then
        check "PUBLIC_IP configurado: $PUBLIC_IP"
    else
        warn "PUBLIC_IP no está configurado correctamente (debe ser la IP pública del VPS)"
    fi
    
    # Verificar GAME_PORT
    GAME_PORT=$(grep "^GAME_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "")
    if [ "$GAME_PORT" = "12345" ]; then
        check "GAME_PORT configurado: $GAME_PORT"
    else
        warn "GAME_PORT no es 12345 (actual: $GAME_PORT)"
    fi
    
    # Verificar AUTH_SERVER
    AUTH_SERVER=$(grep "^GAME_AUTH_SERVER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "")
    if [ -n "$AUTH_SERVER" ]; then
        check "GAME_AUTH_SERVER configurado: $AUTH_SERVER"
    else
        warn "GAME_AUTH_SERVER no está configurado"
    fi
else
    warn "Archivo .env no existe"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 3. Verificar contenedor Docker
echo -e "${GREEN}🔍 Verificando contenedor Docker...${NC}"
if docker ps | grep -q "metin2-server"; then
    check "Contenedor metin2-server está corriendo"
    
    # Verificar que está escuchando en el puerto
    if docker exec metin2-server netstat -tlnp 2>/dev/null | grep -q ":12345"; then
        check "Servidor escuchando en puerto 12345"
    else
        warn "Servidor NO está escuchando en puerto 12345"
    fi
else
    warn "Contenedor metin2-server NO está corriendo"
    echo "   Ejecutar: docker start metin2-server"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 4. Verificar logs del servidor (últimas 20 líneas)
echo -e "${GREEN}🔍 Verificando logs del servidor...${NC}"
if docker logs metin2-server 2>&1 | tail -20 | grep -q "TCP listening"; then
    check "Servidor inició correctamente (TCP listening encontrado)"
else
    warn "No se encontró 'TCP listening' en los logs"
    echo "   Ver logs: docker logs metin2-server"
fi

# Verificar errores críticos
if docker logs metin2-server 2>&1 | tail -50 | grep -q "Table.*doesn't exist"; then
    warn "Se encontraron errores de tablas faltantes en los logs"
fi

if docker logs metin2-server 2>&1 | tail -50 | grep -q "AUTH_SERVER.*syntax error"; then
    warn "Error de configuración AUTH_SERVER en los logs"
fi
echo ""

# 5. Verificar archivos del juego
echo -e "${GREEN}🔍 Verificando archivos del juego...${NC}"
if docker exec metin2-server test -f /app/gamefiles/conf/item_proto.txt 2>/dev/null; then
    check "item_proto.txt existe"
else
    warn "item_proto.txt NO existe"
fi

if docker exec metin2-server test -f /app/gamefiles/conf/mob_proto.txt 2>/dev/null; then
    check "mob_proto.txt existe"
else
    warn "mob_proto.txt NO existe"
fi
echo ""

# 6. Verificar cuenta de prueba
echo -e "${GREEN}🔍 Verificando cuenta de prueba...${NC}"
if [ -f ".env" ]; then
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
    MYSQL_PORT=$(grep "^MYSQL_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "3306")
    MYSQL_USER=$(grep "^MYSQL_USER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "metin2")
    MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "changeme")
    
    if [ "$MYSQL_HOST" = "localhost" ]; then
        MYSQL_HOST="127.0.0.1"
    fi
    
    export MYSQL_PWD="$MYSQL_PASSWORD"
    
    TEST_ACCOUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -sN -e "SELECT COUNT(*) FROM account WHERE login='test';" 2>/dev/null || echo "0")
    unset MYSQL_PWD
    
    if [ "$TEST_ACCOUNT" -gt 0 ]; then
        check "Cuenta de prueba 'test' existe"
    else
        warn "Cuenta de prueba 'test' NO existe"
        echo "   Crear con: mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p metin2_account"
        echo "   INSERT INTO account (login, password, social_id, status) VALUES ('test', SHA1('test123'), 'A', 'OK');"
    fi
else
    warn "No se puede verificar cuenta (archivo .env no encontrado)"
fi
echo ""

# Resumen
echo "=========================================="
echo "Resumen"
echo "=========================================="
echo -e "${GREEN}✅ Verificaciones exitosas: $((10 - ERRORS - WARNINGS))${NC}"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Advertencias: $WARNINGS${NC}"
fi
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Errores: $ERRORS${NC}"
    echo ""
    echo -e "${RED}⚠️  Hay errores que deben corregirse antes de conectar el cliente${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}✅ Todo parece estar configurado correctamente!${NC}"
    echo ""
    echo "📋 Información para configurar el cliente:"
    echo "   IP del servidor: $PUBLIC_IP"
    echo "   Puerto del juego: $GAME_PORT"
    echo ""
    echo "🎮 Próximos pasos:"
    echo "   1. Configurar el cliente con IP: $PUBLIC_IP y Puerto: $GAME_PORT"
    echo "   2. Intentar conectarse con usuario: test / contraseña: test123"
    exit 0
fi

