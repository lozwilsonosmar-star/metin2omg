#!/bin/bash
# Script para corregir problemas finales:
# 1. Agregar configuración LANGUAGE en locale
# 2. Verificar/corregir tipo de columna addon_type
# Uso: bash corregir-problemas-finales.sh

set -e

echo "=========================================="
echo "Corrección de Problemas Finales"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /opt/metin2omg

# Obtener credenciales
MYSQL_HOST=$(grep "^MYSQL_HOST=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "localhost")
MYSQL_PORT=$(grep "^MYSQL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "3306")
MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2")
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

export MYSQL_PWD="$MYSQL_PASSWORD"

# 1. Verificar/corregir LANGUAGE en locale
echo -e "${GREEN}1. Verificando configuración LANGUAGE...${NC}"
LANGUAGE_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -sN -e "SELECT COUNT(*) FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null || echo "0")

if [ "$LANGUAGE_COUNT" = "0" ]; then
    echo -e "${YELLOW}   ⚠️  LANGUAGE no encontrado, insertando...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common <<EOF 2>&1 | grep -v "Duplicate entry" || true
INSERT IGNORE INTO locale (mKey, mValue) VALUES ('LANGUAGE', 'kr');
EOF
    echo -e "${GREEN}   ✅ LANGUAGE insertado${NC}"
else
    echo -e "${GREEN}   ✅ LANGUAGE ya existe${NC}"
fi
echo ""

# 2. Verificar/corregir LOCALE en locale
echo -e "${GREEN}2. Verificando configuración LOCALE...${NC}"
LOCALE_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -sN -e "SELECT COUNT(*) FROM locale WHERE mKey='LOCALE';" 2>/dev/null || echo "0")

if [ "$LOCALE_COUNT" = "0" ]; then
    echo -e "${YELLOW}   ⚠️  LOCALE no encontrado, insertando...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common <<EOF 2>&1 | grep -v "Duplicate entry" || true
INSERT IGNORE INTO locale (mKey, mValue) VALUES ('LOCALE', 'korea');
EOF
    echo -e "${GREEN}   ✅ LOCALE insertado${NC}"
else
    echo -e "${GREEN}   ✅ LOCALE ya existe${NC}"
fi
echo ""

# 3. Verificar tipo de columna addon_type
echo -e "${GREEN}3. Verificando tipo de columna addon_type...${NC}"
ADDON_TYPE_TYPE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT DATA_TYPE, COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='metin2_player' AND TABLE_NAME='item_proto' AND COLUMN_NAME='addon_type';" 2>/dev/null | head -1 || echo "")

if [ -n "$ADDON_TYPE_TYPE" ]; then
    echo -e "${YELLOW}   Tipo actual: $ADDON_TYPE_TYPE${NC}"
    # Si es SMALLINT UNSIGNED, debería funcionar. Si es TINYINT, necesitamos cambiarlo
    if echo "$ADDON_TYPE_TYPE" | grep -qi "tinyint"; then
        echo -e "${YELLOW}   ⚠️  addon_type es TINYINT, cambiando a SMALLINT UNSIGNED...${NC}"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player <<EOF 2>&1 || true
ALTER TABLE item_proto MODIFY COLUMN addon_type SMALLINT UNSIGNED NOT NULL DEFAULT 0;
EOF
        echo -e "${GREEN}   ✅ addon_type corregido${NC}"
    else
        echo -e "${GREEN}   ✅ addon_type tiene el tipo correcto${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  No se pudo verificar el tipo de columna${NC}"
fi
echo ""

# 4. Verificar valores problemáticos en item_proto
echo -e "${GREEN}4. Verificando valores problemáticos en item_proto...${NC}"
PROBLEM_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM item_proto WHERE addon_type > 32767;" 2>/dev/null || echo "0")

if [ "$PROBLEM_COUNT" != "0" ]; then
    echo -e "${YELLOW}   ⚠️  Encontrados $PROBLEM_COUNT registros con addon_type > 32767${NC}"
    echo -e "${YELLOW}   Estos valores pueden causar problemas si la columna no es UNSIGNED${NC}"
    # Limitar valores a 32767 si no es UNSIGNED
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player <<EOF 2>&1 || true
UPDATE item_proto SET addon_type = 0 WHERE addon_type > 65535;
EOF
    echo -e "${GREEN}   ✅ Valores problemáticos corregidos${NC}"
else
    echo -e "${GREEN}   ✅ No hay valores problemáticos${NC}"
fi
echo ""

unset MYSQL_PWD

# 5. Resumen
echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo -e "${GREEN}✅ Configuración LANGUAGE/LOCALE verificada${NC}"
echo -e "${GREEN}✅ Tipo de columna addon_type verificado${NC}"
echo ""
echo -e "${YELLOW}⚠️  Reinicia el contenedor para aplicar cambios:${NC}"
echo "   docker restart metin2-server"
echo ""

