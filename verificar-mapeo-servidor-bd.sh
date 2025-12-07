#!/bin/bash
# Script para verificar el mapeo entre lo que el servidor espera y lo que existe
# Compara game.conf con las bases de datos reales

echo "=========================================="
echo "Verificación de Mapeo Servidor-Base de Datos"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio${NC}"
    exit 1
}

export MYSQL_PWD="proyectalean"
MYSQL_USER="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"

# ============================================================
# 1. LEER CONFIGURACIÓN DEL SERVIDOR (game.conf)
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}1. CONFIGURACIÓN DEL SERVIDOR (game.conf)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Buscar game.conf dentro del contenedor
GAME_CONF_PATHS=(
    "/app/gamefiles/conf/game.conf"
    "/opt/metin2/gamefiles/conf/game.conf"
    "/app/conf/game.conf"
    "/opt/metin2/conf/game.conf"
)

GAME_CONF_CONTENT=""
for path in "${GAME_CONF_PATHS[@]}"; do
    if docker exec metin2-server test -f "$path" 2>/dev/null; then
        GAME_CONF_CONTENT=$(docker exec metin2-server cat "$path" 2>/dev/null)
        echo -e "${GREEN}✅ game.conf encontrado en: $path${NC}"
        break
    fi
done

if [ -z "$GAME_CONF_CONTENT" ]; then
    echo -e "${RED}❌ No se pudo leer game.conf del contenedor${NC}"
    echo -e "${YELLOW}   El contenedor puede no estar corriendo o game.conf no existe${NC}"
    exit 1
fi

echo ""

# Extraer valores de game.conf
PLAYER_SQL=$(echo "$GAME_CONF_CONTENT" | grep "^PLAYER_SQL:" | awk '{print $2, $3, $4, $5, $6}' || echo "")
COMMON_SQL=$(echo "$GAME_CONF_CONTENT" | grep "^COMMON_SQL:" | awk '{print $2, $3, $4, $5, $6}' || echo "")
LOG_SQL=$(echo "$GAME_CONF_CONTENT" | grep "^LOG_SQL:" | awk '{print $2, $3, $4, $5, $6}' || echo "")

echo "Configuración en game.conf:"
echo "   PLAYER_SQL: $PLAYER_SQL"
echo "   COMMON_SQL: $COMMON_SQL"
echo "   LOG_SQL: $LOG_SQL"
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

# ============================================================
# 2. VERIFICAR QUÉ BASES DE DATOS EXISTEN
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}2. BASES DE DATOS QUE REALMENTE EXISTEN${NC}"
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

# ============================================================
# 3. VERIFICAR MAPEO
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3. VERIFICANDO MAPEO${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ERRORS=0

# Verificar PLAYER_SQL
PLAYER_EXISTS=$(echo "$ALL_DATABASES" | grep -c "^$PLAYER_DB$" || echo "0")
if [ "$PLAYER_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Base de datos '$PLAYER_DB' (PLAYER_SQL) existe${NC}"
    
    # Verificar tablas críticas en PLAYER_SQL
    PLAYER_TABLES=("player" "item" "quest" "affect" "skill_proto" "refine_proto")
    for table in "${PLAYER_TABLES[@]}"; do
        EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "$table" || echo "0")
        if [ "$EXISTS" -gt 0 ]; then
            COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "0")
            echo -e "   ${GREEN}  ✓ Tabla '$table' existe ($COUNT registros)${NC}"
        else
            echo -e "   ${RED}  ❌ Tabla '$table' NO existe${NC}"
            ((ERRORS++))
        fi
    done
else
    echo -e "${RED}❌ Base de datos '$PLAYER_DB' (PLAYER_SQL) NO existe${NC}"
    ((ERRORS++))
fi

echo ""

# Verificar COMMON_SQL
COMMON_EXISTS=$(echo "$ALL_DATABASES" | grep -c "^$COMMON_DB$" || echo "0")
if [ "$COMMON_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Base de datos '$COMMON_DB' (COMMON_SQL) existe${NC}"
    
    # Verificar tabla locale (crítica)
    LOCALE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -e "SHOW TABLES LIKE 'locale';" 2>/dev/null | grep -c "locale" || echo "0")
    if [ "$LOCALE_EXISTS" -gt 0 ]; then
        LANGUAGE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT COUNT(*) FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null || echo "0")
        if [ "$LANGUAGE_EXISTS" -gt 0 ]; then
            LANGUAGE_VALUE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT mValue FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null)
            echo -e "   ${GREEN}  ✓ Tabla 'locale' existe${NC}"
            echo -e "   ${GREEN}  ✓ LANGUAGE='$LANGUAGE_VALUE' existe${NC}"
        else
            echo -e "   ${RED}  ❌ LANGUAGE no existe en locale${NC}"
            ((ERRORS++))
        fi
    else
        echo -e "   ${RED}  ❌ Tabla 'locale' NO existe${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}❌ Base de datos '$COMMON_DB' (COMMON_SQL) NO existe${NC}"
    ((ERRORS++))
fi

echo ""

# Verificar LOG_SQL
LOG_EXISTS=$(echo "$ALL_DATABASES" | grep -c "^$LOG_DB$" || echo "0")
if [ "$LOG_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Base de datos '$LOG_DB' (LOG_SQL) existe${NC}"
else
    echo -e "${YELLOW}⚠️  Base de datos '$LOG_DB' (LOG_SQL) NO existe (puede ser opcional)${NC}"
fi

echo ""

# ============================================================
# 4. VERIFICAR DÓNDE ESTÁ LA TABLA account
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}4. VERIFICANDO TABLA account${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# El servidor busca account en PLAYER_SQL según el código de login
echo -e "${YELLOW}Buscando tabla 'account'...${NC}"

# Buscar en PLAYER_SQL (donde el servidor la busca)
ACCOUNT_IN_PLAYER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "account" || echo "0")

if [ "$ACCOUNT_IN_PLAYER" -gt 0 ]; then
    COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ Tabla 'account' encontrada en $PLAYER_DB ($COUNT registros)${NC}"
    echo -e "${GREEN}   ✅ Esto es CORRECTO - el servidor busca account en PLAYER_SQL${NC}"
else
    echo -e "${RED}❌ Tabla 'account' NO encontrada en $PLAYER_DB${NC}"
    echo -e "${YELLOW}   Buscando en otras bases de datos...${NC}"
    
    # Buscar en todas las bases
    for db in $ALL_DATABASES; do
        if [ -n "$db" ]; then
            EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "account" || echo "0")
            if [ "$EXISTS" -gt 0 ]; then
                COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
                echo -e "${YELLOW}   ⚠️  Encontrada en: $db ($COUNT registros)${NC}"
                echo -e "${YELLOW}   💡 PROBLEMA: El servidor busca 'account' en '$PLAYER_DB' pero está en '$db'${NC}"
                ((ERRORS++))
            fi
        fi
    done
fi

echo ""

# ============================================================
# RESUMEN
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ El mapeo entre servidor y bases de datos es correcto${NC}"
    echo ""
    echo "El servidor debería poder encontrar todas las tablas necesarias."
else
    echo -e "${RED}❌ Se encontraron $ERRORS problema(s) de mapeo${NC}"
    echo ""
    echo -e "${YELLOW}Soluciones:${NC}"
    echo ""
    
    if [ "$ACCOUNT_IN_PLAYER" -eq 0 ]; then
        echo "1. Mover tabla 'account' a $PLAYER_DB:"
        echo "   mysql -uroot -p$MYSQL_PWD -e \"CREATE TABLE $PLAYER_DB.account LIKE metin2_account.account;\""
        echo "   mysql -uroot -p$MYSQL_PWD -e \"INSERT INTO $PLAYER_DB.account SELECT * FROM metin2_account.account;\""
        echo ""
    fi
    
    echo "2. Verificar que .env tenga los nombres correctos:"
    echo "   MYSQL_DB_PLAYER=$PLAYER_DB"
    echo "   MYSQL_DB_COMMON=$COMMON_DB"
    echo "   MYSQL_DB_LOG=$LOG_DB"
    echo ""
fi

unset MYSQL_PWD

