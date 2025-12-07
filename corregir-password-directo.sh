#!/bin/bash
# Script directo para corregir columna password sin cambiar SQL_MODE
# Uso: bash corregir-password-directo.sh

echo "=========================================="
echo "Corrección Directa de Columna Password"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Modificando columna password directamente..."
echo ""

# Intentar modificar directamente, ignorando errores de valores por defecto
mysql -uroot -pproyectalean -Dmetin2_account <<'EOF'
SET SESSION sql_mode = '';
ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL;
EOF

if [ $? -eq 0 ]; then
    echo "   ✅ Columna password modificada exitosamente"
    echo ""
    echo "2. Verificando cambio..."
    echo ""
    mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null
    echo ""
    echo "=========================================="
    echo "✅ Columna corregida"
    echo "=========================================="
    echo ""
    echo "Ahora genera el hash y actualiza la cuenta:"
    echo ""
    echo "   python3 -c \"from argon2 import PasswordHasher; ph = PasswordHasher(); print(ph.hash('metin2test123'))\""
    echo ""
    echo "Luego actualiza:"
    echo "   mysql -uroot -pproyectalean -Dmetin2_account -e \"UPDATE account SET password='HASH_AQUI' WHERE login='test';\""
    echo ""
else
    echo "   ⚠️  Error, intentando con método alternativo..."
    echo ""
    
    # Método alternativo: usar CHANGE en lugar de MODIFY
    mysql -uroot -pproyectalean -Dmetin2_account <<'EOF'
SET SESSION sql_mode = '';
ALTER TABLE account CHANGE password password VARCHAR(255) NOT NULL;
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Columna password modificada con método alternativo"
        echo ""
        echo "Verificando..."
        mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null
        echo ""
        echo "✅ Listo. Ahora puedes actualizar el hash."
    else
        echo "   ❌ Error persistente"
        echo ""
        echo "Intenta ejecutar manualmente:"
        echo ""
        echo "   mysql -uroot -pproyectalean -Dmetin2_account"
        echo "   SET SESSION sql_mode = '';"
        echo "   ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL;"
        echo "   exit"
    fi
fi

echo ""

