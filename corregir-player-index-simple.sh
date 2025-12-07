#!/bin/bash
# Script simple para corregir player_index sin usar columna empire

echo "=========================================="
echo "Corrección de player_index"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

export MYSQL_PWD="proyectalean"
MYSQL_USER="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"

PLAYER_DB="metin2_player"

echo -e "${YELLOW}Verificando estructura de la tabla player...${NC}"
echo ""

# Ver qué columnas tiene player
COLUMNS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "DESCRIBE player;" 2>/dev/null)
echo "Columnas en tabla 'player':"
echo "$COLUMNS"
echo ""

# Ver personajes
echo -e "${YELLOW}Personajes existentes:${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SELECT id, account_id, name FROM player;" 2>/dev/null
echo ""

# Verificar si player_index tiene columna empire
PLAYER_INDEX_COLUMNS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "DESCRIBE player_index;" 2>/dev/null)
echo "Columnas en tabla 'player_index':"
echo "$PLAYER_INDEX_COLUMNS"
echo ""

# Verificar si empire existe en player_index
HAS_EMPIRE=$(echo "$PLAYER_INDEX_COLUMNS" | grep -c "empire" || echo "0")

echo -e "${YELLOW}Creando registros en player_index...${NC}"
echo ""

if [ "$HAS_EMPIRE" -gt 0 ]; then
    # player_index tiene columna empire
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
        INSERT INTO player_index (id, pid1, pid2, pid3, pid4, empire)
        SELECT 
            account_id as id,
            MIN(id) as pid1,
            CASE WHEN COUNT(*) > 1 THEN MAX(id) ELSE 0 END as pid2,
            0 as pid3,
            0 as pid4,
            0 as empire
        FROM player
        GROUP BY account_id
        ON DUPLICATE KEY UPDATE
            pid1 = VALUES(pid1),
            pid2 = VALUES(pid2),
            pid3 = VALUES(pid3),
            pid4 = VALUES(pid4),
            empire = VALUES(empire);
    " 2>&1
else
    # player_index NO tiene columna empire
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
        INSERT INTO player_index (id, pid1, pid2, pid3, pid4)
        SELECT 
            account_id as id,
            MIN(id) as pid1,
            CASE WHEN COUNT(*) > 1 THEN MAX(id) ELSE 0 END as pid2,
            0 as pid3,
            0 as pid4
        FROM player
        GROUP BY account_id
        ON DUPLICATE KEY UPDATE
            pid1 = VALUES(pid1),
            pid2 = VALUES(pid2),
            pid3 = VALUES(pid3),
            pid4 = VALUES(pid4);
    " 2>&1
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ player_index actualizada${NC}"
    echo ""
    echo "Datos de player_index:"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SELECT * FROM player_index;" 2>/dev/null
else
    echo -e "${RED}❌ Error al crear player_index${NC}"
    echo ""
    echo -e "${YELLOW}Intentando método más simple...${NC}"
    
    # Método más simple: obtener datos y crear manualmente
    PLAYER_DATA=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT account_id, id FROM player ORDER BY account_id, id;" 2>/dev/null)
    
    declare -A ACCOUNT_PIDS
    
    while IFS=$'\t' read -r account_id player_id; do
        if [ -z "${ACCOUNT_PIDS[$account_id]}" ]; then
            ACCOUNT_PIDS[$account_id]="$player_id"
        else
            ACCOUNT_PIDS[$account_id]="${ACCOUNT_PIDS[$account_id]},$player_id"
        fi
    done <<< "$PLAYER_DATA"
    
    for account_id in "${!ACCOUNT_PIDS[@]}"; do
        PIDS=($(echo "${ACCOUNT_PIDS[$account_id]}" | tr ',' ' '))
        
        PID1=${PIDS[0]:-0}
        PID2=${PIDS[1]:-0}
        PID3=${PIDS[2]:-0}
        PID4=${PIDS[3]:-0}
        
        if [ "$HAS_EMPIRE" -gt 0 ]; then
            mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
                INSERT INTO player_index (id, pid1, pid2, pid3, pid4, empire)
                VALUES ($account_id, $PID1, $PID2, $PID3, $PID4, 0)
                ON DUPLICATE KEY UPDATE
                    pid1 = VALUES(pid1),
                    pid2 = VALUES(pid2),
                    pid3 = VALUES(pid3),
                    pid4 = VALUES(pid4),
                    empire = VALUES(empire);
            " 2>&1
        else
            mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
                INSERT INTO player_index (id, pid1, pid2, pid3, pid4)
                VALUES ($account_id, $PID1, $PID2, $PID3, $PID4)
                ON DUPLICATE KEY UPDATE
                    pid1 = VALUES(pid1),
                    pid2 = VALUES(pid2),
                    pid3 = VALUES(pid3),
                    pid4 = VALUES(pid4);
            " 2>&1
        fi
    done
    
    FINAL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM player_index;" 2>/dev/null || echo "0")
    
    if [ "$FINAL_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ player_index actualizada ($FINAL_COUNT registros)${NC}"
        echo ""
        echo "Datos de player_index:"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SELECT * FROM player_index;" 2>/dev/null
    else
        echo -e "${RED}❌ Error persistente${NC}"
    fi
fi

echo ""
unset MYSQL_PWD

