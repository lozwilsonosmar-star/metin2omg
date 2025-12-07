#!/bin/bash
# Script para resetear/configurar contraseña de root de MySQL
# Uso: bash resetear-root-mysql.sh

set -e

echo "=========================================="
echo "Resetear/Configurar Contraseña Root MySQL"
echo "=========================================="
echo ""

NEW_PASSWORD="proyectalean"

echo "Nueva contraseña: $NEW_PASSWORD"
echo ""

# Método 1: Intentar con mysql_safe para resetear
echo "Método 1: Intentando resetear contraseña..."
sudo systemctl stop mysql 2>/dev/null || sudo systemctl stop mariadb 2>/dev/null || true

# Crear archivo temporal con comandos SQL
cat > /tmp/reset_root.sql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_PASSWORD';
FLUSH PRIVILEGES;
EOF

# Intentar iniciar MySQL en modo seguro
echo "Intentando iniciar MySQL en modo seguro..."
sudo mysqld_safe --skip-grant-tables --skip-networking &
sleep 3

# Intentar conectarse sin contraseña
mysql -u root <<SQL
USE mysql;
UPDATE user SET authentication_string=PASSWORD('$NEW_PASSWORD') WHERE User='root';
FLUSH PRIVILEGES;
SQL

# Detener MySQL seguro y reiniciar normal
sudo pkill mysqld_safe
sudo systemctl start mysql 2>/dev/null || sudo systemctl start mariadb 2>/dev/null || true

sleep 2

# Verificar
if mysql -u root -p"$NEW_PASSWORD" -e "SELECT 1;" 2>/dev/null; then
    echo "✅ Contraseña configurada exitosamente"
    rm -f /tmp/reset_root.sql
    exit 0
fi

# Método 2: Usar mysqladmin con sudo
echo ""
echo "Método 2: Intentando con mysqladmin..."
if sudo mysqladmin -u root password "$NEW_PASSWORD" 2>/dev/null; then
    echo "✅ Contraseña configurada con mysqladmin"
    exit 0
fi

# Método 3: Intentar conectar usando el usuario metin2 para cambiar root
echo ""
echo "Método 3: Intentando con usuario metin2..."
cd /opt/metin2omg
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

if [ -n "$MYSQL_PASSWORD" ]; then
    mysql -h127.0.0.1 -P3306 -umetin2 -p"$MYSQL_PASSWORD" <<SQL 2>/dev/null || true
ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_PASSWORD';
FLUSH PRIVILEGES;
SQL
    
    if mysql -u root -p"$NEW_PASSWORD" -e "SELECT 1;" 2>/dev/null; then
        echo "✅ Contraseña configurada usando usuario metin2"
        exit 0
    fi
fi

# Si todo falla, mostrar instrucciones
echo ""
echo "❌ No se pudo configurar automáticamente"
echo ""
echo "Intenta manualmente con estos pasos:"
echo ""
echo "1. Detener MySQL:"
echo "   sudo systemctl stop mysql"
echo ""
echo "2. Iniciar MySQL en modo seguro:"
echo "   sudo mysqld_safe --skip-grant-tables --skip-networking &"
echo ""
echo "3. En otra terminal, conectarse:"
echo "   mysql -u root"
echo ""
echo "4. Ejecutar:"
echo "   USE mysql;"
echo "   UPDATE user SET authentication_string=PASSWORD('proyectalean') WHERE User='root';"
echo "   FLUSH PRIVILEGES;"
echo "   EXIT;"
echo ""
echo "5. Reiniciar MySQL:"
echo "   sudo pkill mysqld_safe"
echo "   sudo systemctl start mysql"
echo ""

