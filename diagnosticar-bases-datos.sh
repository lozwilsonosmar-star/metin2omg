#!/bin/bash
# Script para diagnosticar qué bases de datos y tablas existen realmente
# Compara con lo que el script de verificación espera encontrar

echo "=========================================="
echo "Diagnóstico de Bases de Datos"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    exit 1
}

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
    echo ""
    echo "   Intenta conectar manualmente:"
    echo "   mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p"
    unset MYSQL_PWD
    exit 1
fi

echo -e "${GREEN}✅ Conexión a MySQL exitosa${NC}"
echo ""

# ============================================================
# 1. LISTAR TODAS LAS BASES DE DATOS
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}1. BASES DE DATOS EXISTENTES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

DATABASES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys")

echo "Bases de datos encontradas:"
echo "$DATABASES" | while read db; do
    if [ -n "$db" ]; then
        echo -e "   ${GREEN}✅ $db${NC}"
    fi
done

echo ""

# ============================================================
# 2. VERIFICAR BASES DE DATOS ESPERADAS
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}2. VERIFICANDO BASES DE DATOS ESPERADAS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

EXPECTED_DBS=("metin2_account" "metin2_common" "metin2_player" "metin2_log")
ENV_DB_ACCOUNT=$(grep "^MYSQL_DB_ACCOUNT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2_account")
ENV_DB_COMMON=$(grep "^MYSQL_DB_COMMON=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2_common")
ENV_DB_PLAYER=$(grep "^MYSQL_DB_PLAYER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2_player")
ENV_DB_LOG=$(grep "^MYSQL_DB_LOG=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2_log")

echo "Bases de datos esperadas según .env:"
echo "   MYSQL_DB_ACCOUNT: $ENV_DB_ACCOUNT"
echo "   MYSQL_DB_COMMON: $ENV_DB_COMMON"
echo "   MYSQL_DB_PLAYER: $ENV_DB_PLAYER"
echo "   MYSQL_DB_LOG: $ENV_DB_LOG"
echo ""

for db in "$ENV_DB_ACCOUNT" "$ENV_DB_COMMON" "$ENV_DB_PLAYER" "$ENV_DB_LOG"; do
    EXISTS=$(echo "$DATABASES" | grep -c "^$db$" || echo "0")
    if [ "$EXISTS" -gt 0 ]; then
        echo -e "   ${GREEN}✅ $db existe${NC}"
    else
        echo -e "   ${RED}❌ $db NO existe${NC}"
        echo -e "      ${YELLOW}¿Está en otra base de datos?${NC}"
    fi
done

echo ""

# ============================================================
# 3. LISTAR TABLAS EN CADA BASE DE DATOS
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3. TABLAS EN CADA BASE DE DATOS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

for db in "$ENV_DB_ACCOUNT" "$ENV_DB_COMMON" "$ENV_DB_PLAYER" "$ENV_DB_LOG"; do
    EXISTS=$(echo "$DATABASES" | grep -c "^$db$" || echo "0")
    if [ "$EXISTS" -gt 0 ]; then
        echo -e "${YELLOW}Base de datos: $db${NC}"
        TABLES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -e "SHOW TABLES;" 2>/dev/null | grep -v "Tables_in")
        
        if [ -n "$TABLES" ]; then
            TABLE_COUNT=$(echo "$TABLES" | wc -l)
            echo -e "   ${GREEN}✅ $TABLE_COUNT tabla(s) encontrada(s):${NC}"
            echo "$TABLES" | while read table; do
                if [ -n "$table" ]; then
                    ROW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "?")
                    echo -e "      - ${GREEN}$table${NC} ($ROW_COUNT registros)"
                fi
            done
        else
            echo -e "   ${YELLOW}⚠️  No hay tablas en esta base de datos${NC}"
        fi
        echo ""
    fi
done

# ============================================================
# 4. BUSCAR TABLAS EN OTRAS BASES DE DATOS
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}4. BUSCANDO TABLAS CRÍTICAS EN OTRAS BASES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

CRITICAL_TABLES=("account" "player_index" "player" "item" "quest" "affect" "skill_proto" "locale")

for table in "${CRITICAL_TABLES[@]}"; do
    echo -e "${YELLOW}Buscando tabla: $table${NC}"
    FOUND=false
    
    for db in $DATABASES; do
        if [ -n "$db" ]; then
            EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "$table" || echo "0")
            if [ "$EXISTS" -gt 0 ]; then
                ROW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "?")
                echo -e "   ${GREEN}✅ Encontrada en: $db ($ROW_COUNT registros)${NC}"
                FOUND=true
            fi
        fi
    done
    
    if [ "$FOUND" = false ]; then
        echo -e "   ${RED}❌ No encontrada en ninguna base de datos${NC}"
    fi
    echo ""
done

# ============================================================
# 5. VERIFICAR CREDENCIALES
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}5. VERIFICACIÓN DE CREDENCIALES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

echo "Credenciales usadas por el script:"
echo "   Host: $MYSQL_HOST"
echo "   Port: $MYSQL_PORT"
echo "   User: $MYSQL_USER"
echo ""
echo -e "${YELLOW}¿Estas credenciales coinciden con las que usas en MySQL Workbench?${NC}"
echo ""
echo "Si usas credenciales diferentes en Workbench, puede ser por eso."
echo ""

# ============================================================
# RESUMEN
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

echo "Si ves las tablas en Workbench pero no aquí, puede ser porque:"
echo "   1. Workbench usa credenciales diferentes (root vs metin2)"
echo "   2. Workbench se conecta a un host/puerto diferente"
echo "   3. Las tablas están en bases de datos con nombres diferentes"
echo ""
echo "Revisa los resultados arriba para identificar el problema."
echo ""

unset MYSQL_PWD

