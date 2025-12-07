#!/bin/bash
# Script para configurar contraseña de root de MySQL directamente
# Uso: bash configurar-root-mysql-directo.sh

set -e

echo "=========================================="
echo "Configuración de Contraseña Root MySQL"
echo "=========================================="
echo ""

NEW_PASSWORD="proyectalean"

echo "Configurando contraseña de root de MySQL..."
echo "   Nueva contraseña: $NEW_PASSWORD"
echo ""

# Intentar conectarse sin contraseña usando sudo mysql
sudo mysql <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_PASSWORD';
FLUSH PRIVILEGES;
SQL

if [ $? -eq 0 ]; then
    echo "✅ Contraseña de root configurada exitosamente"
    echo ""
    echo "Credenciales:"
    echo "   Usuario: root"
    echo "   Contraseña: $NEW_PASSWORD"
else
    echo "❌ Error al configurar contraseña"
    echo ""
    echo "Intenta manualmente:"
    echo "   sudo mysql"
    echo "   ALTER USER 'root'@'localhost' IDENTIFIED BY 'proyectalean';"
    echo "   FLUSH PRIVILEGES;"
    echo "   EXIT;"
fi

echo ""

