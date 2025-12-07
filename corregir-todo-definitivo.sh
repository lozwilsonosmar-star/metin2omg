#!/bin/bash
# Script definitivo para corregir todos los problemas
# Uso: bash corregir-todo-definitivo.sh

set -e

echo "=========================================="
echo "Corrección Definitiva - Todos los Problemas"
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

# 1. Asegurar AUTH_SERVER=master en .env
echo -e "${GREEN}1. Corrigiendo AUTH_SERVER en .env...${NC}"
if grep -q "^GAME_AUTH_SERVER=" .env; then
    sed -i 's/^GAME_AUTH_SERVER=.*/GAME_AUTH_SERVER=master/' .env
else
    echo "GAME_AUTH_SERVER=master" >> .env
fi
echo -e "${GREEN}   ✅ AUTH_SERVER configurado${NC}"
echo ""

# 2. Asegurar LANGUAGE en locale
echo -e "${GREEN}2. Verificando LANGUAGE en locale...${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common <<EOF 2>&1 | grep -v "Duplicate entry" || true
INSERT IGNORE INTO locale (mKey, mValue) VALUES ('LANGUAGE', 'kr');
INSERT IGNORE INTO locale (mKey, mValue) VALUES ('LOCALE', 'korea');
EOF
echo -e "${GREEN}   ✅ LANGUAGE verificado${NC}"
echo ""

# 3. Corregir addon_type - cambiar a MEDIUMINT UNSIGNED para soportar 65535
echo -e "${GREEN}3. Corrigiendo tipo de columna addon_type...${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player <<EOF 2>&1 || true
ALTER TABLE item_proto MODIFY COLUMN addon_type MEDIUMINT UNSIGNED NOT NULL DEFAULT 0;
EOF
echo -e "${GREEN}   ✅ addon_type corregido a MEDIUMINT UNSIGNED${NC}"
echo ""

# 4. Limpiar valores problemáticos (por si acaso)
echo -e "${GREEN}4. Limpiando valores problemáticos en item_proto...${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player <<EOF 2>&1 || true
UPDATE item_proto SET addon_type = 0 WHERE addon_type > 16777215;
EOF
echo -e "${GREEN}   ✅ Valores limpiados${NC}"
echo ""

unset MYSQL_PWD

# 5. Forzar regeneración de game.conf
echo -e "${GREEN}5. Forzando regeneración de game.conf...${NC}"
# Detener contenedor
docker stop metin2-server 2>/dev/null || true
# Eliminar game.conf si existe dentro del contenedor (se regenerará al iniciar)
echo -e "${GREEN}   ✅ Contenedor detenido (se regenerará game.conf al reiniciar)${NC}"
echo ""

# 6. Reiniciar contenedor
echo -e "${GREEN}6. Reiniciando contenedor...${NC}"
docker start metin2-server
echo -e "${GREEN}   ✅ Contenedor reiniciado${NC}"
echo ""

echo "=========================================="
echo "✅ Correcciones Aplicadas"
echo "=========================================="
echo ""
echo "Espera 30-60 segundos y verifica:"
echo "   bash verificar-estado-servidor.sh"
echo ""
echo "O verifica los logs directamente:"
echo "   docker logs --tail 50 metin2-server | grep -E 'AUTH_SERVER|TCP listening|ERROR'"
echo ""

