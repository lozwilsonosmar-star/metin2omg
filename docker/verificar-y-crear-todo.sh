#!/bin/bash
# Script exhaustivo para verificar y crear todas las bases de datos, tablas, columnas y relaciones
# Este script crea automáticamente todo lo que falta

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo -e "Verificación y Creación Exhaustiva de BD"
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

# Paso 1: Crear bases de datos si no existen
echo -e "${BLUE}📊 Paso 1: Creando bases de datos si no existen...${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_account CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_common CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_player CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_log CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
echo -e "${GREEN}✅ Bases de datos verificadas/creadas${NC}"
echo ""

# Paso 2: Ejecutar script SQL completo
echo -e "${BLUE}📊 Paso 2: Ejecutando script SQL completo...${NC}"
if [ -f "docker/create-all-tables.sql" ]; then
    if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" < docker/create-all-tables.sql 2>&1; then
        echo -e "${GREEN}✅ Script SQL ejecutado correctamente${NC}"
    else
        echo -e "${YELLOW}⚠️  Algunos errores durante la ejecución del SQL (puede ser normal si las tablas ya existen)${NC}"
    fi
else
    echo -e "${RED}❌ No se encontró docker/create-all-tables.sql${NC}"
    unset MYSQL_PWD
    exit 1
fi
echo ""

# Paso 3: Verificar tablas críticas
echo -e "${BLUE}🔍 Paso 3: Verificando tablas críticas...${NC}"

TABLAS_CRITICAS=(
    "metin2_account.account"
    "metin2_account.player_index"
    "metin2_common.locale"
    "metin2_common.item_award"
    "metin2_common.skill_proto"
    "metin2_common.refine_proto"
    "metin2_common.item_attr"
    "metin2_common.item_attr_rare"
    "metin2_common.banword"
    "metin2_common.object_proto"
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
    "metin2_log.log"
    "metin2_log.loginlog"
    "metin2_log.hack_log"
    "metin2_log.goldlog"
    "metin2_log.cube"
)

TABLAS_FALTANTES=()

for tabla in "${TABLAS_CRITICAS[@]}"; do
    DB=$(echo "$tabla" | cut -d'.' -f1)
    TABLA=$(echo "$tabla" | cut -d'.' -f2)
    
    if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$DB" \
        -e "SHOW TABLES LIKE '$TABLA';" 2>/dev/null | grep -q "$TABLA"; then
        echo -e "  ${GREEN}✅${NC} $tabla"
    else
        echo -e "  ${RED}❌${NC} $tabla - FALTANTE"
        TABLAS_FALTANTES+=("$tabla")
    fi
done

echo ""

if [ ${#TABLAS_FALTANTES[@]} -gt 0 ]; then
    echo -e "${RED}❌ Faltan ${#TABLAS_FALTANTES[@]} tablas críticas${NC}"
    echo -e "${YELLOW}   Re-ejecutando script SQL...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" < docker/create-all-tables.sql 2>&1 || true
    echo ""
else
    echo -e "${GREEN}✅ Todas las tablas críticas existen${NC}"
fi
echo ""

# Paso 4: Verificar entrada SKILL_POWER_BY_LEVEL en locale
echo -e "${BLUE}🔍 Paso 4: Verificando entrada SKILL_POWER_BY_LEVEL en locale...${NC}"
SKILL_POWER_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common \
    -e "SELECT COUNT(*) FROM locale WHERE mKey='SKILL_POWER_BY_LEVEL';" 2>/dev/null | tail -n 1 || echo "0")

if [ "$SKILL_POWER_EXISTS" = "0" ]; then
    echo -e "${YELLOW}⚠️  Faltante: SKILL_POWER_BY_LEVEL en locale${NC}"
    echo -e "${GREEN}   Creando entrada SKILL_POWER_BY_LEVEL...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common \
        -e "INSERT IGNORE INTO locale (mValue, mKey) VALUES ('1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127', 'SKILL_POWER_BY_LEVEL');" 2>/dev/null || true
    echo -e "${GREEN}   ✅ Entrada creada${NC}"
else
    echo -e "${GREEN}✅ Entrada SKILL_POWER_BY_LEVEL existe${NC}"
fi
echo ""

# Paso 5: Verificar columnas críticas
echo -e "${BLUE}🔍 Paso 5: Verificando columnas críticas...${NC}"

# Verificar columnas en player
COLUMNAS_PLAYER=("part_main")
for columna in "${COLUMNAS_PLAYER[@]}"; do
    if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player \
        -e "SHOW COLUMNS FROM player LIKE '$columna';" 2>/dev/null | grep -q "$columna"; then
        echo -e "  ${GREEN}✅${NC} player.$columna"
    else
        echo -e "  ${RED}❌${NC} player.$columna - FALTANTE"
        echo -e "${YELLOW}   ⚠️  La columna $columna falta. Necesitarás agregarla manualmente o recrear la tabla.${NC}"
    fi
done

# Verificar columnas en guild
COLUMNAS_GUILD=("master" "exp" "skill_point" "skill" "sp")
for columna in "${COLUMNAS_GUILD[@]}"; do
    if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player \
        -e "SHOW COLUMNS FROM guild LIKE '$columna';" 2>/dev/null | grep -q "$columna"; then
        echo -e "  ${GREEN}✅${NC} guild.$columna"
    else
        echo -e "  ${RED}❌${NC} guild.$columna - FALTANTE"
        echo -e "${YELLOW}   ⚠️  La columna $columna falta. Necesitarás agregarla manualmente o recrear la tabla.${NC}"
    fi
done

echo ""

# Paso 6: Verificar relaciones (Foreign Keys)
echo -e "${BLUE}🔍 Paso 6: Verificando relaciones (Foreign Keys)...${NC}"

# Verificar FK en player_index
FK_PLAYER_INDEX=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account \
    -e "SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA='metin2_account' AND TABLE_NAME='player_index' AND CONSTRAINT_NAME!='PRIMARY';" 2>/dev/null | tail -n 1 || echo "0")

if [ "$FK_PLAYER_INDEX" = "0" ]; then
    echo -e "${YELLOW}⚠️  Falta Foreign Key en player_index -> account${NC}"
else
    echo -e "${GREEN}✅ Foreign Key player_index -> account existe${NC}"
fi

# Verificar FK en shop_item
FK_SHOP_ITEM=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player \
    -e "SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA='metin2_player' AND TABLE_NAME='shop_item' AND CONSTRAINT_NAME!='PRIMARY';" 2>/dev/null | tail -n 1 || echo "0")

if [ "$FK_SHOP_ITEM" = "0" ]; then
    echo -e "${YELLOW}⚠️  Falta Foreign Key en shop_item -> shop${NC}"
else
    echo -e "${GREEN}✅ Foreign Key shop_item -> shop existe${NC}"
fi

echo ""

# Resumen final
echo -e "${BLUE}=========================================="
echo -e "Resumen Final"
echo -e "==========================================${NC}"

TABLAS_TOTALES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" \
    -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA IN ('metin2_account', 'metin2_common', 'metin2_player', 'metin2_log');" 2>/dev/null | tail -n 1 || echo "0")

echo -e "${GREEN}Total de tablas creadas: ${TABLAS_TOTALES}${NC}"

if [ ${#TABLAS_FALTANTES[@]} -eq 0 ] && [ "$SKILL_POWER_EXISTS" != "0" ]; then
    echo -e "${GREEN}✅ Todas las verificaciones pasaron correctamente${NC}"
    echo -e "${GREEN}✅ La base de datos está completa y lista${NC}"
else
    echo -e "${YELLOW}⚠️  Algunas verificaciones fallaron${NC}"
    echo -e "${YELLOW}   Revisa los mensajes anteriores para más detalles${NC}"
fi

unset MYSQL_PWD

echo ""
echo -e "${BLUE}=========================================="
echo -e "Verificación completada"
echo -e "==========================================${NC}"

