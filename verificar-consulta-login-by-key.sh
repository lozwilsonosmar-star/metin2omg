#!/bin/bash
# Script para verificar las consultas que hace el DB server durante LOGIN_BY_KEY

echo "=========================================="
echo "Verificación de Consultas LOGIN_BY_KEY"
echo "=========================================="
echo ""

export MYSQL_PWD="proyectalean"
MYSQL_USER="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"

PLAYER_DB="metin2_player"

echo "El DB server hace estas consultas durante LOGIN_BY_KEY:"
echo ""

echo "1. Consulta player_index (línea 140 de ClientManagerLogin.cpp):"
echo "   SELECT pid1, pid2, pid3, pid4, empire FROM player_index WHERE id=2"
echo ""

mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT pid1, pid2, pid3, pid4, empire 
FROM player_index 
WHERE id = 2;
" 2>/dev/null

echo ""

echo "2. Consulta player (línea 200 de ClientManagerLogin.cpp):"
echo "   SELECT id, name, job, level, playtime, st, ht, dx, iq, part_main, part_hair, x, y, skill_group, change_name FROM player WHERE account_id=2"
echo ""

mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT 
    id, 
    name, 
    job, 
    level, 
    playtime, 
    st, 
    ht, 
    dx, 
    iq, 
    part_main, 
    part_hair, 
    x, 
    y, 
    skill_group, 
    change_name 
FROM player 
WHERE account_id = 2;
" 2>/dev/null

echo ""

echo "3. Verificando que los pid en player_index coinciden con los id en player:"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT 
    pi.id as account_id,
    pi.pid1,
    p1.id as player1_id,
    p1.name as player1_name,
    p1.account_id as player1_account_id,
    CASE 
        WHEN pi.pid1 = p1.id AND p1.account_id = pi.id THEN '✅ Correcto'
        ELSE '❌ Error'
    END as verificacion
FROM player_index pi
LEFT JOIN player p1 ON pi.pid1 = p1.id
WHERE pi.id = 2;
" 2>/dev/null

echo ""

echo "4. Verificando logs del DB server:"
if docker ps | grep -q "metin2-server"; then
    echo "Últimos logs del DB server relacionados con LOGIN_BY_KEY:"
    docker logs --tail 200 metin2-server 2>&1 | grep -E "LOGIN_BY_KEY|player_index|SELECT.*player|QID_LOGIN|RESULT_LOGIN" | tail -20
else
    echo "Contenedor no está corriendo"
fi

echo ""
unset MYSQL_PWD

