#!/bin/bash
# Script para verificar que todas las tablas estén en las bases de datos correctas
# Compara dónde el servidor busca las tablas vs dónde están realmente

echo "=========================================="
echo "Verificación Completa de Mapeo de Tablas"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

export MYSQL_PWD="proyectalean"
MYSQL_USER="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"

# Verificar que el contenedor esté corriendo
if ! docker ps | grep -q "metin2-server"; then
    echo -e "${RED}❌ El contenedor metin2-server no está corriendo${NC}"
    exit 1
fi

# Buscar game.conf
GAME_CONF_PATH=$(docker exec metin2-server find / -name "game.conf" 2>/dev/null | head -1)

if [ -z "$GAME_CONF_PATH" ]; then
    echo -e "${RED}❌ game.conf no encontrado${NC}"
    exit 1
fi

GAME_CONF_CONTENT=$(docker exec metin2-server cat "$GAME_CONF_PATH" 2>/dev/null)

# Extraer bases de datos
PLAYER_DB=$(echo "$GAME_CONF_CONTENT" | grep "^PLAYER_SQL:" | awk '{print $5}')
COMMON_DB=$(echo "$GAME_CONF_CONTENT" | grep "^COMMON_SQL:" | awk '{print $5}')
LOG_DB=$(echo "$GAME_CONF_CONTENT" | grep "^LOG_SQL:" | awk '{print $5}')

echo -e "${BLUE}Bases de datos según game.conf:${NC}"
echo "   PLAYER_SQL → $PLAYER_DB"
echo "   COMMON_SQL → $COMMON_DB"
echo "   LOG_SQL → $LOG_DB"
echo ""

# Definir mapeo esperado según el código del servidor
# PLAYER_SQL debe tener:
declare -a PLAYER_TABLES=(
    "account"           # Buscada en input_auth.cpp para login
    "player"            # Datos de personajes
    "item"              # Items de personajes
    "quest"             # Quests de personajes
    "affect"            # Buffs/efectos de personajes
    "skill_proto"       # Prototipos de habilidades
    "refine_proto"      # Prototipos de refinamiento
    "shop"              # Tiendas
    "player_index"      # Índice de personajes por cuenta
    "banword"           # Palabras prohibidas
)

# COMMON_SQL debe tener:
declare -a COMMON_TABLES=(
    "locale"            # Configuración de idioma y locale
)

# LOG_SQL puede tener (opcional):
declare -a LOG_TABLES=(
    "loginlog"
    "itemlog"
)

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}VERIFICANDO TABLAS EN PLAYER_SQL ($PLAYER_DB)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ERRORS=0
WARNINGS=0

for table in "${PLAYER_TABLES[@]}"; do
    EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "^$table$" || echo "0")
    EXISTS=$(echo "$EXISTS" | tr -d '\n' | head -1)
    
    if [ "$EXISTS" -gt 0 ] 2>/dev/null; then
        COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "0")
        echo -e "${GREEN}✅ $table existe ($COUNT registros)${NC}"
    else
        echo -e "${RED}❌ $table NO existe en $PLAYER_DB${NC}"
        ((ERRORS++))
        
        # Buscar en otras bases
        echo -e "${YELLOW}   Buscando en otras bases de datos...${NC}"
        for db in metin2_account metin2_common metin2_log; do
            if [ "$db" != "$PLAYER_DB" ]; then
                FOUND=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "^$table$" || echo "0")
                FOUND=$(echo "$FOUND" | tr -d '\n' | head -1)
                if [ "$FOUND" -gt 0 ] 2>/dev/null; then
                    FOUND_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "0")
                    echo -e "${YELLOW}   ⚠️  Encontrada en: $db ($FOUND_COUNT registros)${NC}"
                    echo -e "${YELLOW}   💡 PROBLEMA: Debe estar en $PLAYER_DB${NC}"
                fi
            fi
        done
    fi
done

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}VERIFICANDO TABLAS EN COMMON_SQL ($COMMON_DB)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

for table in "${COMMON_TABLES[@]}"; do
    EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "^$table$" || echo "0")
    EXISTS=$(echo "$EXISTS" | tr -d '\n' | head -1)
    
    if [ "$EXISTS" -gt 0 ] 2>/dev/null; then
        COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "0")
        echo -e "${GREEN}✅ $table existe ($COUNT registros)${NC}"
        
        # Verificar LANGUAGE si es locale
        if [ "$table" = "locale" ]; then
            LANGUAGE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT COUNT(*) FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null || echo "0")
            if [ "$LANGUAGE_EXISTS" -gt 0 ]; then
                LANGUAGE_VALUE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT mValue FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null)
                echo -e "${GREEN}   ✓ LANGUAGE='$LANGUAGE_VALUE' configurado${NC}"
            else
                echo -e "${RED}   ❌ LANGUAGE no existe en locale${NC}"
                ((ERRORS++))
            fi
        fi
    else
        echo -e "${RED}❌ $table NO existe en $COMMON_DB${NC}"
        ((ERRORS++))
    fi
done

echo ""

# Verificar tablas duplicadas o en lugares incorrectos
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}VERIFICANDO TABLAS DUPLICADAS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ALL_DATABASES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys")

for table in "${PLAYER_TABLES[@]}"; do
    FOUND_IN=()
    
    for db in $ALL_DATABASES; do
        if [ -n "$db" ]; then
            EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "^$table$" || echo "0")
            EXISTS=$(echo "$EXISTS" | tr -d '\n' | head -1)
            
            if [ "$EXISTS" -gt 0 ] 2>/dev/null; then
                FOUND_IN+=("$db")
            fi
        fi
    done
    
    if [ ${#FOUND_IN[@]} -gt 1 ]; then
        echo -e "${YELLOW}⚠️  Tabla '$table' está duplicada en:${NC}"
        for db in "${FOUND_IN[@]}"; do
            COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "0")
            if [ "$db" = "$PLAYER_DB" ]; then
                echo -e "${GREEN}   ✓ $db ($COUNT registros) - CORRECTO${NC}"
            else
                echo -e "${RED}   ❌ $db ($COUNT registros) - INCORRECTO${NC}"
                ((WARNINGS++))
            fi
        done
    fi
done

echo ""

# Resumen
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las tablas están correctamente mapeadas${NC}"
    echo ""
    echo "El servidor debería poder encontrar todas las tablas necesarias."
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Se encontraron $WARNINGS advertencia(s) (tablas duplicadas)${NC}"
    echo -e "${GREEN}✅ No hay errores críticos${NC}"
    echo ""
    echo "Las tablas duplicadas no deberían causar problemas, pero es recomendable limpiarlas."
else
    echo -e "${RED}❌ Se encontraron $ERRORS error(es) y $WARNINGS advertencia(s)${NC}"
    echo ""
    echo -e "${YELLOW}Acciones recomendadas:${NC}"
    echo "   1. Mover tablas faltantes a las bases de datos correctas"
    echo "   2. Eliminar tablas duplicadas de bases de datos incorrectas"
    echo "   3. Ejecutar este script nuevamente para verificar"
fi

unset MYSQL_PWD

