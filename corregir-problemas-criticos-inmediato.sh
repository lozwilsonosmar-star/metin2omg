#!/bin/bash
# Script para corregir problemas críticos que impiden que el servidor inicie
# 1. Corregir columna addon_type a MEDIUMINT UNSIGNED
# 2. Insertar LANGUAGE y LOCALE en tabla locale

echo "=========================================="
echo "Corrección de Problemas Críticos"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio${NC}"
    exit 1
}

export MYSQL_PWD="proyectalean"
MYSQL_USER="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"

echo -e "${YELLOW}Conectando a MySQL con usuario root...${NC}"
echo ""

# ============================================================
# 1. CORREGIR COLUMNA addon_type
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}1. Corrigiendo columna addon_type${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

# Verificar tipo actual
CURRENT_TYPE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player -sN -e "SHOW COLUMNS FROM item_proto WHERE Field='addon_type';" 2>/dev/null | awk '{print $2}')

echo "Tipo actual de addon_type: $CURRENT_TYPE"

if [[ "$CURRENT_TYPE" == *"mediumint"* ]] && [[ "$CURRENT_TYPE" == *"unsigned"* ]]; then
    echo -e "${GREEN}✅ addon_type ya tiene el tipo correcto (MEDIUMINT UNSIGNED)${NC}"
else
    echo -e "${YELLOW}   Cambiando addon_type a MEDIUMINT UNSIGNED...${NC}"
    
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player -e "
        ALTER TABLE item_proto 
        MODIFY COLUMN addon_type MEDIUMINT UNSIGNED NOT NULL DEFAULT 0;
    " 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Columna addon_type corregida${NC}"
    else
        echo -e "${RED}❌ Error al corregir addon_type${NC}"
        echo "   Intentando con sql_mode temporal..."
        
        # Intentar con sql_mode temporal
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player -e "
            SET SESSION sql_mode = '';
            ALTER TABLE item_proto 
            MODIFY COLUMN addon_type MEDIUMINT UNSIGNED NOT NULL DEFAULT 0;
        " 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Columna addon_type corregida (con sql_mode temporal)${NC}"
        else
            echo -e "${RED}❌ Error persistente al corregir addon_type${NC}"
        fi
    fi
fi

echo ""

# ============================================================
# 2. INSERTAR LANGUAGE Y LOCALE
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}2. Verificando LANGUAGE y LOCALE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

# Verificar LANGUAGE
LANGUAGE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common -sN -e "SELECT COUNT(*) FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null || echo "0")

if [ "$LANGUAGE_EXISTS" -eq 0 ]; then
    echo -e "${YELLOW}   Insertando LANGUAGE='kr'...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common -e "
        INSERT IGNORE INTO locale (mKey, mValue) VALUES ('LANGUAGE', 'kr');
    " 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ LANGUAGE insertado${NC}"
    else
        echo -e "${RED}❌ Error al insertar LANGUAGE${NC}"
    fi
else
    echo -e "${GREEN}✅ LANGUAGE ya existe${NC}"
fi

# Verificar LOCALE
LOCALE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common -sN -e "SELECT COUNT(*) FROM locale WHERE mKey='LOCALE';" 2>/dev/null || echo "0")

if [ "$LOCALE_EXISTS" -eq 0 ]; then
    echo -e "${YELLOW}   Insertando LOCALE='korea'...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common -e "
        INSERT IGNORE INTO locale (mKey, mValue) VALUES ('LOCALE', 'korea');
    " 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ LOCALE insertado${NC}"
    else
        echo -e "${RED}❌ Error al insertar LOCALE${NC}"
    fi
else
    echo -e "${GREEN}✅ LOCALE ya existe${NC}"
fi

echo ""

# ============================================================
# 3. VERIFICAR SKILL_POWER_BY_LEVEL
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}3. Verificando SKILL_POWER_BY_LEVEL${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

SKILL_POWER_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common -sN -e "SELECT COUNT(*) FROM locale WHERE mKey='SKILL_POWER_BY_LEVEL';" 2>/dev/null || echo "0")

if [ "$SKILL_POWER_EXISTS" -eq 0 ]; then
    echo -e "${YELLOW}   Insertando SKILL_POWER_BY_LEVEL...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common -e "
        INSERT IGNORE INTO locale (mKey, mValue) VALUES ('SKILL_POWER_BY_LEVEL', '0 5 7 9 11 13 15 17 19 20 22 24 26 28 30 32 34 36 38 40 50 52 55 58 61 63 66 69 72 75 80 82 84 87 90 95 100 110 120 130 150');
    " 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SKILL_POWER_BY_LEVEL insertado${NC}"
    else
        echo -e "${RED}❌ Error al insertar SKILL_POWER_BY_LEVEL${NC}"
    fi
else
    SKILL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common -sN -e "SELECT LENGTH(mValue) - LENGTH(REPLACE(mValue, ' ', '')) + 1 FROM locale WHERE mKey='SKILL_POWER_BY_LEVEL';" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ SKILL_POWER_BY_LEVEL existe ($SKILL_COUNT valores)${NC}"
fi

echo ""

# ============================================================
# RESUMEN
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}RESUMEN${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}✅ Correcciones aplicadas${NC}"
echo ""
echo "Próximos pasos:"
echo "   1. Reinicia el contenedor: docker restart metin2-server"
echo "   2. Espera 30 segundos"
echo "   3. Verifica logs: docker logs --tail 50 metin2-server | grep -E 'TCP listening|MasterAuth|LANGUAGE'"
echo ""

unset MYSQL_PWD

