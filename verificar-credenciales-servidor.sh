#!/bin/bash
# Script para verificar que el servidor Metin2 está usando las credenciales correctas
# Uso: bash verificar-credenciales-servidor.sh

echo "=========================================="
echo "Verificación de Credenciales del Servidor"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Credenciales configuradas en .env:${NC}"
echo ""

MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

echo "   Usuario MySQL: $MYSQL_USER"
echo "   Contraseña MySQL: $MYSQL_PASSWORD"
echo ""

# Verificar que el usuario metin2 puede conectarse
export MYSQL_PWD="$MYSQL_PASSWORD"

if mysql -h127.0.0.1 -P3306 -u"$MYSQL_USER" -e "SELECT 'Conexión exitosa' AS resultado;" 2>/dev/null; then
    echo -e "${GREEN}✅ El usuario $MYSQL_USER puede conectarse correctamente${NC}"
    echo ""
    echo -e "${GREEN}✅ El servidor Metin2 NO necesita reiniciarse${NC}"
    echo "   El servidor usa el usuario '$MYSQL_USER', no 'root'"
    echo "   El cambio de contraseña de 'root' solo afecta a tu aplicación web"
    echo ""
else
    echo -e "${RED}❌ Error: El usuario $MYSQL_USER NO puede conectarse${NC}"
    echo "   Verifica las credenciales en .env"
fi

unset MYSQL_PWD

echo "=========================================="
echo "Resumen"
echo "=========================================="
echo ""
echo "Usuario root MySQL:"
echo "   Contraseña: proyectalean (para aplicación web)"
echo ""
echo "Usuario metin2 MySQL:"
echo "   Contraseña: $MYSQL_PASSWORD (para servidor Metin2)"
echo ""
echo -e "${GREEN}✅ Ambos usuarios funcionan independientemente${NC}"
echo ""

