#!/bin/bash
# Script para configurar contraseña de root de MySQL (versión mejorada)
# Uso: bash configurar-root-mysql-v2.sh

set -e

echo "=========================================="
echo "Configuración de Contraseña Root MySQL"
echo "=========================================="
echo ""

NEW_PASSWORD="proyectalean"

echo "Configurando contraseña de root de MySQL..."
echo "   Nueva contraseña: $NEW_PASSWORD"
echo ""

# Método 1: Intentar con sudo mysql (sin -u root)
echo "Intentando método 1: sudo mysql..."
if sudo mysql <<SQL 2>/dev/null; then
ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_PASSWORD';
FLUSH PRIVILEGES;
SQL
    echo "✅ Contraseña configurada con método 1"
    exit 0
fi

# Método 2: Intentar con mysql directamente
echo "Intentando método 2: mysql -u root..."
if mysql -u root <<SQL 2>/dev/null; then
ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_PASSWORD';
FLUSH PRIVILEGES;
SQL
    echo "✅ Contraseña configurada con método 2"
    exit 0
fi

# Método 3: Usar mysqladmin
echo "Intentando método 3: mysqladmin..."
if sudo mysqladmin -u root password "$NEW_PASSWORD" 2>/dev/null; then
    echo "✅ Contraseña configurada con método 3"
    exit 0
fi

# Si todos fallan, mostrar instrucciones manuales
echo "❌ No se pudo configurar automáticamente"
echo ""
echo "Ejecuta manualmente:"
echo ""
echo "   sudo mysql"
echo ""
echo "Luego dentro de MySQL ejecuta:"
echo ""
echo "   ALTER USER 'root'@'localhost' IDENTIFIED BY 'proyectalean';"
echo "   FLUSH PRIVILEGES;"
echo "   EXIT;"
echo ""

