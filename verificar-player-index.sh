#!/bin/bash
# Script para verificar dónde está player_index y si está en el lugar correcto

echo "=========================================="
echo "Verificación de player_index"
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

# Buscar player_index en todas las bases de datos
ALL_DATABASES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys")

echo -e "${BLUE}Buscando tabla 'player_index' en todas las bases de datos...${NC}"
echo ""

FOUND_IN=()

for db in $ALL_DATABASES; do
    if [ -n "$db" ]; then
        EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -e "SHOW TABLES LIKE 'player_index';" 2>/dev/null | grep -c "^player_index$" || echo "0")
        EXISTS=$(echo "$EXISTS" | tr -d '\n' | head -1)
        
        if [ "$EXISTS" -gt 0 ] 2>/dev/null; then
            COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -sN -e "SELECT COUNT(*) FROM \`player_index\`;" 2>/dev/null || echo "0")
            FOUND_IN+=("$db")
            echo -e "${YELLOW}⚠️  Encontrada en: $db ($COUNT registros)${NC}"
        fi
    fi
done

echo ""

# Verificar dónde el servidor la busca
if docker ps | grep -q "metin2-server"; then
    GAME_CONF_PATH=$(docker exec metin2-server find / -name "game.conf" 2>/dev/null | head -1)
    
    if [ -n "$GAME_CONF_PATH" ]; then
        GAME_CONF_CONTENT=$(docker exec metin2-server cat "$GAME_CONF_PATH" 2>/dev/null)
        PLAYER_DB=$(echo "$GAME_CONF_CONTENT" | grep "^PLAYER_SQL:" | awk '{print $5}')
        
        echo -e "${BLUE}Según game.conf, PLAYER_SQL es: $PLAYER_DB${NC}"
        echo ""
        
        # Verificar si está en PLAYER_DB
        IN_PLAYER_DB=$(echo "${FOUND_IN[@]}" | grep -c "$PLAYER_DB" || echo "0")
        
        if [ "$IN_PLAYER_DB" -gt 0 ]; then
            echo -e "${GREEN}✅ player_index está en $PLAYER_DB (CORRECTO)${NC}"
        else
            echo -e "${RED}❌ player_index NO está en $PLAYER_DB${NC}"
            echo ""
            echo -e "${YELLOW}Según el código del servidor, player_index se busca en PLAYER_SQL${NC}"
            echo -e "${YELLOW}Debe estar en: $PLAYER_DB${NC}"
            echo ""
            
            if [ ${#FOUND_IN[@]} -gt 0 ]; then
                echo -e "${YELLOW}Opciones:${NC}"
                echo "   1. Mover player_index de ${FOUND_IN[0]} a $PLAYER_DB"
                echo "   2. Verificar si el código realmente busca player_index en PLAYER_SQL"
            else
                echo -e "${RED}❌ player_index no existe en ninguna base de datos${NC}"
                echo -e "${YELLOW}   Necesitas crearla${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  No se pudo leer game.conf${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Contenedor no está corriendo${NC}"
fi

echo ""

# Mostrar estructura si existe
if [ ${#FOUND_IN[@]} -gt 0 ]; then
    echo -e "${BLUE}Estructura de player_index en ${FOUND_IN[0]}:${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"${FOUND_IN[0]}" -e "DESCRIBE player_index;" 2>/dev/null
    echo ""
    
    echo -e "${BLUE}Datos de ejemplo (primeros 5 registros):${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"${FOUND_IN[0]}" -e "SELECT * FROM player_index LIMIT 5;" 2>/dev/null
fi

unset MYSQL_PWD

