#!/bin/bash
# Script para corregir el tamaño de la columna password (versión mejorada)
# Uso: bash corregir-columna-password-v2.sh

echo "=========================================="
echo "Corrección de Columna Password v2"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Verificando estructura actual de la tabla account..."
echo ""

mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null

echo ""
echo "2. Modificando columna password a VARCHAR(255)..."
echo ""

# Intentar modificar sin especificar DEFAULT para evitar conflictos
mysql -uroot -pproyectalean -Dmetin2_account <<EOF
ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL;
EOF

if [ $? -eq 0 ]; then
    echo "   ✅ Columna modificada exitosamente"
    echo ""
    echo "3. Verificando nuevo tamaño..."
    mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null
    echo ""
    echo "=========================================="
    echo "✅ Columna corregida"
    echo "=========================================="
    echo ""
    echo "Ahora puedes generar y actualizar el hash:"
    echo "   python3 -c \"from argon2 import PasswordHasher; ph = PasswordHasher(); print(ph.hash('metin2test123'))\""
    echo ""
    echo "Luego actualiza la cuenta con el hash generado"
    echo ""
else
    echo "   ⚠️  Error al modificar, intentando método alternativo..."
    echo ""
    
    # Método alternativo: usar CHANGE en lugar de MODIFY
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
ALTER TABLE account CHANGE password password VARCHAR(255) NOT NULL;
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Columna modificada con método alternativo"
        echo ""
        echo "Verificando..."
        mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null
        echo ""
        echo "✅ Listo. Ahora puedes actualizar el hash."
    else
        echo "   ❌ Error persistente"
        echo ""
        echo "Verificando estructura completa de la tabla..."
        mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW CREATE TABLE account\G" 2>/dev/null | grep -A 5 "password"
        echo ""
        echo "Intenta modificar manualmente:"
        echo "   mysql -uroot -pproyectalean -Dmetin2_account"
        echo "   ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL;"
    fi
fi

echo ""

