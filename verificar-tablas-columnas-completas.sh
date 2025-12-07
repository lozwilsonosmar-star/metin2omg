#!/bin/bash
# Script para verificar TODAS las tablas y columnas necesarias para el flujo completo de login y juego

echo "=========================================="
echo "Verificación Completa de Tablas y Columnas"
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

if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

# Cargar variables de entorno
source .env 2>/dev/null || true

MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USER=${MYSQL_USER:-metin2}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-Osmar2405}
MYSQL_DB_PLAYER=${MYSQL_DB_PLAYER:-metin2_player}
MYSQL_DB_ACCOUNT=${MYSQL_DB_ACCOUNT:-metin2_account}

echo -e "${YELLOW}Conectando a MySQL...${NC}"
echo "Host: $MYSQL_HOST:$MYSQL_PORT"
echo "Usuario: $MYSQL_USER"
echo "Base de datos: $MYSQL_DB_PLAYER, $MYSQL_DB_ACCOUNT"
echo ""

ERRORS=0
WARNINGS=0

# Función para verificar tabla y columnas
check_table_columns() {
    local DB=$1
    local TABLE=$2
    local COLUMNS=$3
    local DESCRIPTION=$4
    
    echo -e "${YELLOW}Verificando: $DESCRIPTION${NC}"
    echo "  Tabla: $TABLE en $DB"
    
    # Verificar que la tabla existe
    TABLE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DB" -e "SHOW TABLES LIKE '$TABLE';" 2>/dev/null | grep -c "$TABLE")
    
    if [ "$TABLE_EXISTS" -eq 0 ]; then
        echo -e "  ${RED}❌ Tabla '$TABLE' NO existe en $DB${NC}"
        ((ERRORS++))
        return
    fi
    
    echo -e "  ${GREEN}✅ Tabla existe${NC}"
    
    # Verificar cada columna
    IFS=',' read -ra COLS <<< "$COLUMNS"
    for COL in "${COLS[@]}"; do
        COL=$(echo "$COL" | xargs) # Trim whitespace
        COL_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DB" -e "SHOW COLUMNS FROM $TABLE LIKE '$COL';" 2>/dev/null | grep -c "$COL")
        
        if [ "$COL_EXISTS" -eq 0 ]; then
            echo -e "  ${RED}❌ Columna '$COL' NO existe en $TABLE${NC}"
            ((ERRORS++))
        else
            echo -e "  ${GREEN}  ✓ Columna '$COL' existe${NC}"
        fi
    done
    
    # Verificar si hay datos (opcional, solo para tablas que deben tener datos)
    if [ "$5" = "check_data" ]; then
        ROW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DB" -e "SELECT COUNT(*) FROM $TABLE;" 2>/dev/null | tail -n 1)
        if [ "$ROW_COUNT" -eq 0 ]; then
            echo -e "  ${YELLOW}  ⚠️  Tabla está vacía (0 registros)${NC}"
            ((WARNINGS++))
        else
            echo -e "  ${GREEN}  ✓ Tabla tiene $ROW_COUNT registros${NC}"
        fi
    fi
    
    echo ""
}

# ============================================================
# 1. TABLAS DE AUTENTICACIÓN Y LOGIN
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}1. TABLAS DE AUTENTICACIÓN Y LOGIN${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

# account (en metin2_account)
check_table_columns "$MYSQL_DB_ACCOUNT" "account" "id,login,password,social_id,status,availDt,create_time,last_play" "Tabla account (autenticación)"

# player_index (en metin2_account) - CRÍTICA para LOGIN_BY_KEY
check_table_columns "$MYSQL_DB_ACCOUNT" "player_index" "id,pid1,pid2,pid3,pid4,empire" "Tabla player_index (índice de personajes por cuenta)" "check_data"

# ============================================================
# 2. TABLAS DE PERSONAJES (PLAYER)
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}2. TABLAS DE PERSONAJES${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

# player (en metin2_player) - CRÍTICA para LOGIN y PLAYER_LOAD
check_table_columns "$MYSQL_DB_PLAYER" "player" "id,account_id,name,job,level,playtime,st,ht,dx,iq,part_main,part_hair,x,y,z,map_index,exit_x,exit_y,exit_map_index,hp,mp,stamina,random_hp,random_sp,gold,level_step,exp,stat_point,skill_point,sub_skill_point,stat_reset_count,skill_level,quickslot,skill_group,alignment,voice,dir,last_play" "Tabla player (datos de personajes)"

# ============================================================
# 3. TABLAS DE ITEMS
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}3. TABLAS DE ITEMS${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

# item (en metin2_player) - CRÍTICA para PLAYER_LOAD
check_table_columns "$MYSQL_DB_PLAYER" "item" "id,owner_id,window,pos,count,vnum,socket0,socket1,socket2,attrtype0,attrvalue0,attrtype1,attrvalue1,attrtype2,attrvalue2,attrtype3,attrvalue3,attrtype4,attrvalue4,attrtype5,attrvalue5,attrtype6,attrvalue6" "Tabla item (items de personajes)"

# ============================================================
# 4. TABLAS DE QUESTS Y AFFECTS
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}4. TABLAS DE QUESTS Y AFFECTS${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

# quest (en metin2_player) - CRÍTICA para PLAYER_LOAD
check_table_columns "$MYSQL_DB_PLAYER" "quest" "dwPID,szName,szState,lValue" "Tabla quest (quests de personajes)"

# affect (en metin2_player) - CRÍTICA para PLAYER_LOAD
check_table_columns "$MYSQL_DB_PLAYER" "affect" "dwPID,bType,bApplyOn,lApplyValue,dwFlag,lDuration,lSPCost" "Tabla affect (efectos/buffs de personajes)"

# ============================================================
# 5. VERIFICACIÓN ESPECÍFICA: player_index debe tener registro para cuenta de prueba
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}5. VERIFICACIÓN DE DATOS DE PRUEBA${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

# Obtener ID de cuenta de prueba
ACCOUNT_ID=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB_ACCOUNT" -e "SELECT id FROM account WHERE login='test' LIMIT 1;" 2>/dev/null | tail -n 1)

if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" = "NULL" ]; then
    echo -e "${RED}❌ No se encontró cuenta 'test' en account${NC}"
    echo -e "${YELLOW}  ⚠️  Crea una cuenta de prueba primero${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ Cuenta 'test' encontrada (ID: $ACCOUNT_ID)${NC}"
    
    # Verificar player_index
    PLAYER_INDEX_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB_ACCOUNT" -e "SELECT COUNT(*) FROM player_index WHERE id=$ACCOUNT_ID;" 2>/dev/null | tail -n 1)
    
    if [ "$PLAYER_INDEX_EXISTS" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No existe registro en player_index para cuenta ID $ACCOUNT_ID${NC}"
        echo -e "${YELLOW}  Esto es normal si no hay personajes creados${NC}"
        ((WARNINGS++))
    else
        echo -e "${GREEN}✅ Registro en player_index existe para cuenta ID $ACCOUNT_ID${NC}"
        
        # Mostrar datos
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB_ACCOUNT" -e "SELECT id, pid1, pid2, pid3, pid4, empire FROM player_index WHERE id=$ACCOUNT_ID;" 2>/dev/null
    fi
    
    # Verificar personajes
    PLAYER_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB_PLAYER" -e "SELECT COUNT(*) FROM player WHERE account_id=$ACCOUNT_ID;" 2>/dev/null | tail -n 1)
    
    if [ "$PLAYER_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No hay personajes creados para esta cuenta${NC}"
        echo -e "${YELLOW}  El cliente mostrará pantalla de creación de personaje${NC}"
        ((WARNINGS++))
    else
        echo -e "${GREEN}✅ Encontrados $PLAYER_COUNT personaje(s) para esta cuenta${NC}"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB_PLAYER" -e "SELECT id, name, job, level, map_index, x, y FROM player WHERE account_id=$ACCOUNT_ID LIMIT 4;" 2>/dev/null
    fi
fi

echo ""

# ============================================================
# RESUMEN
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}RESUMEN${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las verificaciones pasaron correctamente${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Verificaciones completadas con $WARNINGS advertencia(s)${NC}"
    echo -e "${GREEN}✅ No hay errores críticos${NC}"
    exit 0
else
    echo -e "${RED}❌ Se encontraron $ERRORS error(es) y $WARNINGS advertencia(s)${NC}"
    echo ""
    echo -e "${YELLOW}Acciones recomendadas:${NC}"
    echo "  1. Ejecuta: bash docker/create-all-tables.sql"
    echo "  2. Verifica que todas las tablas se crearon correctamente"
    echo "  3. Vuelve a ejecutar este script"
    exit 1
fi

