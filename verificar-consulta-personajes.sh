#!/bin/bash
# Script para verificar la consulta que el servidor hace para cargar personajes

echo "=========================================="
echo "Verificación de Consulta de Personajes"
echo "=========================================="
echo ""

export MYSQL_PWD="proyectalean"
MYSQL_USER="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"

PLAYER_DB="metin2_player"

echo "El servidor consulta player_index para obtener los personajes."
echo "Verificando que los datos estén correctos..."
echo ""

# Simular la consulta que probablemente hace el servidor
echo "1. Consulta player_index para account_id=2 (test):"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT 
    id as account_id,
    pid1,
    pid2,
    pid3,
    pid4,
    empire
FROM player_index
WHERE id = 2;
" 2>/dev/null

echo ""

echo "2. Verificando que los personajes existen:"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT 
    id,
    account_id,
    name,
    job,
    level,
    empire
FROM player
WHERE account_id = 2;
" 2>/dev/null

echo ""

echo "3. Verificando que account_id coincide:"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT 
    a.id as account_id,
    a.login,
    pi.pid1,
    p1.id as player_id,
    p1.name as player_name,
    p1.account_id as player_account_id
FROM account a
LEFT JOIN player_index pi ON a.id = pi.id
LEFT JOIN player p1 ON pi.pid1 = p1.id
WHERE a.login = 'test';
" 2>/dev/null

echo ""

echo "4. Verificando logs del servidor para errores:"
if docker ps | grep -q "metin2-server"; then
    echo "Últimos logs relacionados:"
    docker logs --tail 200 metin2-server 2>&1 | grep -E "GetServerLocation|player_index|SELECT.*player|LoginSuccess|SendLoginSuccess|PHASE_SELECT|ERROR|CRITICAL" | tail -20
else
    echo "Contenedor no está corriendo"
fi

echo ""
unset MYSQL_PWD

