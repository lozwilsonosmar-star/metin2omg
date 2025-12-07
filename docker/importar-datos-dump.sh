#!/bin/bash
# Script para importar datos desde los dumps SQL de metin2_mysql_dump
# Uso: bash docker/importar-datos-dump.sh

set -e

echo "=========================================="
echo "Importación de Datos desde Dumps SQL"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Obtener credenciales de MySQL desde .env si existe
if [ -f ".env" ]; then
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
    MYSQL_PORT=$(grep "^MYSQL_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "3306")
    MYSQL_USER=$(grep "^MYSQL_USER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "metin2")
    MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "changeme")
    
    # Convertir localhost a 127.0.0.1
    if [ "$MYSQL_HOST" = "localhost" ]; then
        MYSQL_HOST="127.0.0.1"
    fi
    
    echo -e "${YELLOW}Usando credenciales de .env${NC}"
    echo -e "${YELLOW}Host: ${MYSQL_HOST}:${MYSQL_PORT}${NC}"
    echo -e "${YELLOW}Usuario: ${MYSQL_USER}${NC}"
    echo ""
else
    echo -e "${RED}❌ No se encontró archivo .env${NC}"
    echo "   Por favor crea un archivo .env con las credenciales de MySQL"
    exit 1
fi

# Exportar contraseña para mysql
export MYSQL_PWD="$MYSQL_PASSWORD"

# Verificar que existen los dumps
DUMP_DIR="metin2_mysql_dump"
if [ ! -d "$DUMP_DIR" ]; then
    echo -e "${RED}❌ No se encontró el directorio $DUMP_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}📊 Paso 1: Importando datos de common.sql a metin2_common...${NC}"
if [ -f "$DUMP_DIR/common.sql" ]; then
    # Convertir INSERT INTO a INSERT IGNORE INTO para evitar errores de duplicados
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' "$DUMP_DIR/common.sql" | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common 2>&1 | \
        grep -v "already exists\|Duplicate entry" || true
    echo -e "${GREEN}✅ Datos de common importados${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró $DUMP_DIR/common.sql${NC}"
fi
echo ""

echo -e "${GREEN}📊 Paso 2: Importando datos de player.sql a metin2_player...${NC}"
if [ -f "$DUMP_DIR/player.sql" ]; then
    # Convertir INSERT INTO a INSERT IGNORE INTO para evitar errores de duplicados
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' "$DUMP_DIR/player.sql" | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player 2>&1 | \
        grep -v "already exists\|Duplicate entry" || true
    echo -e "${GREEN}✅ Datos de player importados${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró $DUMP_DIR/player.sql${NC}"
fi
echo ""

echo -e "${GREEN}📊 Paso 3: Importando datos de account.sql a metin2_account...${NC}"
if [ -f "$DUMP_DIR/account.sql" ]; then
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' "$DUMP_DIR/account.sql" | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_account 2>&1 | \
        grep -v "already exists\|Duplicate entry" || true
    echo -e "${GREEN}✅ Datos de account importados${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró $DUMP_DIR/account.sql${NC}"
fi
echo ""

echo -e "${GREEN}📊 Paso 4: Importando datos de log.sql a metin2_log...${NC}"
if [ -f "$DUMP_DIR/log.sql" ]; then
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' "$DUMP_DIR/log.sql" | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_log 2>&1 | \
        grep -v "already exists\|Duplicate entry" || true
    echo -e "${GREEN}✅ Datos de log importados${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró $DUMP_DIR/log.sql${NC}"
fi
echo ""

# Verificar que los datos se importaron correctamente
echo -e "${GREEN}🔍 Paso 5: Verificando datos importados...${NC}"

# Verificar skill_proto
SKILL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM skill_proto;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   skill_proto: ${SKILL_COUNT} registros${NC}"

# Verificar refine_proto
REFINE_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM refine_proto;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   refine_proto: ${REFINE_COUNT} registros${NC}"

# Verificar shop
SHOP_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM shop;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   shop: ${SHOP_COUNT} registros${NC}"

# Verificar item_attr
ITEM_ATTR_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM item_attr;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   item_attr: ${ITEM_ATTR_COUNT} registros${NC}"

# Verificar locale
LOCALE_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -sN -e "SELECT COUNT(*) FROM locale;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   locale: ${LOCALE_COUNT} registros${NC}"

echo ""
echo -e "${GREEN}✅ Importación completada!${NC}"

unset MYSQL_PWD

