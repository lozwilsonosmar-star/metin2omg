#!/bin/bash
# Script para corregir problemas críticos del servidor
# - AUTH_SERVER: debe ser "master" para servidor standalone
# - skill_proto: verificar e importar datos si está vacía
# Uso: bash corregir-problemas-servidor.sh

set -e

echo "=========================================="
echo "Corrección de Problemas del Servidor"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || exit 1

# 1. Corregir AUTH_SERVER en .env
echo -e "${GREEN}1. Corrigiendo AUTH_SERVER...${NC}"

if [ ! -f ".env" ]; then
    echo -e "${RED}   ❌ Archivo .env no encontrado${NC}"
    exit 1
fi

# Hacer backup
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Verificar y corregir AUTH_SERVER
AUTH_SERVER=$(grep "^GAME_AUTH_SERVER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

if [ -z "$AUTH_SERVER" ] || [ "$AUTH_SERVER" = "localhost" ]; then
    echo -e "${YELLOW}   ⚠️  AUTH_SERVER está vacío o es 'localhost'${NC}"
    echo -e "${GREEN}   ✅ Cambiando a 'master' (servidor standalone)${NC}"
    
    # Reemplazar o agregar GAME_AUTH_SERVER
    if grep -q "^GAME_AUTH_SERVER=" .env; then
        sed -i 's/^GAME_AUTH_SERVER=.*/GAME_AUTH_SERVER=master/' .env
    else
        echo "GAME_AUTH_SERVER=master" >> .env
    fi
    
    echo -e "${GREEN}   ✅ AUTH_SERVER corregido${NC}"
else
    echo -e "${GREEN}   ✅ AUTH_SERVER ya está configurado: $AUTH_SERVER${NC}"
fi
echo ""

# 2. Verificar skill_proto
echo -e "${GREEN}2. Verificando datos de skill_proto...${NC}"

# Obtener credenciales de .env
MYSQL_HOST=$(grep "^MYSQL_HOST=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "localhost")
MYSQL_PORT=$(grep "^MYSQL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "3306")
MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2")
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
MYSQL_DB_PLAYER=$(grep "^MYSQL_DB_PLAYER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2_player")

# Convertir localhost a 127.0.0.1 para conexión TCP
if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

# Verificar si skill_proto tiene datos
SKILL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DB_PLAYER" -se "SELECT COUNT(*) FROM skill_proto;" 2>/dev/null || echo "0")

if [ "$SKILL_COUNT" = "0" ] || [ -z "$SKILL_COUNT" ]; then
    echo -e "${RED}   ❌ skill_proto está vacía (0 registros)${NC}"
    echo -e "${YELLOW}   ⚠️  Intentando importar datos...${NC}"
    
    # Verificar si existe el script de importación
    if [ -f "docker/importar-datos-dump.sh" ]; then
        echo -e "${GREEN}   ✅ Ejecutando script de importación...${NC}"
        bash docker/importar-datos-dump.sh
        
        # Verificar nuevamente
        SKILL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DB_PLAYER" -se "SELECT COUNT(*) FROM skill_proto;" 2>/dev/null || echo "0")
        
        if [ "$SKILL_COUNT" != "0" ] && [ -n "$SKILL_COUNT" ]; then
            echo -e "${GREEN}   ✅ Datos importados correctamente: $SKILL_COUNT registros${NC}"
        else
            echo -e "${RED}   ❌ La importación falló o no hay datos disponibles${NC}"
            echo -e "${YELLOW}   ⚠️  Necesitas importar manualmente los datos de skill_proto${NC}"
        fi
    else
        echo -e "${RED}   ❌ Script de importación no encontrado${NC}"
        echo -e "${YELLOW}   ⚠️  Necesitas importar manualmente los datos de skill_proto${NC}"
    fi
else
    echo -e "${GREEN}   ✅ skill_proto tiene datos: $SKILL_COUNT registros${NC}"
fi
echo ""

# 3. Verificar otras tablas críticas
echo -e "${GREEN}3. Verificando otras tablas críticas...${NC}"

check_table() {
    local TABLE_NAME=$1
    local COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DB_PLAYER" -se "SELECT COUNT(*) FROM $TABLE_NAME;" 2>/dev/null || echo "0")
    
    if [ "$COUNT" = "0" ] || [ -z "$COUNT" ]; then
        echo -e "${YELLOW}   ⚠️  $TABLE_NAME: vacía (0 registros)${NC}"
        return 1
    else
        echo -e "${GREEN}   ✅ $TABLE_NAME: $COUNT registros${NC}"
        return 0
    fi
}

check_table "refine_proto"
check_table "shop"
check_table "item_attr"
check_table "banword"

echo ""

# 4. Resumen y reinicio
echo "=========================================="
echo "RESUMEN"
echo "=========================================="

echo -e "${GREEN}✅ AUTH_SERVER corregido en .env${NC}"
echo ""

if [ "$SKILL_COUNT" = "0" ] || [ -z "$SKILL_COUNT" ]; then
    echo -e "${RED}❌ skill_proto aún está vacía${NC}"
    echo ""
    echo "Necesitas importar los datos manualmente:"
    echo "   1. Verifica que existan los archivos SQL dump en metin2_mysql_dump/"
    echo "   2. Ejecuta: bash docker/importar-datos-dump.sh"
    echo ""
else
    echo -e "${GREEN}✅ skill_proto tiene datos${NC}"
fi

echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE: Debes reiniciar el contenedor para aplicar los cambios${NC}"
echo ""
read -p "¿Deseas reiniciar el contenedor ahora? (S/n): " REINICIAR

if [[ ! "$REINICIAR" =~ ^[Nn]$ ]]; then
    echo ""
    echo -e "${GREEN}🔄 Reiniciando contenedor...${NC}"
    docker restart metin2-server
    echo -e "${GREEN}✅ Contenedor reiniciado${NC}"
    echo ""
    echo "Espera 30-60 segundos y verifica:"
    echo "   bash verificar-estado-servidor.sh"
else
    echo ""
    echo "Reinicia manualmente cuando estés listo:"
    echo "   docker restart metin2-server"
fi

echo ""

