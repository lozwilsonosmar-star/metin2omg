#!/bin/bash
# Script para verificar y corregir player_index si hay personajes sin índice

echo "=========================================="
echo "Verificación y Corrección de player_index"
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

echo -e "${BLUE}Verificando personajes y player_index...${NC}"
echo ""

# Contar personajes
PLAYER_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM player;" 2>/dev/null || echo "0")
PLAYER_INDEX_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM player_index;" 2>/dev/null || echo "0")

echo "Personajes en tabla 'player': $PLAYER_COUNT"
echo "Registros en 'player_index': $PLAYER_INDEX_COUNT"
echo ""

if [ "$PLAYER_COUNT" -gt 0 ] && [ "$PLAYER_INDEX_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Hay $PLAYER_COUNT personaje(s) pero player_index está vacía${NC}"
    echo ""
    echo "Esto puede causar problemas al listar personajes."
    echo ""
    read -p "¿Crear registros en player_index para los personajes existentes? (S/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[SsYy]$ ]] || [[ -z "$REPLY" ]]; then
        echo ""
        echo -e "${YELLOW}Creando registros en player_index...${NC}"
        
        # Obtener todos los personajes y crear player_index
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
            INSERT INTO player_index (id, pid1, pid2, pid3, pid4, empire)
            SELECT 
                account_id,
                CASE WHEN ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY id) = 1 THEN id ELSE 0 END as pid1,
                CASE WHEN ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY id) = 2 THEN id ELSE 0 END as pid2,
                CASE WHEN ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY id) = 3 THEN id ELSE 0 END as pid3,
                CASE WHEN ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY id) = 4 THEN id ELSE 0 END as pid4,
                empire
            FROM player
            GROUP BY account_id, empire
            ON DUPLICATE KEY UPDATE
                pid1 = VALUES(pid1),
                pid2 = VALUES(pid2),
                pid3 = VALUES(pid3),
                pid4 = VALUES(pid4),
                empire = VALUES(empire);
        " 2>&1
        
        # Método alternativo más simple
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}   Método alternativo: creando registros uno por uno...${NC}"
            
            # Obtener personajes agrupados por cuenta
            mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
                INSERT INTO player_index (id, pid1, pid2, pid3, pid4, empire)
                SELECT 
                    account_id,
                    MAX(CASE WHEN rn = 1 THEN id ELSE 0 END) as pid1,
                    MAX(CASE WHEN rn = 2 THEN id ELSE 0 END) as pid2,
                    MAX(CASE WHEN rn = 3 THEN id ELSE 0 END) as pid3,
                    MAX(CASE WHEN rn = 4 THEN id ELSE 0 END) as pid4,
                    MAX(empire) as empire
                FROM (
                    SELECT 
                        id, account_id, empire,
                        ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY id) as rn
                    FROM player
                ) as ranked
                GROUP BY account_id
                ON DUPLICATE KEY UPDATE
                    pid1 = VALUES(pid1),
                    pid2 = VALUES(pid2),
                    pid3 = VALUES(pid3),
                    pid4 = VALUES(pid4),
                    empire = VALUES(empire);
            " 2>&1
        fi
        
        # Verificar resultado
        NEW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM player_index;" 2>/dev/null || echo "0")
        
        if [ "$NEW_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✅ player_index actualizada ($NEW_COUNT registros)${NC}"
            echo ""
            echo "Datos de player_index:"
            mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SELECT * FROM player_index;" 2>/dev/null
        else
            echo -e "${RED}❌ Error al crear player_index${NC}"
            echo ""
            echo -e "${YELLOW}Intentando método manual...${NC}"
            
            # Método manual: obtener personajes y crear registros
            PLAYERS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT account_id, id, empire FROM player ORDER BY account_id, id;" 2>/dev/null)
            
            declare -A ACCOUNT_PIDS
            declare -A ACCOUNT_EMPIRE
            
            while IFS=$'\t' read -r account_id player_id empire; do
                if [ -z "${ACCOUNT_PIDS[$account_id]}" ]; then
                    ACCOUNT_PIDS[$account_id]="$player_id"
                    ACCOUNT_EMPIRE[$account_id]="$empire"
                else
                    ACCOUNT_PIDS[$account_id]="${ACCOUNT_PIDS[$account_id]},$player_id"
                fi
            done <<< "$PLAYERS"
            
            for account_id in "${!ACCOUNT_PIDS[@]}"; do
                PIDS=($(echo "${ACCOUNT_PIDS[$account_id]}" | tr ',' ' '))
                EMPIRE="${ACCOUNT_EMPIRE[$account_id]}"
                
                PID1=${PIDS[0]:-0}
                PID2=${PIDS[1]:-0}
                PID3=${PIDS[2]:-0}
                PID4=${PIDS[3]:-0}
                
                mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
                    INSERT INTO player_index (id, pid1, pid2, pid3, pid4, empire)
                    VALUES ($account_id, $PID1, $PID2, $PID3, $PID4, $EMPIRE)
                    ON DUPLICATE KEY UPDATE
                        pid1 = VALUES(pid1),
                        pid2 = VALUES(pid2),
                        pid3 = VALUES(pid3),
                        pid4 = VALUES(pid4),
                        empire = VALUES(empire);
                " 2>&1
            done
            
            FINAL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM player_index;" 2>/dev/null || echo "0")
            
            if [ "$FINAL_COUNT" -gt 0 ]; then
                echo -e "${GREEN}✅ player_index actualizada manualmente ($FINAL_COUNT registros)${NC}"
            else
                echo -e "${RED}❌ Error persistente al crear player_index${NC}"
            fi
        fi
    else
        echo "Operación cancelada"
    fi
elif [ "$PLAYER_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ No hay personajes - player_index vacía es normal${NC}"
elif [ "$PLAYER_INDEX_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ player_index tiene $PLAYER_INDEX_COUNT registro(s)${NC}"
    echo ""
    echo "Datos actuales:"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SELECT * FROM player_index;" 2>/dev/null
fi

echo ""
unset MYSQL_PWD

