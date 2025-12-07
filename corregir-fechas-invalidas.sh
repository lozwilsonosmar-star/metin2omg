#!/bin/bash

echo "=========================================="
echo "Corrección de Fechas Inválidas en Account"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cargar variables de entorno
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ No se encontró el archivo .env${NC}"
    exit 1
fi

echo "1. Deshabilitando temporalmente el modo estricto de SQL..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} <<EOF 2>&1 | grep -v "Warning"
SET SESSION sql_mode = '';
EOF

echo "2. Corrigiendo fechas inválidas en la cuenta 'test'..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} <<EOF 2>&1 | grep -v "Warning"
SET SESSION sql_mode = '';

UPDATE account 
SET 
    social_id = COALESCE(NULLIF(social_id, ''), 'A1'),
    securitycode = COALESCE(NULLIF(securitycode, ''), ''),
    create_time = CASE 
        WHEN create_time IS NULL OR create_time = '0000-00-00 00:00:00' OR create_time = '1970-01-01 00:00:00'
        THEN NOW() 
        ELSE create_time 
    END,
    last_play = CASE 
        WHEN last_play IS NULL OR last_play = '0000-00-00 00:00:00' OR last_play = '1970-01-01 00:00:00'
        THEN NOW() 
        ELSE last_play 
    END,
    availDt = CASE 
        WHEN availDt IS NULL OR availDt = '0000-00-00 00:00:00' OR availDt = '1970-01-01 00:00:00'
        THEN NULL
        ELSE availDt 
    END,
    silver_expire = CASE 
        WHEN silver_expire IS NULL OR silver_expire = '0000-00-00 00:00:00' OR silver_expire = '1970-01-01 00:00:00'
        THEN '1970-01-01 00:00:01'
        ELSE silver_expire 
    END,
    gold_expire = CASE 
        WHEN gold_expire IS NULL OR gold_expire = '0000-00-00 00:00:00' OR gold_expire = '1970-01-01 00:00:00'
        THEN '1970-01-01 00:00:01'
        ELSE gold_expire 
    END,
    safebox_expire = CASE 
        WHEN safebox_expire IS NULL OR safebox_expire = '0000-00-00 00:00:00' OR safebox_expire = '1970-01-01 00:00:00'
        THEN '1970-01-01 00:00:01'
        ELSE safebox_expire 
    END,
    autoloot_expire = CASE 
        WHEN autoloot_expire IS NULL OR autoloot_expire = '0000-00-00 00:00:00' OR autoloot_expire = '1970-01-01 00:00:00'
        THEN '1970-01-01 00:00:01'
        ELSE autoloot_expire 
    END,
    fish_mind_expire = CASE 
        WHEN fish_mind_expire IS NULL OR fish_mind_expire = '0000-00-00 00:00:00' OR fish_mind_expire = '1970-01-01 00:00:00'
        THEN '1970-01-01 00:00:01'
        ELSE fish_mind_expire 
    END,
    marriage_fast_expire = CASE 
        WHEN marriage_fast_expire IS NULL OR marriage_fast_expire = '0000-00-00 00:00:00' OR marriage_fast_expire = '1970-01-01 00:00:00'
        THEN '1970-01-01 00:00:01'
        ELSE marriage_fast_expire 
    END,
    money_drop_rate_expire = CASE 
        WHEN money_drop_rate_expire IS NULL OR money_drop_rate_expire = '0000-00-00 00:00:00' OR money_drop_rate_expire = '1970-01-01 00:00:00'
        THEN '1970-01-01 00:00:01'
        ELSE money_drop_rate_expire 
    END
WHERE login = 'test';
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Fechas corregidas${NC}"
else
    echo -e "${RED}❌ Error al corregir fechas${NC}"
fi
echo ""

echo "3. Verificando que la consulta SQL funcione correctamente..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} <<EOF 2>&1 | grep -v "Warning"
SET SESSION sql_mode = '';

SELECT 
    login,
    CASE WHEN password IS NULL THEN 'NULL' ELSE 'OK' END as password,
    CASE WHEN social_id IS NULL THEN 'NULL' ELSE social_id END as social_id,
    CASE WHEN id IS NULL THEN 'NULL' ELSE CAST(id AS CHAR) END as id,
    CASE WHEN status IS NULL THEN 'NULL' ELSE status END as status,
    CASE WHEN create_time IS NULL OR create_time = '0000-00-00 00:00:00' THEN 'INVALID' ELSE 'OK' END as create_time,
    UNIX_TIMESTAMP(create_time) as create_time_ts
FROM account 
WHERE login='test';
EOF

echo ""
echo "4. Verificando que la consulta completa funcione..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} <<EOF 2>&1 | grep -v "Warning"
SET SESSION sql_mode = '';

SELECT 
    password,
    securitycode,
    social_id,
    id,
    status,
    availDt - NOW() > 0 as availDt_check,
    UNIX_TIMESTAMP(silver_expire) as silver_expire_ts,
    UNIX_TIMESTAMP(gold_expire) as gold_expire_ts,
    UNIX_TIMESTAMP(safebox_expire) as safebox_expire_ts,
    UNIX_TIMESTAMP(autoloot_expire) as autoloot_expire_ts,
    UNIX_TIMESTAMP(fish_mind_expire) as fish_mind_expire_ts,
    UNIX_TIMESTAMP(marriage_fast_expire) as marriage_fast_expire_ts,
    UNIX_TIMESTAMP(money_drop_rate_expire) as money_drop_rate_expire_ts,
    UNIX_TIMESTAMP(create_time) as create_time_ts
FROM account 
WHERE login='test';
EOF

echo ""
echo "5. Verificando que no haya valores NULL problemáticos..."
RESULT=$(mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} -N <<EOF 2>&1 | grep -v "Warning" | tail -1
SET SESSION sql_mode = '';
SELECT COUNT(*) 
FROM account 
WHERE login='test' 
AND (password IS NULL 
     OR social_id IS NULL 
     OR id IS NULL 
     OR status IS NULL);
EOF
)

if [ "$RESULT" = "0" ]; then
    echo -e "${GREEN}✅ No hay valores NULL problemáticos${NC}"
else
    echo -e "${YELLOW}⚠️ Aún hay valores NULL: $RESULT${NC}"
fi
echo ""

echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
echo "Se han corregido las fechas inválidas en la cuenta 'test'."
echo ""
echo "Próximos pasos:"
echo "1. Reiniciar el contenedor: docker restart metin2-server"
echo "2. Esperar 30 segundos: sleep 30"
echo "3. Intentar conectarse con el cliente"
echo "4. Verificar los logs: docker logs -f metin2-server"
echo ""

