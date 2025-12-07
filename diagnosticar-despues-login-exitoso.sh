#!/bin/bash
# Script para diagnosticar por qué el cliente se queda después del login

echo "=========================================="
echo "Diagnóstico: Cliente se queda después del login"
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

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}1. VERIFICANDO player_index${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Verificar player_index
PLAYER_INDEX_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM player_index;" 2>/dev/null || echo "0")
PLAYER_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM player;" 2>/dev/null || echo "0")

echo "Personajes en tabla 'player': $PLAYER_COUNT"
echo "Registros en 'player_index': $PLAYER_INDEX_COUNT"
echo ""

if [ "$PLAYER_INDEX_COUNT" -eq 0 ] && [ "$PLAYER_COUNT" -gt 0 ]; then
    echo -e "${RED}❌ PROBLEMA: Hay personajes pero player_index está vacía${NC}"
    echo ""
    echo "El servidor necesita player_index para listar los personajes."
    echo ""
    read -p "¿Crear player_index ahora? (S/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[SsYy]$ ]] || [[ -z "$REPLY" ]]; then
        echo ""
        echo "Creando player_index..."
        
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
        SET SESSION sql_mode = '';
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
            empire = VALUES(empire);
        " 2>&1
        
        if [ $? -eq 0 ]; then
            NEW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM player_index;" 2>/dev/null || echo "0")
            echo -e "${GREEN}✅ player_index creada ($NEW_COUNT registros)${NC}"
        else
            echo -e "${RED}❌ Error al crear player_index${NC}"
        fi
    fi
else
    echo -e "${GREEN}✅ player_index tiene datos${NC}"
    echo ""
    echo "Datos de player_index:"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SELECT * FROM player_index;" 2>/dev/null
fi

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}2. VERIFICANDO PERSONAJES POR CUENTA${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Verificar que los personajes coinciden con player_index
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT 
    pi.id as account_id,
    a.login,
    pi.pid1,
    p1.name as personaje1,
    pi.pid2,
    p2.name as personaje2,
    pi.empire
FROM player_index pi
LEFT JOIN account a ON pi.id = a.id
LEFT JOIN player p1 ON pi.pid1 = p1.id
LEFT JOIN player p2 ON pi.pid2 = p2.id AND pi.pid2 > 0;
" 2>/dev/null

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3. VERIFICANDO LOGS DEL SERVIDOR${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if docker ps | grep -q "metin2-server"; then
    echo "Últimas líneas de logs relacionadas con login:"
    echo ""
    docker logs --tail 50 metin2-server 2>&1 | grep -E "AuthLogin|PHASE_SELECT|SendCharacterList|player_index|LoadCharacter|test|admin" | tail -20
    
    echo ""
    echo -e "${YELLOW}Para ver logs en tiempo real mientras intentas conectarte:${NC}"
    echo "   docker logs -f metin2-server | grep -E 'AuthLogin|PHASE|Character|player_index'"
else
    echo -e "${RED}❌ Contenedor no está corriendo${NC}"
fi

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}4. VERIFICANDO CONFIGURACIÓN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Verificar que account_id en player coincide con id en account
echo "Verificando mapeo account_id:"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT 
    a.id as account_id,
    a.login,
    COUNT(p.id) as num_personajes
FROM account a
LEFT JOIN player p ON a.id = p.account_id
GROUP BY a.id, a.login;
" 2>/dev/null

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN Y RECOMENDACIONES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

echo "Si el cliente se queda en 'you have been connected to the server':"
echo ""
echo "1. Verifica que player_index tenga datos para tu cuenta"
echo "2. Verifica que los personajes tengan account_id correcto"
echo "3. Revisa los logs del servidor para ver errores"
echo "4. Reinicia el servidor después de corregir player_index"
echo ""

unset MYSQL_PWD

