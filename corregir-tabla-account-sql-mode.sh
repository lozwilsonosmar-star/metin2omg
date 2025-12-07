#!/bin/bash
# Script para corregir tabla account deshabilitando temporalmente SQL_MODE estricto
# Uso: bash corregir-tabla-account-sql-mode.sh

echo "=========================================="
echo "Corrección de Tabla Account (SQL_MODE)"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Deshabilitando temporalmente SQL_MODE estricto..."
echo ""

# Guardar el SQL_MODE actual y deshabilitarlo temporalmente
mysql -uroot -pproyectalean -Dmetin2_account <<EOF
SET @old_sql_mode = @@sql_mode;
SET sql_mode = '';
EOF

echo "2. Corrigiendo columnas problemáticas..."
echo ""

# Corregir todas las columnas problemáticas
mysql -uroot -pproyectalean -Dmetin2_account <<EOF
SET sql_mode = '';

-- Corregir create_time
ALTER TABLE account MODIFY COLUMN create_time datetime NOT NULL;

-- Corregir availDt si existe
ALTER TABLE account MODIFY COLUMN availDt datetime NULL;

-- Corregir password
ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL;

-- Restaurar SQL_MODE
SET sql_mode = @old_sql_mode;
EOF

if [ $? -eq 0 ]; then
    echo "   ✅ Columnas corregidas exitosamente"
    echo ""
    echo "3. Verificando cambios..."
    echo ""
    mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW COLUMNS FROM account WHERE Field IN ('password', 'create_time', 'availDt');" 2>/dev/null
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
    echo "   ⚠️  Error al corregir, intentando método alternativo..."
    echo ""
    
    # Método alternativo: corregir una por una
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
SET sql_mode = '';
ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL;
SET sql_mode = @old_sql_mode;
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Columna password corregida"
        echo ""
        echo "Verificando..."
        mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null
        echo ""
        echo "✅ Listo. Ahora puedes actualizar el hash."
    else
        echo "   ❌ Error persistente"
        echo ""
        echo "Intenta ejecutar estos comandos manualmente:"
        echo ""
        echo "   mysql -uroot -pproyectalean -Dmetin2_account"
        echo "   SET sql_mode = '';"
        echo "   ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL;"
        echo "   SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';"
        echo "   exit"
    fi
fi

echo ""

