#!/bin/bash
# Script para ver el formato de contraseñas y actualizarlas

echo "=========================================="
echo "Verificación y Actualización de Contraseñas"
echo "=========================================="
echo ""

export MYSQL_PWD="proyectalean"

# Ver formato actual de contraseñas
echo "Formato actual de contraseñas:"
mysql -uroot -Dmetin2_player -e "
SELECT 
    id,
    login,
    SUBSTRING(password, 1, 40) as password_preview,
    LENGTH(password) as length,
    CASE 
        WHEN password LIKE '\$argon2id%' THEN 'Argon2id ✅'
        WHEN password LIKE '\$2a\$%' THEN 'bcrypt ❌'
        WHEN password LIKE '*%' THEN 'MySQL hash ❌'
        WHEN LENGTH(password) < 20 THEN 'Texto plano ❌'
        ELSE 'Desconocido ❌'
    END as formato
FROM account;
"

echo ""
echo "¿Qué contraseña quieres usar para la cuenta 'test'?"
read -sp "Nueva contraseña para 'test': " NEW_PASSWORD
echo ""

if [ -z "$NEW_PASSWORD" ]; then
    echo "❌ Contraseña no puede estar vacía"
    unset MYSQL_PWD
    exit 1
fi

echo ""
echo "Generando hash Argon2id..."

# Verificar si argon2 está instalado
if ! python3 -c "import argon2" 2>/dev/null; then
    echo "⚠️  argon2-cffi no está instalado"
    echo "Instalando..."
    pip3 install argon2-cffi --quiet 2>&1 || {
        echo "❌ Error al instalar argon2-cffi"
        echo "Instala manualmente: pip3 install argon2-cffi"
        unset MYSQL_PWD
        exit 1
    }
fi

# Generar hash
ARGON2_HASH=$(python3 <<PYTHON
from argon2 import PasswordHasher
ph = PasswordHasher()
hash = ph.hash('$NEW_PASSWORD')
print(hash)
PYTHON
2>&1)

if [ -z "$ARGON2_HASH" ] || [ "${#ARGON2_HASH}" -lt 50 ]; then
    echo "❌ Error al generar hash"
    unset MYSQL_PWD
    exit 1
fi

echo "✅ Hash generado"
echo ""

# Actualizar contraseña
echo "Actualizando contraseña para 'test'..."
mysql -uroot -Dmetin2_player -e "
UPDATE account 
SET password = '$ARGON2_HASH',
    status = 'OK'
WHERE login = 'test';
" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Contraseña actualizada"
    echo ""
    echo "Verificación:"
    mysql -uroot -Dmetin2_player -e "
    SELECT 
        login,
        SUBSTRING(password, 1, 30) as password_preview,
        CASE 
            WHEN password LIKE '\$argon2id%' THEN 'Argon2id ✅'
            ELSE 'Otro formato ❌'
        END as formato,
        status
    FROM account 
    WHERE login = 'test';
    "
else
    echo "❌ Error al actualizar"
fi

echo ""
unset MYSQL_PWD

