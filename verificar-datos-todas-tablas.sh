#!/bin/bash
# Script para verificar qué tablas tienen datos y cuáles están vacías

echo "=========================================="
echo "Verificación de Datos en Todas las Tablas"
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
COMMON_DB="metin2_common"
ACCOUNT_DB="metin2_account"
LOG_DB="metin2_log"

# Tablas críticas que DEBEN tener datos
declare -A CRITICAL_TABLES=(
    # PLAYER_SQL
    ["$PLAYER_DB:item_proto"]="CRÍTICA - Prototipos de items"
    ["$PLAYER_DB:skill_proto"]="CRÍTICA - Prototipos de habilidades"
    ["$PLAYER_DB:refine_proto"]="CRÍTICA - Prototipos de refinamiento"
    ["$PLAYER_DB:mob_proto"]="CRÍTICA - Prototipos de monstruos"
    ["$PLAYER_DB:shop"]="CRÍTICA - Tiendas"
    ["$PLAYER_DB:banword"]="IMPORTANTE - Palabras prohibidas"
    
    # COMMON_SQL
    ["$COMMON_DB:locale"]="CRÍTICA - Configuración de idioma"
    
    # ACCOUNT_SQL (aunque account está en PLAYER_SQL ahora)
    ["$PLAYER_DB:account"]="CRÍTICA - Cuentas de usuario"
)

# Tablas que pueden estar vacías inicialmente
declare -A OPTIONAL_TABLES=(
    ["$PLAYER_DB:player"]="Personajes (vacía si no hay personajes creados)"
    ["$PLAYER_DB:player_index"]="Índice de personajes (vacía si no hay personajes)"
    ["$PLAYER_DB:item"]="Items de personajes (vacía si no hay personajes)"
    ["$PLAYER_DB:quest"]="Quests de personajes (vacía si no hay personajes)"
    ["$PLAYER_DB:affect"]="Buffs/efectos (vacía si no hay personajes)"
)

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}1. TABLAS CRÍTICAS (DEBEN TENER DATOS)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ERRORS=0
WARNINGS=0

for table_key in "${!CRITICAL_TABLES[@]}"; do
    DB=$(echo "$table_key" | cut -d':' -f1)
    TABLE=$(echo "$table_key" | cut -d':' -f2)
    DESCRIPTION="${CRITICAL_TABLES[$table_key]}"
    
    # Verificar que la tabla existe
    EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$DB" -e "SHOW TABLES LIKE '$TABLE';" 2>/dev/null | grep -c "^$TABLE$" || echo "0")
    EXISTS=$(echo "$EXISTS" | tr -d '\n' | head -1)
    
    if [ "$EXISTS" -eq 0 ] 2>/dev/null; then
        echo -e "${RED}❌ $TABLE NO existe en $DB${NC}"
        echo "   $DESCRIPTION"
        ((ERRORS++))
    else
        COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$DB" -sN -e "SELECT COUNT(*) FROM \`$TABLE\`;" 2>/dev/null || echo "0")
        
        if [ "$COUNT" -eq 0 ]; then
            echo -e "${RED}❌ $TABLE está VACÍA (0 registros)${NC}"
            echo "   $DESCRIPTION"
            echo -e "${YELLOW}   ⚠️  PROBLEMA: Esta tabla debe tener datos${NC}"
            ((ERRORS++))
        else
            echo -e "${GREEN}✅ $TABLE tiene $COUNT registros${NC}"
        fi
    fi
done

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}2. TABLAS OPCIONALES (PUEDEN ESTAR VACÍAS)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

for table_key in "${!OPTIONAL_TABLES[@]}"; do
    DB=$(echo "$table_key" | cut -d':' -f1)
    TABLE=$(echo "$table_key" | cut -d':' -f2)
    DESCRIPTION="${OPTIONAL_TABLES[$table_key]}"
    
    EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$DB" -e "SHOW TABLES LIKE '$TABLE';" 2>/dev/null | grep -c "^$TABLE$" || echo "0")
    EXISTS=$(echo "$EXISTS" | tr -d '\n' | head -1)
    
    if [ "$EXISTS" -gt 0 ] 2>/dev/null; then
        COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$DB" -sN -e "SELECT COUNT(*) FROM \`$TABLE\`;" 2>/dev/null || echo "0")
        
        if [ "$COUNT" -eq 0 ]; then
            echo -e "${YELLOW}⚠️  $TABLE está vacía (0 registros)${NC}"
            echo "   $DESCRIPTION"
            ((WARNINGS++))
        else
            echo -e "${GREEN}✅ $TABLE tiene $COUNT registros${NC}"
        fi
    else
        echo -e "${RED}❌ $TABLE NO existe en $DB${NC}"
        ((ERRORS++))
    fi
done

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3. VERIFICANDO TODAS LAS TABLAS EN CADA BASE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

for DB in "$PLAYER_DB" "$COMMON_DB" "$ACCOUNT_DB" "$LOG_DB"; do
    echo -e "${YELLOW}Base de datos: $DB${NC}"
    
    TABLES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$DB" -e "SHOW TABLES;" 2>/dev/null | grep -v "Tables_in" || echo "")
    
    if [ -n "$TABLES" ]; then
        EMPTY_COUNT=0
        TOTAL_COUNT=0
        
        echo "$TABLES" | while read table; do
            if [ -n "$table" ]; then
                COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$DB" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "0")
                
                if [ "$COUNT" -eq 0 ]; then
                    echo -e "   ${YELLOW}⚠️  $table: 0 registros${NC}"
                else
                    echo -e "   ${GREEN}✓ $table: $COUNT registros${NC}"
                fi
            fi
        done
    else
        echo -e "${RED}   ❌ No se encontraron tablas${NC}"
    fi
    
    echo ""
done

echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}4. VERIFICANDO DUMPS SQL DISPONIBLES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${YELLOW}⚠️  No se encontró el directorio del proyecto${NC}"
}

if [ -d "metin2_mysql_dump" ]; then
    echo -e "${GREEN}✅ Directorio metin2_mysql_dump encontrado${NC}"
    echo ""
    
    for dump_file in metin2_mysql_dump/*.sql; do
        if [ -f "$dump_file" ]; then
            FILE_NAME=$(basename "$dump_file")
            FILE_SIZE=$(du -h "$dump_file" | cut -f1)
            
            # Contar INSERT statements
            INSERT_COUNT=$(grep -c "^INSERT INTO" "$dump_file" 2>/dev/null || echo "0")
            
            echo "   Archivo: $FILE_NAME"
            echo "   Tamaño: $FILE_SIZE"
            echo "   Inserts: $INSERT_COUNT"
            
            if [ "$INSERT_COUNT" -gt 0 ]; then
                echo -e "   ${GREEN}✓ Contiene datos para importar${NC}"
            else
                echo -e "   ${YELLOW}⚠️  No contiene INSERT statements${NC}"
            fi
            echo ""
        fi
    done
else
    echo -e "${YELLOW}⚠️  Directorio metin2_mysql_dump no encontrado${NC}"
    echo "   Buscando en otras ubicaciones..."
    
    if [ -d "../metin2_mysql_dump" ]; then
        echo -e "${GREEN}✅ Encontrado en ../metin2_mysql_dump${NC}"
    fi
fi

echo ""

# Resumen
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las tablas críticas tienen datos${NC}"
    echo ""
    echo "El servidor debería poder funcionar correctamente."
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Se encontraron $WARNINGS advertencia(s)${NC}"
    echo -e "${GREEN}✅ No hay errores críticos${NC}"
    echo ""
    echo "Las tablas opcionales pueden estar vacías si no hay personajes creados."
else
    echo -e "${RED}❌ Se encontraron $ERRORS error(es) y $WARNINGS advertencia(s)${NC}"
    echo ""
    echo -e "${YELLOW}Acciones recomendadas:${NC}"
    echo "   1. Importar datos desde metin2_mysql_dump/"
    echo "   2. Ejecutar: bash crear-tablas-desde-dumps.sh"
    echo "   3. O importar manualmente los archivos SQL necesarios"
fi

unset MYSQL_PWD

