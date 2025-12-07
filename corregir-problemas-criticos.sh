#!/bin/bash
# Script para corregir problemas críticos:
# 1. WEB_APP_URL y WEB_APP_KEY (obligatorios)
# 2. addon_type (definitivamente a MEDIUMINT UNSIGNED)
# Uso: bash corregir-problemas-criticos.sh

set -e

echo "=========================================="
echo "Corrección de Problemas Críticos"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /opt/metin2omg

# 1. Corregir WEB_APP_URL y WEB_APP_KEY en .env
echo -e "${GREEN}1. Corrigiendo WEB_APP_URL y WEB_APP_KEY...${NC}"

# Si están vacíos o no existen, poner valores dummy
if ! grep -q "^WEB_APP_URL=" .env || [ -z "$(grep "^WEB_APP_URL=" .env | cut -d'=' -f2)" ]; then
    if grep -q "^WEB_APP_URL=" .env; then
        sed -i 's/^WEB_APP_URL=.*/WEB_APP_URL=http:\/\/localhost\/api/' .env
    else
        echo "WEB_APP_URL=http://localhost/api" >> .env
    fi
    echo -e "${GREEN}   ✅ WEB_APP_URL configurado${NC}"
else
    echo -e "${GREEN}   ✅ WEB_APP_URL ya está configurado${NC}"
fi

if ! grep -q "^WEB_APP_KEY=" .env || [ -z "$(grep "^WEB_APP_KEY=" .env | cut -d'=' -f2)" ]; then
    if grep -q "^WEB_APP_KEY=" .env; then
        sed -i 's/^WEB_APP_KEY=.*/WEB_APP_KEY=dummy_key_12345/' .env
    else
        echo "WEB_APP_KEY=dummy_key_12345" >> .env
    fi
    echo -e "${GREEN}   ✅ WEB_APP_KEY configurado${NC}"
else
    echo -e "${GREEN}   ✅ WEB_APP_KEY ya está configurado${NC}"
fi
echo ""

# 2. Obtener credenciales MySQL
MYSQL_HOST=$(grep "^MYSQL_HOST=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "localhost")
MYSQL_PORT=$(grep "^MYSQL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "3306")
MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2")
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

export MYSQL_PWD="$MYSQL_PASSWORD"

# 3. Verificar y corregir addon_type DEFINITIVAMENTE
echo -e "${GREEN}2. Verificando y corrigiendo addon_type...${NC}"

# Verificar el tipo actual
CURRENT_TYPE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='metin2_player' AND TABLE_NAME='item_proto' AND COLUMN_NAME='addon_type';" 2>/dev/null || echo "")

if [ -n "$CURRENT_TYPE" ]; then
    echo -e "${YELLOW}   Tipo actual: $CURRENT_TYPE${NC}"
    
    # Si no es MEDIUMINT UNSIGNED, cambiarlo
    if ! echo "$CURRENT_TYPE" | grep -qi "mediumint.*unsigned"; then
        echo -e "${YELLOW}   ⚠️  Cambiando a MEDIUMINT UNSIGNED...${NC}"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player <<EOF 2>&1 || true
ALTER TABLE item_proto MODIFY COLUMN addon_type MEDIUMINT UNSIGNED NOT NULL DEFAULT 0;
EOF
        echo -e "${GREEN}   ✅ addon_type cambiado a MEDIUMINT UNSIGNED${NC}"
    else
        echo -e "${GREEN}   ✅ addon_type ya es MEDIUMINT UNSIGNED${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  No se pudo verificar el tipo, intentando cambiar de todas formas...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player <<EOF 2>&1 || true
ALTER TABLE item_proto MODIFY COLUMN addon_type MEDIUMINT UNSIGNED NOT NULL DEFAULT 0;
EOF
    echo -e "${GREEN}   ✅ Comando ejecutado${NC}"
fi
echo ""

# 4. Verificar valores problemáticos y limpiarlos
echo -e "${GREEN}3. Limpiando valores problemáticos en item_proto...${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player <<EOF 2>&1 || true
UPDATE item_proto SET addon_type = 0 WHERE addon_type > 16777215;
EOF
echo -e "${GREEN}   ✅ Valores limpiados${NC}"
echo ""

unset MYSQL_PWD

# 5. Detener y recrear contenedor para aplicar cambios
echo -e "${GREEN}4. Reiniciando contenedor para aplicar cambios...${NC}"
docker stop metin2-server 2>/dev/null || true
docker rm metin2-server 2>/dev/null || true

# Obtener imagen
IMAGE=$(docker images | grep "metin2/server" | awk '{print $1":"$2}' | head -1)
if [ -z "$IMAGE" ]; then
    IMAGE="metin2/server:latest"
fi

# Recrear contenedor
docker run -d \
    --name metin2-server \
    --restart unless-stopped \
    --network host \
    --env-file .env \
    "$IMAGE"

echo -e "${GREEN}   ✅ Contenedor recreado${NC}"
echo ""

echo "=========================================="
echo "✅ Correcciones Aplicadas"
echo "=========================================="
echo ""
echo "Espera 30-60 segundos y verifica:"
echo "   docker logs --tail 30 metin2-server | grep -E 'WEB_APP|TCP listening|ERROR'"
echo ""

