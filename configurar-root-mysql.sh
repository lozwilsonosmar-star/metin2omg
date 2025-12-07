#!/bin/bash
# Script para configurar contraseña de root de MySQL
# Uso: bash configurar-root-mysql.sh

set -e

echo "=========================================="
echo "Configuración de Contraseña Root MySQL"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

NEW_PASSWORD="proyectalean"

echo -e "${GREEN}Configurando contraseña de root de MySQL...${NC}"
echo "   Nueva contraseña: $NEW_PASSWORD"
echo ""

# Intentar conectarse sin contraseña primero
if sudo mysql -u root <<EOF 2>/dev/null; then
    echo -e "${GREEN}Conectado a MySQL sin contraseña${NC}"
    
    sudo mysql -u root <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_PASSWORD';
FLUSH PRIVILEGES;
SQL
    
    echo -e "${GREEN}✅ Contraseña de root configurada${NC}"
else
    echo -e "${YELLOW}⚠️  No se pudo conectar sin contraseña${NC}"
    echo -e "${YELLOW}   Intentando con autenticación por socket...${NC}"
    
    # Intentar con sudo mysql (sin -u root)
    sudo mysql <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_PASSWORD';
FLUSH PRIVILEGES;
SQL
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Contraseña de root configurada${NC}"
    else
        echo -e "${RED}❌ Error al configurar contraseña${NC}"
        echo ""
        echo "Intenta manualmente:"
        echo "   sudo mysql"
        echo "   ALTER USER 'root'@'localhost' IDENTIFIED BY 'proyectalean';"
        echo "   FLUSH PRIVILEGES;"
        echo "   EXIT;"
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "✅ Configuración Completada"
echo "=========================================="
echo ""
echo "Credenciales de root MySQL:"
echo "   Usuario: root"
echo "   Contraseña: $NEW_PASSWORD"
echo ""
echo "Ahora puedes usar estas credenciales en:"
echo "   - Tu aplicación web"
echo "   - MySQL Workbench (si quieres usar root)"
echo ""

