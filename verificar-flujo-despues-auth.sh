#!/bin/bash

echo "=========================================="
echo "Verificación del Flujo Después de Auth"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "1. Verificando si el cliente está recibiendo HEADER_GC_AUTH_SUCCESS..."
echo "   (Esto debería aparecer después de AuthLogin result 1)"
if docker logs metin2-server 2>&1 | grep -q "HEADER_GC_AUTH_SUCCESS\|AuthLogin result"; then
    echo -e "${GREEN}✅ Se encontraron referencias a autenticación exitosa${NC}"
    docker logs metin2-server 2>&1 | grep -E "AuthLogin result|HEADER_GC_AUTH" | tail -5
else
    echo -e "${RED}❌ No se encontraron referencias a autenticación exitosa${NC}"
fi
echo ""

echo "2. Verificando si el cliente está enviando HEADER_CG_LOGIN_BY_KEY..."
if docker logs metin2-server 2>&1 | grep -qi "HEADER_CG_LOGIN_BY_KEY\|LOGIN_BY_KEY\|LoginByKey"; then
    echo -e "${GREEN}✅ Se encontró HEADER_CG_LOGIN_BY_KEY${NC}"
    docker logs metin2-server 2>&1 | grep -i "HEADER_CG_LOGIN_BY_KEY\|LOGIN_BY_KEY\|LoginByKey" | tail -5
else
    echo -e "${RED}❌ No se encontró HEADER_CG_LOGIN_BY_KEY${NC}"
    echo "   Esto significa que el cliente NO está solicitando la lista de personajes"
    echo "   después de autenticarse exitosamente"
fi
echo ""

echo "3. Verificando si hay errores relacionados con el envío de paquetes al cliente..."
if docker logs metin2-server 2>&1 | grep -qi "Packet.*fail\|send.*error\|connection.*close"; then
    echo -e "${YELLOW}⚠️ Se encontraron posibles errores de envío:${NC}"
    docker logs metin2-server 2>&1 | grep -i "Packet.*fail\|send.*error\|connection.*close" | tail -5
else
    echo -e "${GREEN}✅ No se encontraron errores obvios de envío${NC}"
fi
echo ""

echo "4. Verificando la fase (PHASE) del cliente después de autenticación..."
if docker logs metin2-server 2>&1 | grep -qi "PHASE.*SELECT\|SetPhase\|phase"; then
    echo -e "${GREEN}✅ Se encontraron referencias a cambio de fase:${NC}"
    docker logs metin2-server 2>&1 | grep -i "PHASE.*SELECT\|SetPhase\|phase" | tail -5
else
    echo -e "${YELLOW}⚠️ No se encontraron referencias a cambio de fase${NC}"
    echo "   El cliente debería cambiar a PHASE_SELECT después de autenticarse"
fi
echo ""

echo "5. Verificando si hay personajes en la base de datos para la cuenta 'test'..."
if [ -f .env ]; then
    source .env
    COUNT=$(mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} -N -e "
    SELECT COUNT(*) FROM player WHERE account_id = (SELECT id FROM account WHERE login='test');
    " 2>&1 | grep -v "Warning" | tail -1)
    
    if [ "$COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ La cuenta 'test' tiene $COUNT personaje(s)${NC}"
    else
        echo -e "${YELLOW}⚠️ La cuenta 'test' NO tiene personajes${NC}"
        echo "   Esto es normal si es una cuenta nueva"
        echo "   El cliente debería mostrar la pantalla de creación de personaje"
    fi
else
    echo -e "${YELLOW}⚠️ No se pudo verificar (no hay .env)${NC}"
fi
echo ""

echo "6. Verificando los últimos logs de autenticación (últimas 20 líneas relevantes)..."
echo "   Buscando eventos relacionados con login..."
docker logs metin2-server 2>&1 | grep -E "AuthLogin|LOGIN|login|Login" | tail -20
echo ""

echo "=========================================="
echo "ANÁLISIS"
echo "=========================================="
echo ""
echo "Si 'AuthLogin result 1' aparece pero NO aparece 'HEADER_CG_LOGIN_BY_KEY':"
echo "  → El cliente está recibiendo la autenticación exitosa"
echo "  → Pero NO está enviando la solicitud de personajes"
echo "  → Posibles causas:"
echo "    1. El cliente no está configurado correctamente"
echo "    2. El cliente está esperando algo más del servidor"
echo "    3. Hay un problema con el paquete HEADER_GC_AUTH_SUCCESS"
echo ""
echo "Si NO aparece 'AuthLogin result 1':"
echo "  → El flujo de autenticación se está interrumpiendo antes"
echo "  → Revisa los logs anteriores para ver dónde falla"
echo ""
echo "Si aparece 'HEADER_CG_LOGIN_BY_KEY' pero no hay respuesta:"
echo "  → El cliente está solicitando personajes correctamente"
echo "  → Pero el servidor no está respondiendo"
echo "  → Revisa los logs del DB server"
echo ""

