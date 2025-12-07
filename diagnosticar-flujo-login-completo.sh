#!/bin/bash

echo "=========================================="
echo "Diagnóstico Completo del Flujo de Login"
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

echo "1. Verificando que el contenedor esté corriendo..."
if ! docker ps | grep -q metin2-server; then
    echo -e "${RED}❌ El contenedor no está corriendo${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Contenedor está corriendo${NC}"
echo ""

echo "2. Verificando logs de QID_AUTH_LOGIN..."
echo "   Buscando 'QID_AUTH_LOGIN: START'..."
if docker logs metin2-server 2>&1 | grep -q "QID_AUTH_LOGIN: START"; then
    echo -e "${GREEN}✅ Se encontró QID_AUTH_LOGIN: START${NC}"
    docker logs metin2-server 2>&1 | grep "QID_AUTH_LOGIN" | tail -5
else
    echo -e "${YELLOW}⚠️ No se encontró QID_AUTH_LOGIN: START (puede que no haya intentos de login recientes)${NC}"
fi
echo ""

echo "3. Verificando logs de QID_AUTH_LOGIN: SUCCESS..."
if docker logs metin2-server 2>&1 | grep -q "QID_AUTH_LOGIN: SUCCESS"; then
    echo -e "${GREEN}✅ Se encontró QID_AUTH_LOGIN: SUCCESS${NC}"
    docker logs metin2-server 2>&1 | grep "QID_AUTH_LOGIN: SUCCESS" | tail -3
else
    echo -e "${RED}❌ No se encontró QID_AUTH_LOGIN: SUCCESS${NC}"
    echo "   Esto significa que AnalyzeReturnQuery no está llegando a LoginPrepare"
fi
echo ""

echo "4. Verificando logs de SendAuthLogin..."
if docker logs metin2-server 2>&1 | grep -q "SendAuthLogin"; then
    echo -e "${GREEN}✅ Se encontró SendAuthLogin${NC}"
    docker logs metin2-server 2>&1 | grep "SendAuthLogin" | tail -3
else
    echo -e "${RED}❌ No se encontró SendAuthLogin${NC}"
    echo "   Esto significa que LoginPrepare no está llamando a SendAuthLogin"
fi
echo ""

echo "5. Verificando logs de HEADER_GD_AUTH_LOGIN (paquete al DB server)..."
if docker logs metin2-server 2>&1 | grep -qi "HEADER_GD_AUTH_LOGIN\|QUERY_AUTH_LOGIN"; then
    echo -e "${GREEN}✅ Se encontraron referencias a HEADER_GD_AUTH_LOGIN${NC}"
    docker logs metin2-server 2>&1 | grep -i "HEADER_GD_AUTH_LOGIN\|QUERY_AUTH_LOGIN" | tail -3
else
    echo -e "${YELLOW}⚠️ No se encontraron referencias a HEADER_GD_AUTH_LOGIN${NC}"
fi
echo ""

echo "6. Verificando logs de AuthLogin result (respuesta del DB server)..."
if docker logs metin2-server 2>&1 | grep -q "AuthLogin result"; then
    echo -e "${GREEN}✅ Se encontró AuthLogin result${NC}"
    docker logs metin2-server 2>&1 | grep "AuthLogin result" | tail -3
else
    echo -e "${RED}❌ No se encontró AuthLogin result${NC}"
    echo "   Esto significa que el DB server no está respondiendo con HEADER_DG_AUTH_LOGIN"
fi
echo ""

echo "7. Verificando errores relacionados con columnas NULL..."
if docker logs metin2-server 2>&1 | grep -q "error column"; then
    echo -e "${RED}❌ Se encontraron errores de columnas:${NC}"
    docker logs metin2-server 2>&1 | grep "error column" | tail -5
else
    echo -e "${GREEN}✅ No se encontraron errores de columnas${NC}"
fi
echo ""

echo "8. Verificando si db_clientdesc está conectado..."
# Buscar en los logs si hay errores de conexión al DB server
if docker logs metin2-server 2>&1 | grep -qi "db.*connect\|db.*fail\|db.*error"; then
    echo -e "${YELLOW}⚠️ Se encontraron posibles problemas de conexión al DB server:${NC}"
    docker logs metin2-server 2>&1 | grep -i "db.*connect\|db.*fail\|db.*error" | tail -3
else
    echo -e "${GREEN}✅ No se encontraron errores obvios de conexión al DB server${NC}"
fi
echo ""

echo "9. Verificando la consulta SQL de login en la base de datos..."
echo "   Ejecutando la misma consulta que usa el servidor..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} -e "
SELECT 
    password IS NOT NULL as has_password,
    securitycode IS NOT NULL as has_securitycode,
    social_id IS NOT NULL as has_social_id,
    id IS NOT NULL as has_id,
    status IS NOT NULL as has_status,
    CASE WHEN availDt IS NULL THEN 1 ELSE 0 END as availDt_is_null,
    UNIX_TIMESTAMP(silver_expire) IS NOT NULL as has_silver_expire,
    UNIX_TIMESTAMP(gold_expire) IS NOT NULL as has_gold_expire,
    UNIX_TIMESTAMP(safebox_expire) IS NOT NULL as has_safebox_expire,
    UNIX_TIMESTAMP(autoloot_expire) IS NOT NULL as has_autoloot_expire,
    UNIX_TIMESTAMP(fish_mind_expire) IS NOT NULL as has_fish_mind_expire,
    UNIX_TIMESTAMP(marriage_fast_expire) IS NOT NULL as has_marriage_fast_expire,
    UNIX_TIMESTAMP(money_drop_rate_expire) IS NOT NULL as has_money_drop_rate_expire,
    UNIX_TIMESTAMP(create_time) IS NOT NULL as has_create_time
FROM account 
WHERE login='test';
" 2>&1 | grep -v "Warning"
echo ""

echo "10. Verificando si hay valores NULL problemáticos..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} -e "
SELECT 
    login,
    CASE WHEN password IS NULL THEN 'NULL' ELSE 'OK' END as password,
    CASE WHEN social_id IS NULL THEN 'NULL' ELSE 'OK' END as social_id,
    CASE WHEN id IS NULL THEN 'NULL' ELSE CAST(id AS CHAR) END as id,
    CASE WHEN status IS NULL THEN 'NULL' ELSE status END as status,
    CASE WHEN create_time = '0000-00-00 00:00:00' THEN 'INVALID' ELSE 'OK' END as create_time
FROM account 
WHERE login='test';
" 2>&1 | grep -v "Warning"
echo ""

echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
echo "El flujo esperado es:"
echo "1. Cliente → HEADER_CG_LOGIN3"
echo "2. Game Server → QID_AUTH_LOGIN (consulta SQL)"
echo "3. Game Server → QID_AUTH_LOGIN: SUCCESS"
echo "4. Game Server → LoginPrepare → SendAuthLogin"
echo "5. Game Server → HEADER_GD_AUTH_LOGIN → DB Server"
echo "6. DB Server → HEADER_DG_AUTH_LOGIN → Game Server"
echo "7. Game Server → AuthLogin result 1"
echo "8. Game Server → HEADER_GC_AUTH_SUCCESS → Cliente"
echo "9. Cliente → HEADER_CG_LOGIN_BY_KEY (para obtener personajes)"
echo "10. Game Server → HEADER_GD_LOGIN_BY_KEY → DB Server"
echo "11. DB Server → HEADER_DG_LOGIN_SUCCESS → Game Server"
echo "12. Game Server → HEADER_GC_LOGIN_SUCCESS → Cliente"
echo ""
echo "Si el cliente se queda en 'you have been connected to the server',"
echo "significa que el paso 9 no está ocurriendo o el paso 11 está fallando."
echo ""

