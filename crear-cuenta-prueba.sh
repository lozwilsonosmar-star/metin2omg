#!/bin/bash
# Script para crear una cuenta de prueba
# Uso: bash crear-cuenta-prueba.sh [usuario] [contraseña]

set -e

echo "=========================================="
echo "Creación de Cuenta de Prueba"
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

# Obtener usuario y contraseña
USERNAME="${1:-test}"
PASSWORD="${2:-test123}"

echo -e "${GREEN}Creando cuenta:${NC}"
echo "   Usuario: $USERNAME"
echo "   Contraseña: $PASSWORD"
echo ""

# Verificar si la cuenta ya existe
EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -sN -e "SELECT COUNT(*) FROM account WHERE login='$USERNAME';" 2>/dev/null || echo "0")

if [ "$EXISTS" != "0" ]; then
    echo -e "${YELLOW}⚠️  La cuenta '$USERNAME' ya existe${NC}"
    read -p "¿Deseas eliminarla y crearla de nuevo? (s/N): " REEMPLAZAR
    if [[ "$REEMPLAZAR" =~ ^[Ss]$ ]]; then
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_account <<EOF 2>&1 || true
DELETE FROM account WHERE login='$USERNAME';
EOF
        echo -e "${GREEN}   ✅ Cuenta eliminada${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Manteniendo cuenta existente${NC}"
        unset MYSQL_PWD
        exit 0
    fi
fi

# Crear la cuenta
echo -e "${GREEN}Insertando cuenta en la base de datos...${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_account <<EOF 2>&1 || true
INSERT INTO account (login, password, social_id, status) VALUES ('$USERNAME', SHA1('$PASSWORD'), 'A', 'OK');
EOF

# Verificar que se creó
CREATED=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -sN -e "SELECT COUNT(*) FROM account WHERE login='$USERNAME';" 2>/dev/null || echo "0")

if [ "$CREATED" != "0" ]; then
    echo -e "${GREEN}✅ Cuenta creada exitosamente${NC}"
    echo ""
    echo "=========================================="
    echo "✅ CUENTA CREADA"
    echo "=========================================="
    echo ""
    echo "   Usuario: $USERNAME"
    echo "   Contraseña: $PASSWORD"
    echo ""
    echo -e "${BLUE}🎮 Configuración del Cliente:${NC}"
    echo ""
    echo "   IP del servidor: 72.61.12.2"
    echo "   Puerto: 12345"
    echo ""
    echo "   Usa estas credenciales para conectarte desde el cliente Metin2"
    echo ""
else
    echo -e "${RED}❌ Error al crear la cuenta${NC}"
    echo "   Verifica las credenciales de MySQL en .env"
fi

unset MYSQL_PWD

echo ""

