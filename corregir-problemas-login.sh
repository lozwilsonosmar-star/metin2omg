#!/bin/bash

echo "=========================================="
echo "Corrección de Problemas de Login"
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

echo "1. Verificando valores NULL en la cuenta 'test'..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} <<EOF 2>&1 | grep -v "Warning"
SELECT 
    login,
    CASE WHEN password IS NULL THEN 'NULL' ELSE 'OK' END as password,
    CASE WHEN securitycode IS NULL THEN 'NULL' ELSE 'OK' END as securitycode,
    CASE WHEN social_id IS NULL THEN 'NULL' ELSE social_id END as social_id,
    CASE WHEN id IS NULL THEN 'NULL' ELSE CAST(id AS CHAR) END as id,
    CASE WHEN status IS NULL THEN 'NULL' ELSE status END as status,
    CASE WHEN create_time = '0000-00-00 00:00:00' OR create_time IS NULL THEN 'INVALID' ELSE 'OK' END as create_time
FROM account 
WHERE login='test';
EOF

echo ""
echo "2. Corrigiendo valores NULL y fechas inválidas..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} <<EOF 2>&1 | grep -v "Warning"
UPDATE account 
SET 
    social_id = COALESCE(NULLIF(social_id, ''), 'A1'),
    securitycode = COALESCE(NULLIF(securitycode, ''), ''),
    create_time = CASE 
        WHEN create_time IS NULL OR create_time = '0000-00-00 00:00:00' 
        THEN NOW() 
        ELSE create_time 
    END,
    silver_expire = COALESCE(silver_expire, '1970-01-01 00:00:00'),
    gold_expire = COALESCE(gold_expire, '1970-01-01 00:00:00'),
    safebox_expire = COALESCE(safebox_expire, '1970-01-01 00:00:00'),
    autoloot_expire = COALESCE(autoloot_expire, '1970-01-01 00:00:00'),
    fish_mind_expire = COALESCE(fish_mind_expire, '1970-01-01 00:00:00'),
    marriage_fast_expire = COALESCE(marriage_fast_expire, '1970-01-01 00:00:00'),
    money_drop_rate_expire = COALESCE(money_drop_rate_expire, '1970-01-01 00:00:00')
WHERE login = 'test';
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Valores corregidos${NC}"
else
    echo -e "${RED}❌ Error al corregir valores${NC}"
fi
echo ""

echo "3. Verificando que la consulta SQL funcione correctamente..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} <<EOF 2>&1 | grep -v "Warning"
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
echo "4. Verificando que no haya valores NULL en los resultados..."
RESULT=$(mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} -N -e "
SELECT COUNT(*) 
FROM account 
WHERE login='test' 
AND (password IS NULL 
     OR social_id IS NULL 
     OR id IS NULL 
     OR status IS NULL 
     OR create_time IS NULL 
     OR create_time = '0000-00-00 00:00:00');
" 2>&1 | grep -v "Warning")

if [ "$RESULT" = "0" ]; then
    echo -e "${GREEN}✅ No hay valores NULL problemáticos${NC}"
else
    echo -e "${RED}❌ Aún hay valores NULL problemáticos: $RESULT${NC}"
fi
echo ""

echo "5. Verificando conexión al DB server..."
if docker exec metin2-server netstat -an 2>/dev/null | grep -q ":8888.*ESTABLISHED"; then
    echo -e "${GREEN}✅ El game server está conectado al DB server en el puerto 8888${NC}"
else
    echo -e "${YELLOW}⚠️ No se pudo verificar la conexión al DB server${NC}"
    echo "   (Esto puede ser normal si el servidor aún no ha intentado conectarse)"
fi
echo ""

echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
echo "Se han corregido los valores NULL y fechas inválidas en la cuenta 'test'."
echo ""
echo "Próximos pasos:"
echo "1. Reiniciar el contenedor: docker restart metin2-server"
echo "2. Intentar conectarse con el cliente"
echo "3. Verificar los logs: docker logs -f metin2-server"
echo "4. Buscar en los logs:"
echo "   - 'QID_AUTH_LOGIN: SUCCESS'"
echo "   - 'SendAuthLogin'"
echo "   - 'AuthLogin result 1'"
echo "   - 'HEADER_CG_LOGIN_BY_KEY' (del cliente)"
echo ""

