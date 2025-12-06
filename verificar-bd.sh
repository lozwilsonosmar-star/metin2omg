#!/bin/bash
# Script para verificar el estado de las bases de datos después del primer inicio

echo "=========================================="
echo "Verificación de Bases de Datos Metin2"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Leer contraseña de root
read -sp "Contraseña de root de MySQL: " ROOT_PASSWORD
echo ""

# Verificar bases de datos
echo -e "${GREEN}📊 Verificando bases de datos...${NC}"
mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW DATABASES LIKE 'metin2_%';" 2>/dev/null

echo ""
echo -e "${YELLOW}📋 Verificando tablas en metin2_common...${NC}"
TABLES=$(mysql -u root -p"${ROOT_PASSWORD}" -e "USE metin2_common; SHOW TABLES;" 2>/dev/null | wc -l)

if [ "$TABLES" -gt 1 ]; then
    echo -e "${GREEN}✅ Tablas encontradas: $((TABLES - 1))${NC}"
    echo ""
    echo "Tablas creadas:"
    mysql -u root -p"${ROOT_PASSWORD}" -e "USE metin2_common; SHOW TABLES;" 2>/dev/null | tail -n +2
else
    echo -e "${YELLOW}⚠️  Aún no hay tablas. Esto es normal si el servidor no se ha iniciado aún.${NC}"
    echo "Las tablas se crearán automáticamente cuando inicies el servidor por primera vez."
fi

echo ""
echo -e "${GREEN}✅ Verificación completada!${NC}"

