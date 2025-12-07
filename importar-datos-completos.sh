#!/bin/bash
# Script para importar datos completos desde los dumps SQL
# Uso: bash importar-datos-completos.sh

set -e

echo "=========================================="
echo "Importación de Datos Completos"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /opt/metin2omg

# Verificar que existen los dumps
if [ ! -d "metin2_mysql_dump" ]; then
    echo -e "${RED}❌ No se encontró el directorio metin2_mysql_dump${NC}"
    echo "   Por favor sube los archivos SQL primero"
    exit 1
fi

# Obtener credenciales
MYSQL_HOST=$(grep "^MYSQL_HOST=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "localhost")
MYSQL_PORT=$(grep "^MYSQL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "3306")
MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2")
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

export MYSQL_PWD="$MYSQL_PASSWORD"

echo -e "${YELLOW}Importando datos desde metin2_mysql_dump/...${NC}"
echo ""

# Importar player.sql (contiene skill_proto, refine_proto, etc.)
if [ -f "metin2_mysql_dump/player.sql" ]; then
    echo -e "${GREEN}📊 Importando player.sql a metin2_player...${NC}"
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' metin2_mysql_dump/player.sql | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player 2>&1 | \
        grep -v "already exists\|Duplicate entry\|Warning\|Note" || true
    echo -e "${GREEN}✅ player.sql importado${NC}"
else
    echo -e "${RED}❌ No se encontró player.sql${NC}"
fi
echo ""

# Importar common.sql
if [ -f "metin2_mysql_dump/common.sql" ]; then
    echo -e "${GREEN}📊 Importando common.sql a metin2_common...${NC}"
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' metin2_mysql_dump/common.sql | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common 2>&1 | \
        grep -v "already exists\|Duplicate entry\|Warning\|Note" || true
    echo -e "${GREEN}✅ common.sql importado${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró common.sql${NC}"
fi
echo ""

# Importar account.sql
if [ -f "metin2_mysql_dump/account.sql" ]; then
    echo -e "${GREEN}📊 Importando account.sql a metin2_account...${NC}"
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' metin2_mysql_dump/account.sql | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_account 2>&1 | \
        grep -v "already exists\|Duplicate entry\|Warning\|Note" || true
    echo -e "${GREEN}✅ account.sql importado${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró account.sql${NC}"
fi
echo ""

# Verificar resultados
echo -e "${GREEN}🔍 Verificando datos importados...${NC}"

SKILL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM skill_proto;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   skill_proto: ${SKILL_COUNT} registros${NC}"

REFINE_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM refine_proto;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   refine_proto: ${REFINE_COUNT} registros${NC}"

SHOP_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM shop;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   shop: ${SHOP_COUNT} registros${NC}"

ITEM_ATTR_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM item_attr;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   item_attr: ${ITEM_ATTR_COUNT} registros${NC}"

echo ""
if [ "$SKILL_COUNT" -gt "1" ]; then
    echo -e "${GREEN}✅ Datos completos importados correctamente!${NC}"
else
    echo -e "${YELLOW}⚠️  skill_proto aún tiene pocos registros. Verifica que player.sql se importó correctamente.${NC}"
fi

unset MYSQL_PWD

echo ""

