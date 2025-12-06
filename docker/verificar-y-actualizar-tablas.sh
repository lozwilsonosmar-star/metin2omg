#!/bin/bash
# Script para verificar y actualizar tablas y columnas faltantes
# Este script verifica que todas las tablas y columnas existan

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=========================================="
echo -e "Verificación Exhaustiva de Base de Datos"
echo -e "==========================================${NC}"
echo ""

# Obtener credenciales de MySQL desde .env
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ No se encontró archivo .env${NC}"
    exit 1
fi

MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
MYSQL_PORT=$(grep "^MYSQL_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "3306")
MYSQL_USER=$(grep "^MYSQL_USER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "metin2")
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "changeme")

# Convertir localhost a 127.0.0.1
if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

export MYSQL_PWD="$MYSQL_PASSWORD"

echo -e "${YELLOW}Conectando a MySQL en ${MYSQL_HOST}:${MYSQL_PORT} como ${MYSQL_USER}${NC}"
echo ""

# Verificar conexión
if ! mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: No se pudo conectar a MySQL${NC}"
    unset MYSQL_PWD
    exit 1
fi

echo -e "${GREEN}✅ Conexión a MySQL exitosa${NC}"
echo ""

# Ejecutar el script SQL completo (CREATE TABLE IF NOT EXISTS crea solo si no existen)
echo -e "${GREEN}📊 Ejecutando script SQL completo...${NC}"
if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" < docker/create-all-tables.sql; then
    echo -e "${GREEN}✅ Script SQL ejecutado correctamente${NC}"
else
    echo -e "${RED}❌ Error al ejecutar script SQL${NC}"
    unset MYSQL_PWD
    exit 1
fi

echo ""

# Verificar tablas críticas
echo -e "${GREEN}🔍 Verificando tablas críticas...${NC}"

TABLAS_CRITICAS=(
    "metin2_account.account"
    "metin2_account.player_index"
    "metin2_common.locale"
    "metin2_common.item_award"
    "metin2_player.player"
    "metin2_player.item"
    "metin2_player.quest"
    "metin2_player.affect"
    "metin2_player.guild"
    "metin2_player.guild_member"
    "metin2_player.item_proto"
    "metin2_player.mob_proto"
    "metin2_player.shop"
    "metin2_player.shop_item"
    "metin2_common.skill_proto"
    "metin2_common.refine_proto"
    "metin2_common.item_attr"
    "metin2_common.item_attr_rare"
    "metin2_common.banword"
    "metin2_common.object_proto"
)

TODAS_OK=true

for tabla in "${TABLAS_CRITICAS[@]}"; do
    DB=$(echo "$tabla" | cut -d'.' -f1)
    TABLA=$(echo "$tabla" | cut -d'.' -f2)
    
    if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$DB" \
        -e "SHOW TABLES LIKE '$TABLA';" 2>/dev/null | grep -q "$TABLA"; then
        echo -e "  ${GREEN}✅${NC} $tabla"
    else
        echo -e "  ${RED}❌${NC} $tabla - FALTANTE"
        TODAS_OK=false
    fi
done

echo ""

if [ "$TODAS_OK" = true ]; then
    echo -e "${GREEN}✅ Todas las tablas críticas existen${NC}"
else
    echo -e "${RED}❌ Algunas tablas críticas faltan${NC}"
    echo -e "${YELLOW}   Ejecuta el script SQL manualmente:${NC}"
    echo "   mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p < docker/create-all-tables.sql"
fi

echo ""

# Verificar columnas críticas en tabla player
echo -e "${GREEN}🔍 Verificando columnas críticas en tabla player...${NC}"

COLUMNAS_PLAYER=(
    "id"
    "account_id"
    "name"
    "part_main"
    "part_base"
    "part_hair"
    "horse_level"
    "horse_riding"
    "horse_hp"
    "horse_hp_droptime"
    "horse_stamina"
    "horse_skill_point"
)

TODAS_COLUMNAS_OK=true

for columna in "${COLUMNAS_PLAYER[@]}"; do
    if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player \
        -e "SHOW COLUMNS FROM player LIKE '$columna';" 2>/dev/null | grep -q "$columna"; then
        echo -e "  ${GREEN}✅${NC} player.$columna"
    else
        echo -e "  ${RED}❌${NC} player.$columna - FALTANTE"
        TODAS_COLUMNAS_OK=false
    fi
done

echo ""

# Verificar columnas críticas en tabla guild
echo -e "${GREEN}🔍 Verificando columnas críticas en tabla guild...${NC}"

COLUMNAS_GUILD=(
    "id"
    "name"
    "master"
    "sp"
    "level"
    "exp"
    "skill_point"
    "skill"
    "ladder_point"
    "win"
    "draw"
    "loss"
    "gold"
)

for columna in "${COLUMNAS_GUILD[@]}"; do
    if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player \
        -e "SHOW COLUMNS FROM guild LIKE '$columna';" 2>/dev/null | grep -q "$columna"; then
        echo -e "  ${GREEN}✅${NC} guild.$columna"
    else
        echo -e "  ${RED}❌${NC} guild.$columna - FALTANTE"
        TODAS_COLUMNAS_OK=false
    fi
done

echo ""

if [ "$TODAS_COLUMNAS_OK" = true ]; then
    echo -e "${GREEN}✅ Todas las columnas críticas existen${NC}"
else
    echo -e "${YELLOW}⚠️  Algunas columnas críticas faltan${NC}"
    echo -e "${YELLOW}   El script SQL usa CREATE TABLE IF NOT EXISTS${NC}"
    echo -e "${YELLOW}   Si las tablas ya existían, las columnas faltantes no se agregaron${NC}"
    echo -e "${YELLOW}   Necesitarás agregarlas manualmente o recrear las tablas${NC}"
fi

unset MYSQL_PWD

echo ""
echo -e "${GREEN}=========================================="
echo -e "Verificación completada"
echo -e "==========================================${NC}"

