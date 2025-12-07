#!/bin/bash
# Script para corregir la tabla account completa (create_time y password)
# Uso: bash corregir-tabla-account-completo.sh

echo "=========================================="
echo "Corrección Completa de Tabla Account"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Corrigiendo columna create_time primero..."
echo ""

# Corregir create_time cambiando el DEFAULT inválido
mysql -uroot -pproyectalean -Dmetin2_account <<EOF
ALTER TABLE account MODIFY COLUMN create_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;
EOF

if [ $? -ne 0 ]; then
    echo "   ⚠️  Error con CURRENT_TIMESTAMP, intentando sin DEFAULT..."
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
ALTER TABLE account MODIFY COLUMN create_time datetime NOT NULL;
EOF
fi

echo ""
echo "2. Modificando columna password a VARCHAR(255)..."
echo ""

mysql -uroot -pproyectalean -Dmetin2_account <<EOF
ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL;
EOF

if [ $? -eq 0 ]; then
    echo "   ✅ Columna password modificada exitosamente"
    echo ""
    echo "3. Verificando cambios..."
    echo ""
    mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW COLUMNS FROM account WHERE Field IN ('password', 'create_time');" 2>/dev/null
    echo ""
    echo "=========================================="
    echo "✅ Tabla corregida"
    echo "=========================================="
    echo ""
    echo "Ahora puedes generar y actualizar el hash:"
    echo ""
    echo "   python3 -c \"from argon2 import PasswordHasher; ph = PasswordHasher(); print(ph.hash('metin2test123'))\""
    echo ""
    echo "Luego actualiza la cuenta:"
    echo "   mysql -uroot -pproyectalean -Dmetin2_account -e \"UPDATE account SET password='HASH_AQUI' WHERE login='test';\""
    echo ""
else
    echo "   ⚠️  Error al modificar password, intentando método alternativo..."
    echo ""
    
    # Intentar con CHANGE
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
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
        echo "Intenta ejecutar estos comandos manualmente en MySQL:"
        echo ""
        echo "   mysql -uroot -pproyectalean -Dmetin2_account"
        echo "   ALTER TABLE account MODIFY COLUMN create_time datetime NOT NULL;"
        echo "   ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL;"
        echo "   exit"
    fi
fi

echo ""

