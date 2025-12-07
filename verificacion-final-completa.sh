#!/bin/bash
# Verificación final completa de todas las tablas

echo "=========================================="
echo "Verificación Final Completa"
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

PLAYER_DB="metin2_player"
COMMON_DB="metin2_common"

# Tablas que deben estar en PLAYER_SQL
PLAYER_TABLES=("account" "player" "item" "quest" "affect" "skill_proto" "refine_proto" "shop" "player_index" "banword")

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}VERIFICANDO TABLAS EN PLAYER_SQL ($PLAYER_DB)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ERRORS=0

for table in "${PLAYER_TABLES[@]}"; do
    EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "^$table$" || echo "0")
    EXISTS=$(echo "$EXISTS" | tr -d '\n' | head -1)
    
    if [ "$EXISTS" -gt 0 ] 2>/dev/null; then
        COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "0")
        echo -e "${GREEN}✅ $table existe ($COUNT registros)${NC}"
    else
        echo -e "${RED}❌ $table NO existe en $PLAYER_DB${NC}"
        ((ERRORS++))
    fi
done

echo ""

# Verificar COMMON_SQL
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}VERIFICANDO TABLAS EN COMMON_SQL ($COMMON_DB)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

LOCALE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -e "SHOW TABLES LIKE 'locale';" 2>/dev/null | grep -c "^locale$" || echo "0")
LOCALE_EXISTS=$(echo "$LOCALE_EXISTS" | tr -d '\n' | head -1)

if [ "$LOCALE_EXISTS" -gt 0 ] 2>/dev/null; then
    COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT COUNT(*) FROM locale;" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ locale existe ($COUNT registros)${NC}"
    
    LANGUAGE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT COUNT(*) FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null || echo "0")
    if [ "$LANGUAGE_EXISTS" -gt 0 ]; then
        LANGUAGE_VALUE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT mValue FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null)
        echo -e "${GREEN}   ✓ LANGUAGE='$LANGUAGE_VALUE' configurado${NC}"
    else
        echo -e "${RED}   ❌ LANGUAGE no existe${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}❌ locale NO existe${NC}"
    ((ERRORS++))
fi

echo ""

# Verificar addon_type
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}VERIFICANDO COLUMNA addon_type${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ADDON_TYPE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SHOW COLUMNS FROM item_proto WHERE Field='addon_type';" 2>/dev/null | awk '{print $2}')

if [[ "$ADDON_TYPE" == *"mediumint"* ]] && [[ "$ADDON_TYPE" == *"unsigned"* ]]; then
    echo -e "${GREEN}✅ addon_type tiene el tipo correcto: $ADDON_TYPE${NC}"
else
    echo -e "${RED}❌ addon_type tiene tipo incorrecto: $ADDON_TYPE${NC}"
    echo -e "${YELLOW}   Debe ser: MEDIUMINT UNSIGNED${NC}"
    ((ERRORS++))
fi

echo ""

# Resumen
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las verificaciones pasaron${NC}"
    echo ""
    echo "El servidor debería poder iniciar correctamente."
    echo ""
    echo "Próximos pasos:"
    echo "   1. Reinicia el contenedor: docker restart metin2-server"
    echo "   2. Espera 30 segundos"
    echo "   3. Verifica logs: docker logs --tail 50 metin2-server | grep -E 'TCP listening|MasterAuth|LANGUAGE|account'"
else
    echo -e "${RED}❌ Se encontraron $ERRORS error(es)${NC}"
    echo ""
    echo "Corrige los errores antes de reiniciar el servidor."
fi

unset MYSQL_PWD

