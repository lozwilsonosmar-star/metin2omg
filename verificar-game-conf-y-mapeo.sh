#!/bin/bash
# Script mejorado para encontrar game.conf y verificar el mapeo

echo "=========================================="
echo "Verificación de game.conf y Mapeo"
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

# Verificar que el contenedor esté corriendo
if ! docker ps | grep -q "metin2-server"; then
    echo -e "${RED}❌ El contenedor metin2-server no está corriendo${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Contenedor está corriendo${NC}"
echo ""

# Buscar game.conf en múltiples ubicaciones
echo -e "${YELLOW}Buscando game.conf...${NC}"

GAME_CONF_PATHS=(
    "/app/gamefiles/conf/game.conf"
    "/opt/metin2/gamefiles/conf/game.conf"
    "/app/conf/game.conf"
    "/opt/metin2/conf/game.conf"
    "/conf/game.conf"
    "/gamefiles/conf/game.conf"
)

GAME_CONF_PATH=""
for path in "${GAME_CONF_PATHS[@]}"; do
    if docker exec metin2-server test -f "$path" 2>/dev/null; then
        GAME_CONF_PATH="$path"
        echo -e "${GREEN}✅ game.conf encontrado en: $path${NC}"
        break
    fi
done

if [ -z "$GAME_CONF_PATH" ]; then
    echo -e "${YELLOW}⚠️  game.conf no encontrado en ubicaciones estándar${NC}"
    echo -e "${YELLOW}   Buscando en todo el contenedor...${NC}"
    
    # Buscar en todo el contenedor
    FOUND=$(docker exec metin2-server find / -name "game.conf" 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        GAME_CONF_PATH="$FOUND"
        echo -e "${GREEN}✅ game.conf encontrado en: $FOUND${NC}"
    else
        echo -e "${RED}❌ game.conf no encontrado${NC}"
        echo ""
        echo "Listando archivos de configuración disponibles:"
        docker exec metin2-server find / -name "*.conf" 2>/dev/null | head -10
        exit 1
    fi
fi

echo ""

# Leer game.conf
GAME_CONF_CONTENT=$(docker exec metin2-server cat "$GAME_CONF_PATH" 2>/dev/null)

if [ -z "$GAME_CONF_CONTENT" ]; then
    echo -e "${RED}❌ No se pudo leer game.conf${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}CONFIGURACIÓN DEL SERVIDOR (game.conf)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Extraer valores
PLAYER_SQL=$(echo "$GAME_CONF_CONTENT" | grep "^PLAYER_SQL:" | sed 's/^PLAYER_SQL: //' || echo "")
COMMON_SQL=$(echo "$GAME_CONF_CONTENT" | grep "^COMMON_SQL:" | sed 's/^COMMON_SQL: //' || echo "")
LOG_SQL=$(echo "$GAME_CONF_CONTENT" | grep "^LOG_SQL:" | sed 's/^LOG_SQL: //' || echo "")

echo "PLAYER_SQL: $PLAYER_SQL"
echo "COMMON_SQL: $COMMON_SQL"
echo "LOG_SQL: $LOG_SQL"
echo ""

# Extraer nombres de bases de datos
PLAYER_DB=$(echo "$PLAYER_SQL" | awk '{print $4}')
COMMON_DB=$(echo "$COMMON_SQL" | awk '{print $4}')
LOG_DB=$(echo "$LOG_SQL" | awk '{print $4}')

echo "Bases de datos que el servidor espera:"
echo "   PLAYER_SQL → $PLAYER_DB"
echo "   COMMON_SQL → $COMMON_DB"
echo "   LOG_SQL → $LOG_DB"
echo ""

# Verificar qué bases de datos existen
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}BASES DE DATOS QUE EXISTEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ALL_DATABASES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys")

echo "Bases de datos encontradas:"
echo "$ALL_DATABASES" | while read db; do
    if [ -n "$db" ]; then
        echo "   - $db"
    fi
done

echo ""

# Verificar mapeo
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}VERIFICANDO MAPEO${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ERRORS=0

# Verificar PLAYER_DB
if echo "$ALL_DATABASES" | grep -q "^$PLAYER_DB$"; then
    echo -e "${GREEN}✅ $PLAYER_DB (PLAYER_SQL) existe${NC}"
    
    # Verificar tabla account (el servidor la busca aquí según input_auth.cpp)
    ACCOUNT_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "account" || echo "0")
    if [ "$ACCOUNT_EXISTS" -gt 0 ]; then
        COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
        echo -e "   ${GREEN}✓ Tabla 'account' existe ($COUNT registros)${NC}"
    else
        echo -e "   ${RED}❌ Tabla 'account' NO existe en $PLAYER_DB${NC}"
        echo -e "   ${YELLOW}   ⚠️  PROBLEMA: El servidor busca 'account' en $PLAYER_DB${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}❌ $PLAYER_DB (PLAYER_SQL) NO existe${NC}"
    ((ERRORS++))
fi

# Verificar COMMON_DB
if echo "$ALL_DATABASES" | grep -q "^$COMMON_DB$"; then
    echo -e "${GREEN}✅ $COMMON_DB (COMMON_SQL) existe${NC}"
    
    # Verificar tabla locale
    LOCALE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -e "SHOW TABLES LIKE 'locale';" 2>/dev/null | grep -c "locale" || echo "0")
    if [ "$LOCALE_EXISTS" -gt 0 ]; then
        LANGUAGE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT COUNT(*) FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null || echo "0")
        if [ "$LANGUAGE_EXISTS" -gt 0 ]; then
            echo -e "   ${GREEN}✓ Tabla 'locale' existe y LANGUAGE está configurado${NC}"
        else
            echo -e "   ${RED}❌ LANGUAGE no existe en locale${NC}"
            ((ERRORS++))
        fi
    else
        echo -e "   ${RED}❌ Tabla 'locale' NO existe${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}❌ $COMMON_DB (COMMON_SQL) NO existe${NC}"
    ((ERRORS++))
fi

# Verificar LOG_DB
if echo "$ALL_DATABASES" | grep -q "^$LOG_DB$"; then
    echo -e "${GREEN}✅ $LOG_DB (LOG_SQL) existe${NC}"
else
    echo -e "${YELLOW}⚠️  $LOG_DB (LOG_SQL) NO existe (puede ser opcional)${NC}"
fi

echo ""

# Resumen
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ El mapeo es correcto${NC}"
    echo ""
    echo "El servidor debería poder encontrar todas las tablas necesarias."
else
    echo -e "${RED}❌ Se encontraron $ERRORS problema(s)${NC}"
    echo ""
    
    if [ "$ACCOUNT_EXISTS" -eq 0 ] && [ -n "$PLAYER_DB" ]; then
        echo -e "${YELLOW}SOLUCIÓN: Mover tabla 'account' a $PLAYER_DB${NC}"
        echo ""
        echo "Ejecuta estos comandos:"
        echo ""
        echo "export MYSQL_PWD=\"proyectalean\""
        echo "mysql -uroot -D$PLAYER_DB -e \"CREATE TABLE IF NOT EXISTS account LIKE metin2_account.account;\""
        echo "mysql -uroot -D$PLAYER_DB -e \"INSERT INTO account SELECT * FROM metin2_account.account;\""
        echo ""
    fi
fi

unset MYSQL_PWD

