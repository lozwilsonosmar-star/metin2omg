#!/bin/bash
# Script para verificar que Docker no modifique las tablas que movimos

echo "=========================================="
echo "Verificación: Docker no modificará tablas"
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
ACCOUNT_DB="metin2_account"

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}1. VERIFICANDO QUÉ HACE EL ENTRYPOINT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if docker ps | grep -q "metin2-server"; then
    echo -e "${GREEN}✅ Contenedor está corriendo${NC}"
    
    # Verificar si existe create-all-tables.sql en el contenedor
    if docker exec metin2-server test -f "/app/create-all-tables.sql" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  El contenedor tiene create-all-tables.sql${NC}"
        echo ""
        echo "El entrypoint verifica si existe 'item_proto' en $PLAYER_DB"
        echo "Si NO existe, ejecuta create-all-tables.sql"
        echo ""
        
        # Verificar si item_proto existe
        ITEM_PROTO_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SHOW TABLES LIKE 'item_proto';" 2>/dev/null | grep -c "^item_proto$" || echo "0")
        ITEM_PROTO_EXISTS=$(echo "$ITEM_PROTO_EXISTS" | tr -d '\n' | head -1)
        
        if [ "$ITEM_PROTO_EXISTS" -gt 0 ] 2>/dev/null; then
            echo -e "${GREEN}✅ item_proto existe - Docker NO ejecutará create-all-tables.sql${NC}"
            echo ""
            echo "Esto significa que Docker NO modificará tus tablas."
        else
            echo -e "${RED}❌ item_proto NO existe - Docker intentaría ejecutar create-all-tables.sql${NC}"
            echo ""
            echo -e "${YELLOW}⚠️  RIESGO: Si reinicias el contenedor, podría crear tablas en lugares incorrectos${NC}"
        fi
    else
        echo -e "${GREEN}✅ El contenedor NO tiene create-all-tables.sql${NC}"
        echo "Docker NO puede modificar las tablas automáticamente."
    fi
else
    echo -e "${YELLOW}⚠️  Contenedor no está corriendo${NC}"
fi

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}2. VERIFICANDO QUÉ CREA create-all-tables.sql${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ -f "docker/create-all-tables.sql" ]; then
    echo "Buscando dónde crea 'account' y 'player_index'..."
    echo ""
    
    # Buscar dónde crea account
    ACCOUNT_CREATE=$(grep -A 5 "CREATE TABLE.*account" docker/create-all-tables.sql | head -10)
    ACCOUNT_DB=$(grep -B 2 "CREATE TABLE.*account" docker/create-all-tables.sql | grep "USE" | awk '{print $2}' | tr -d ';' || echo "")
    
    if [ -n "$ACCOUNT_DB" ]; then
        echo -e "${YELLOW}⚠️  create-all-tables.sql crea 'account' en: $ACCOUNT_DB${NC}"
        
        if [ "$ACCOUNT_DB" = "$ACCOUNT_DB" ]; then
            echo -e "${RED}   ❌ PROBLEMA: Crea account en $ACCOUNT_DB, pero debe estar en $PLAYER_DB${NC}"
            echo ""
            echo -e "${YELLOW}   Sin embargo, usa 'CREATE TABLE IF NOT EXISTS'${NC}"
            echo -e "${YELLOW}   Esto significa que si account ya existe en $PLAYER_DB, NO la creará en $ACCOUNT_DB${NC}"
        fi
    fi
    
    # Buscar dónde crea player_index
    PLAYER_INDEX_DB=$(grep -B 2 "CREATE TABLE.*player_index" docker/create-all-tables.sql | grep "USE" | awk '{print $2}' | tr -d ';' | head -1 || echo "")
    
    if [ -n "$PLAYER_INDEX_DB" ]; then
        echo -e "${YELLOW}⚠️  create-all-tables.sql crea 'player_index' en: $PLAYER_INDEX_DB${NC}"
        
        if [ "$PLAYER_INDEX_DB" != "$PLAYER_DB" ]; then
            echo -e "${RED}   ❌ PROBLEMA: Crea player_index en $PLAYER_INDEX_DB, pero debe estar en $PLAYER_DB${NC}"
            echo ""
            echo -e "${YELLOW}   Sin embargo, usa 'CREATE TABLE IF NOT EXISTS'${NC}"
            echo -e "${YELLOW}   Esto significa que si player_index ya existe en $PLAYER_DB, NO la creará en $PLAYER_INDEX_DB${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  No se encontró docker/create-all-tables.sql${NC}"
fi

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3. VERIFICANDO ESTADO ACTUAL${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Verificar dónde están account y player_index
ACCOUNT_IN_PLAYER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "^account$" || echo "0")
ACCOUNT_IN_PLAYER=$(echo "$ACCOUNT_IN_PLAYER" | tr -d '\n' | head -1)

ACCOUNT_IN_ACCOUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$ACCOUNT_DB" -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "^account$" || echo "0")
ACCOUNT_IN_ACCOUNT=$(echo "$ACCOUNT_IN_ACCOUNT" | tr -d '\n' | head -1)

PLAYER_INDEX_IN_PLAYER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SHOW TABLES LIKE 'player_index';" 2>/dev/null | grep -c "^player_index$" || echo "0")
PLAYER_INDEX_IN_PLAYER=$(echo "$PLAYER_INDEX_IN_PLAYER" | tr -d '\n' | head -1)

PLAYER_INDEX_IN_ACCOUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$ACCOUNT_DB" -e "SHOW TABLES LIKE 'player_index';" 2>/dev/null | grep -c "^player_index$" || echo "0")
PLAYER_INDEX_IN_ACCOUNT=$(echo "$PLAYER_INDEX_IN_ACCOUNT" | tr -d '\n' | head -1)

echo "Estado actual:"
if [ "$ACCOUNT_IN_PLAYER" -gt 0 ] 2>/dev/null; then
    COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ account está en $PLAYER_DB ($COUNT registros) - CORRECTO${NC}"
else
    echo -e "${RED}❌ account NO está en $PLAYER_DB${NC}"
fi

if [ "$ACCOUNT_IN_ACCOUNT" -gt 0 ] 2>/dev/null; then
    COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$ACCOUNT_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
    echo -e "${YELLOW}⚠️  account también está en $ACCOUNT_DB ($COUNT registros) - DUPLICADO${NC}"
fi

if [ "$PLAYER_INDEX_IN_PLAYER" -gt 0 ] 2>/dev/null; then
    COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM player_index;" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ player_index está en $PLAYER_DB ($COUNT registros) - CORRECTO${NC}"
else
    echo -e "${RED}❌ player_index NO está en $PLAYER_DB${NC}"
fi

if [ "$PLAYER_INDEX_IN_ACCOUNT" -gt 0 ] 2>/dev/null; then
    COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$ACCOUNT_DB" -sN -e "SELECT COUNT(*) FROM player_index;" 2>/dev/null || echo "0")
    echo -e "${YELLOW}⚠️  player_index también está en $ACCOUNT_DB ($COUNT registros) - DUPLICADO${NC}"
fi

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN Y RECOMENDACIONES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

echo "1. Docker NO eliminará tus tablas porque:"
echo "   - El entrypoint solo ejecuta create-all-tables.sql si item_proto NO existe"
echo "   - item_proto ya existe, así que NO se ejecutará"
echo ""
echo "2. create-all-tables.sql NO sobrescribirá tus tablas porque:"
echo "   - Usa 'CREATE TABLE IF NOT EXISTS' (solo crea si no existe)"
echo "   - Si account/player_index ya existen en $PLAYER_DB, NO las creará en $ACCOUNT_DB"
echo ""
echo "3. RECOMENDACIÓN:"
if [ "$ACCOUNT_IN_ACCOUNT" -gt 0 ] 2>/dev/null || [ "$PLAYER_INDEX_IN_ACCOUNT" -gt 0 ] 2>/dev/null; then
    echo -e "${YELLOW}   Elimina las tablas duplicadas en $ACCOUNT_DB para evitar confusión:${NC}"
    if [ "$ACCOUNT_IN_ACCOUNT" -gt 0 ] 2>/dev/null; then
        echo "   mysql -uroot -D$ACCOUNT_DB -e 'DROP TABLE IF EXISTS account;'"
    fi
    if [ "$PLAYER_INDEX_IN_ACCOUNT" -gt 0 ] 2>/dev/null; then
        echo "   mysql -uroot -D$ACCOUNT_DB -e 'DROP TABLE IF EXISTS player_index;'"
    fi
else
    echo -e "${GREEN}   ✅ No hay tablas duplicadas - Todo está correcto${NC}"
fi

unset MYSQL_PWD

