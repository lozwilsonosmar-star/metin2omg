#!/bin/bash
# Script para crear automáticamente las bases de datos y usuario
# Uso: bash setup-database.sh [mysql_root_password]

set -e

echo "=========================================="
echo "Configuración de Base de Datos Metin2"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar que MySQL/MariaDB está corriendo
if ! systemctl is-active --quiet mariadb && ! systemctl is-active --quiet mysql; then
    echo -e "${RED}❌ MySQL/MariaDB no está corriendo${NC}"
    echo "Iniciando MySQL/MariaDB..."
    systemctl start mariadb 2>/dev/null || systemctl start mysql
    sleep 2
fi

# Obtener contraseña de root
if [ -z "$1" ]; then
    echo -e "${YELLOW}⚠️  Necesitas la contraseña de root de MySQL${NC}"
    read -sp "Contraseña de root de MySQL: " ROOT_PASSWORD
    echo ""
else
    ROOT_PASSWORD="$1"
fi

# Contraseña para el usuario metin2
echo -e "${YELLOW}⚠️  Configurando usuario metin2${NC}"
read -sp "Contraseña para usuario 'metin2' (o Enter para generar automática): " METIN2_PASSWORD
echo ""

if [ -z "$METIN2_PASSWORD" ]; then
    METIN2_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
    echo -e "${GREEN}✅ Contraseña generada automáticamente: ${METIN2_PASSWORD}${NC}"
    echo -e "${YELLOW}⚠️  GUARDA ESTA CONTRASEÑA - la necesitarás para el archivo .env${NC}"
fi

# Crear script SQL temporal
SQL_FILE=$(mktemp)
cat > "$SQL_FILE" << EOF
-- Crear bases de datos
CREATE DATABASE IF NOT EXISTS metin2_account CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS metin2_common CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS metin2_player CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS metin2_log CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear usuario
CREATE USER IF NOT EXISTS 'metin2'@'localhost' IDENTIFIED BY '${METIN2_PASSWORD}';
CREATE USER IF NOT EXISTS 'metin2'@'%' IDENTIFIED BY '${METIN2_PASSWORD}';

-- Otorgar privilegios
GRANT ALL PRIVILEGES ON metin2_account.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_common.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_player.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_log.* TO 'metin2'@'localhost';

GRANT ALL PRIVILEGES ON metin2_account.* TO 'metin2'@'%';
GRANT ALL PRIVILEGES ON metin2_common.* TO 'metin2'@'%';
GRANT ALL PRIVILEGES ON metin2_player.* TO 'metin2'@'%';
GRANT ALL PRIVILEGES ON metin2_log.* TO 'metin2'@'%';

FLUSH PRIVILEGES;

-- Mostrar bases de datos creadas
SHOW DATABASES LIKE 'metin2_%';
EOF

# Ejecutar script SQL
echo -e "${GREEN}📦 Creando bases de datos y usuario...${NC}"

if mysql -u root -p"${ROOT_PASSWORD}" < "$SQL_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ Bases de datos creadas exitosamente!${NC}"
    echo ""
    echo -e "${GREEN}📋 Resumen:${NC}"
    echo "  Usuario: metin2"
    echo "  Contraseña: ${METIN2_PASSWORD}"
    echo "  Bases de datos:"
    echo "    - metin2_account"
    echo "    - metin2_common"
    echo "    - metin2_player"
    echo "    - metin2_log"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANTE: Guarda esta contraseña para el archivo .env${NC}"
    
    # Guardar contraseña en archivo temporal
    echo "$METIN2_PASSWORD" > /tmp/metin2_db_password.txt
    chmod 600 /tmp/metin2_db_password.txt
    echo -e "${GREEN}✅ Contraseña guardada en /tmp/metin2_db_password.txt${NC}"
else
    echo -e "${RED}❌ Error al crear bases de datos${NC}"
    echo "Verifica que la contraseña de root sea correcta"
    rm -f "$SQL_FILE"
    exit 1
fi

# Limpiar
rm -f "$SQL_FILE"

echo ""
echo -e "${GREEN}✅ Configuración de base de datos completada!${NC}"


