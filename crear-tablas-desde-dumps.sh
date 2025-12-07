#!/bin/bash
# Script para crear todas las tablas desde los dumps SQL
# Los dumps SQL ya contienen CREATE TABLE, así que los usamos directamente
# Uso: bash crear-tablas-desde-dumps.sh

echo "=========================================="
echo "Creación de Tablas desde Dumps SQL"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    exit 1
}

# Verificar que existen los dumps
if [ ! -d "metin2_mysql_dump" ]; then
    echo -e "${RED}❌ No se encontró el directorio metin2_mysql_dump${NC}"
    echo "   Los dumps SQL deben estar en: metin2_mysql_dump/"
    exit 1
fi

# Obtener credenciales desde .env
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

source .env 2>/dev/null || true

MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USER=${MYSQL_USER:-metin2}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-Osmar2405}

# Ajustar localhost
if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

export MYSQL_PWD="$MYSQL_PASSWORD"

echo -e "${YELLOW}Conectando a MySQL...${NC}"
echo "Host: $MYSQL_HOST:$MYSQL_PORT"
echo "Usuario: $MYSQL_USER"
echo ""

# Verificar conexión
if ! mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error al conectar a MySQL${NC}"
    echo "   Verifica las credenciales en .env"
    unset MYSQL_PWD
    exit 1
fi

echo -e "${GREEN}✅ Conexión a MySQL exitosa${NC}"
echo ""

# ============================================================
# 1. IMPORTAR account.sql (crea tablas en metin2_account)
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}1. Importando account.sql${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ -f "metin2_mysql_dump/account.sql" ]; then
    echo -e "${YELLOW}   Importando tablas y datos a metin2_account...${NC}"
    
    # Convertir INSERT INTO a INSERT IGNORE INTO para evitar errores de duplicados
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' metin2_mysql_dump/account.sql | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_account 2>&1 | \
        grep -v "already exists\|Duplicate entry\|Warning\|Note\|Using a password" || true
    
    echo -e "${GREEN}✅ account.sql importado${NC}"
    
    # Verificar que account existe
    ACCOUNT_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -sN -e "SHOW TABLES LIKE 'account';" 2>/dev/null | wc -l)
    if [ "$ACCOUNT_EXISTS" -gt 0 ]; then
        echo -e "${GREEN}   ✅ Tabla 'account' creada${NC}"
    else
        echo -e "${RED}   ❌ Tabla 'account' NO se creó${NC}"
    fi
else
    echo -e "${RED}❌ No se encontró account.sql${NC}"
fi

echo ""

# ============================================================
# 2. IMPORTAR common.sql (crea tablas en metin2_common)
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}2. Importando common.sql${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ -f "metin2_mysql_dump/common.sql" ]; then
    echo -e "${YELLOW}   Importando tablas y datos a metin2_common...${NC}"
    
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' metin2_mysql_dump/common.sql | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common 2>&1 | \
        grep -v "already exists\|Duplicate entry\|Warning\|Note\|Using a password" || true
    
    echo -e "${GREEN}✅ common.sql importado${NC}"
    
    # Verificar que locale existe
    LOCALE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -sN -e "SHOW TABLES LIKE 'locale';" 2>/dev/null | wc -l)
    if [ "$LOCALE_EXISTS" -gt 0 ]; then
        echo -e "${GREEN}   ✅ Tabla 'locale' creada${NC}"
    else
        echo -e "${RED}   ❌ Tabla 'locale' NO se creó${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No se encontró common.sql${NC}"
fi

echo ""

# ============================================================
# 3. IMPORTAR player.sql (crea tablas en metin2_player)
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3. Importando player.sql${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ -f "metin2_mysql_dump/player.sql" ]; then
    echo -e "${YELLOW}   Importando tablas y datos a metin2_player...${NC}"
    echo -e "${YELLOW}   ⏳ Esto puede tardar unos minutos...${NC}"
    
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' metin2_mysql_dump/player.sql | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player 2>&1 | \
        grep -v "already exists\|Duplicate entry\|Warning\|Note\|Using a password" || true
    
    echo -e "${GREEN}✅ player.sql importado${NC}"
    
    # Verificar tablas críticas
    echo ""
    echo -e "${YELLOW}   Verificando tablas críticas...${NC}"
    
    TABLES=("player" "player_index" "item" "quest" "affect" "skill_proto" "refine_proto" "shop")
    for table in "${TABLES[@]}"; do
        EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SHOW TABLES LIKE '$table';" 2>/dev/null | wc -l)
        if [ "$EXISTS" -gt 0 ]; then
            COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo "0")
            echo -e "${GREEN}   ✅ Tabla '$table' creada ($COUNT registros)${NC}"
        else
            echo -e "${RED}   ❌ Tabla '$table' NO se creó${NC}"
        fi
    done
else
    echo -e "${RED}❌ No se encontró player.sql${NC}"
    echo -e "${RED}   Esta es la tabla más importante, debe existir${NC}"
fi

echo ""

# ============================================================
# 4. IMPORTAR log.sql (opcional)
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}4. Importando log.sql (opcional)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ -f "metin2_mysql_dump/log.sql" ]; then
    echo -e "${YELLOW}   Importando tablas y datos a metin2_log...${NC}"
    
    sed 's/INSERT INTO/INSERT IGNORE INTO/g' metin2_mysql_dump/log.sql | \
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_log 2>&1 | \
        grep -v "already exists\|Duplicate entry\|Warning\|Note\|Using a password" || true
    
    echo -e "${GREEN}✅ log.sql importado${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró log.sql (opcional)${NC}"
fi

echo ""

# ============================================================
# RESUMEN
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}✅ Proceso de importación completado${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "   1. Ejecuta: bash verificar-tablas-columnas-completas.sh"
echo "   2. Verifica que todas las tablas se crearon correctamente"
echo "   3. Si hay errores, revisa los logs arriba"
echo ""

unset MYSQL_PWD

