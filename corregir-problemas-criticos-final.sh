#!/bin/bash

echo "=========================================="
echo "Corrección de Problemas Críticos Finales"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cargar variables de entorno
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ No se encontró el archivo .env${NC}"
    exit 1
fi

echo "1. Corrigiendo columna addon_type en item_proto..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} <<EOF 2>&1 | grep -v "Warning"
SET SESSION sql_mode = '';
ALTER TABLE item_proto MODIFY COLUMN addon_type MEDIUMINT UNSIGNED NOT NULL DEFAULT 0;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Columna addon_type corregida${NC}"
else
    echo -e "${YELLOW}⚠️  Error al corregir addon_type (puede que ya esté correcta)${NC}"
fi
echo ""

echo "2. Verificando tipo de columna addon_type..."
TIPO=$(mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_PLAYER} -N -e "
SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA='${MYSQL_DB_PLAYER}' 
AND TABLE_NAME='item_proto' 
AND COLUMN_NAME='addon_type';
" 2>&1 | grep -v "Warning" | tail -1)

if [ "$TIPO" = "mediumint" ] || [ "$TIPO" = "MEDIUMINT" ]; then
    echo -e "${GREEN}✅ addon_type es MEDIUMINT (correcto)${NC}"
else
    echo -e "${YELLOW}⚠️  addon_type es $TIPO (debería ser MEDIUMINT)${NC}"
fi
echo ""

echo "3. Insertando LANGUAGE en locale (metin2_common)..."
mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_COMMON} <<EOF 2>&1 | grep -v "Warning"
INSERT IGNORE INTO locale (mKey, mValue) VALUES ('LANGUAGE', 'kr');
INSERT IGNORE INTO locale (mKey, mValue) VALUES ('LOCALE', 'korea');
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ LANGUAGE insertado${NC}"
else
    echo -e "${YELLOW}⚠️  Error al insertar LANGUAGE${NC}"
fi
echo ""

echo "4. Verificando que LANGUAGE existe..."
COUNT=$(mysql -h127.0.0.1 -P3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D${MYSQL_DB_COMMON} -N -e "
SELECT COUNT(*) FROM locale WHERE mKey='LANGUAGE';
" 2>&1 | grep -v "Warning" | tail -1)

if [ "$COUNT" = "1" ]; then
    echo -e "${GREEN}✅ LANGUAGE existe en la base de datos${NC}"
else
    echo -e "${RED}❌ LANGUAGE NO existe (count: $COUNT)${NC}"
fi
echo ""

echo "5. Verificando WEB_APP_URL en .env..."
if grep -q "^WEB_APP_URL=" .env; then
    WEB_APP_URL=$(grep "^WEB_APP_URL=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    if [ -n "$WEB_APP_URL" ] && [ "$WEB_APP_URL" != "" ]; then
        echo -e "${GREEN}✅ WEB_APP_URL está configurado${NC}"
    else
        echo -e "${YELLOW}⚠️  WEB_APP_URL está vacío, agregando valor dummy...${NC}"
        if ! grep -q "^WEB_APP_URL=" .env; then
            echo "WEB_APP_URL=http://localhost" >> .env
            echo "WEB_APP_KEY=dummy_key" >> .env
        fi
    fi
else
    echo -e "${YELLOW}⚠️  WEB_APP_URL no encontrado, agregando...${NC}"
    echo "WEB_APP_URL=http://localhost" >> .env
    echo "WEB_APP_KEY=dummy_key" >> .env
    echo -e "${GREEN}✅ WEB_APP_URL agregado${NC}"
fi
echo ""

echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
echo "Se han corregido los problemas críticos:"
echo "  - Columna addon_type"
echo "  - Configuración LANGUAGE"
echo "  - Configuración WEB_APP_URL"
echo ""
echo "Próximos pasos:"
echo "1. Reiniciar el contenedor: docker restart metin2-server"
echo "2. Esperar 30 segundos: sleep 30"
echo "3. Verificar estado: bash verificar-estado-servidor.sh"
echo ""

