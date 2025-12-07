#!/bin/bash
# Script para verificar y corregir el mapeo de bases de datos
# Compara lo que el servidor espera vs lo que realmente existe

echo "=========================================="
echo "Verificación de Mapeo de Bases de Datos"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    exit 1
}

# Obtener credenciales
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

source .env 2>/dev/null || true

MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USER=${MYSQL_USER:-metin2}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-Osmar2405}

if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

export MYSQL_PWD="$MYSQL_PASSWORD"

echo -e "${YELLOW}Conectando a MySQL...${NC}"
echo ""

# ============================================================
# 1. BASES DE DATOS ESPERADAS POR EL SERVIDOR
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}1. BASES DE DATOS ESPERADAS POR EL SERVIDOR${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ENV_DB_ACCOUNT=$(grep "^MYSQL_DB_ACCOUNT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2_account")
ENV_DB_COMMON=$(grep "^MYSQL_DB_COMMON=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2_common")
ENV_DB_PLAYER=$(grep "^MYSQL_DB_PLAYER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2_player")
ENV_DB_LOG=$(grep "^MYSQL_DB_LOG=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2_log")

echo "Según .env:"
echo "   MYSQL_DB_ACCOUNT: $ENV_DB_ACCOUNT"
echo "   MYSQL_DB_COMMON: $ENV_DB_COMMON"
echo "   MYSQL_DB_PLAYER: $ENV_DB_PLAYER"
echo "   MYSQL_DB_LOG: $ENV_DB_LOG"
echo ""

# ============================================================
# 2. BASES DE DATOS QUE REALMENTE EXISTEN
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}2. BASES DE DATOS QUE REALMENTE EXISTEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ALL_DATABASES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys")

echo "Bases de datos encontradas:"
echo "$ALL_DATABASES" | while read db; do
    if [ -n "$db" ]; then
        echo "   - $db"
    fi
done

echo ""

# ============================================================
# 3. VERIFICAR MAPEO
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3. VERIFICANDO MAPEO${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ERRORS=0

# Verificar cada base de datos esperada
for expected_db in "$ENV_DB_ACCOUNT" "$ENV_DB_COMMON" "$ENV_DB_PLAYER" "$ENV_DB_LOG"; do
    EXISTS=$(echo "$ALL_DATABASES" | grep -c "^$expected_db$" || echo "0")
    
    if [ "$EXISTS" -gt 0 ]; then
        echo -e "${GREEN}✅ $expected_db existe${NC}"
    else
        echo -e "${RED}❌ $expected_db NO existe${NC}"
        
        # Buscar variantes posibles
        VARIANT1=$(echo "$expected_db" | sed 's/metin2_//')
        VARIANT2=$(echo "$expected_db" | sed 's/^metin2_//')
        
        if echo "$ALL_DATABASES" | grep -q "^$VARIANT1$"; then
            echo -e "${YELLOW}   ⚠️  Pero existe: $VARIANT1${NC}"
            echo -e "${YELLOW}   💡 El servidor espera '$expected_db' pero las tablas están en '$VARIANT1'${NC}"
            ((ERRORS++))
        fi
    fi
done

echo ""

# ============================================================
# 4. VERIFICAR TABLAS CRÍTICAS
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}4. VERIFICANDO TABLAS CRÍTICAS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Tablas críticas y dónde deberían estar
declare -A CRITICAL_TABLES=(
    ["account:metin2_account"]="account"
    ["player_index:metin2_account"]="player_index"
    ["player:metin2_player"]="player"
    ["item:metin2_player"]="item"
    ["quest:metin2_player"]="quest"
    ["affect:metin2_player"]="affect"
    ["skill_proto:metin2_player"]="skill_proto"
    ["refine_proto:metin2_player"]="refine_proto"
    ["locale:metin2_common"]="locale"
)

for key in "${!CRITICAL_TABLES[@]}"; do
    IFS=':' read -r table expected_db <<< "$key"
    
    echo -e "${YELLOW}Buscando: $table en $expected_db${NC}"
    
    # Buscar en la base de datos esperada
    EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$expected_db" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "$table" || echo "0")
    
    if [ "$EXISTS" -gt 0 ]; then
        ROW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$expected_db" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "?")
        echo -e "   ${GREEN}✅ Encontrada en $expected_db ($ROW_COUNT registros)${NC}"
    else
        echo -e "   ${RED}❌ NO encontrada en $expected_db${NC}"
        
        # Buscar en otras bases de datos
        FOUND_IN=""
        for db in $ALL_DATABASES; do
            if [ -n "$db" ]; then
                EXISTS_OTHER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "$table" || echo "0")
                if [ "$EXISTS_OTHER" -gt 0 ]; then
                    FOUND_IN="$db"
                    break
                fi
            fi
        done
        
        if [ -n "$FOUND_IN" ]; then
            echo -e "   ${YELLOW}   ⚠️  Pero está en: $FOUND_IN${NC}"
            echo -e "   ${YELLOW}   💡 PROBLEMA DE MAPEO: El servidor espera '$table' en '$expected_db' pero está en '$FOUND_IN'${NC}"
            ((ERRORS++))
        else
            echo -e "   ${RED}   ❌ No encontrada en ninguna base de datos${NC}"
            ((ERRORS++))
        fi
    fi
    echo ""
done

# ============================================================
# RESUMEN Y RECOMENDACIONES
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las tablas están correctamente mapeadas${NC}"
    echo ""
    echo "El servidor debería poder encontrar todas las tablas necesarias."
else
    echo -e "${RED}❌ Se encontraron $ERRORS problema(s) de mapeo${NC}"
    echo ""
    echo -e "${YELLOW}Posibles soluciones:${NC}"
    echo ""
    echo "1. Si las bases de datos tienen nombres diferentes (ej: 'account' vs 'metin2_account'):"
    echo "   Opción A: Renombrar las bases de datos:"
    echo "      mysql -u root -p -e \"RENAME DATABASE account TO metin2_account;\""
    echo ""
    echo "   Opción B: Cambiar .env para usar los nombres existentes:"
    echo "      MYSQL_DB_ACCOUNT=account"
    echo "      MYSQL_DB_COMMON=common"
    echo "      MYSQL_DB_PLAYER=player"
    echo "      MYSQL_DB_LOG=log"
    echo ""
    echo "2. Si las tablas están en bases de datos incorrectas:"
    echo "   Mover las tablas a las bases de datos correctas o"
    echo "   Actualizar el código del servidor para buscar en las bases correctas"
    echo ""
fi

unset MYSQL_PWD

