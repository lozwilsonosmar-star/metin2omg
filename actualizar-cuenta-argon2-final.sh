#!/bin/bash
# Script final para generar hash Argon2id y actualizar cuenta
# Uso: bash actualizar-cuenta-argon2-final.sh

echo "=========================================="
echo "Actualización Final de Cuenta con Argon2id"
echo "=========================================="
echo ""

cd /opt/metin2omg

TEST_USER="test"
TEST_PASSWORD="metin2test123"

echo "1. Generando hash Argon2id para: $TEST_PASSWORD"
echo ""

ARGON2_HASH=$(python3 <<PYTHON
try:
    from argon2 import PasswordHasher
    ph = PasswordHasher()
    hash = ph.hash('$TEST_PASSWORD')
    print(hash)
except Exception as e:
    print("")
    import sys
    sys.stderr.write(f"Error: {e}\n")
PYTHON
2>&1)

if [ -n "$ARGON2_HASH" ] && [ "${#ARGON2_HASH}" -gt 50 ]; then
    echo "   ✅ Hash generado exitosamente"
    echo "   Hash (primeros 80 caracteres): ${ARGON2_HASH:0:80}..."
    echo ""
    
    echo "2. Actualizando cuenta '$TEST_USER'..."
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
UPDATE account SET password='$ARGON2_HASH', status='OK', last_play=NOW() WHERE login='$TEST_USER';
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Cuenta actualizada exitosamente"
        echo ""
        echo "3. Verificando cuenta..."
        mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, LEFT(password, 60) as password_preview, status FROM account WHERE login='$TEST_USER';" 2>/dev/null
        echo ""
        echo "=========================================="
        echo "✅ ¡LISTO!"
        echo "=========================================="
        echo ""
        echo "📋 Credenciales para conectarte:"
        echo "   Usuario: $TEST_USER"
        echo "   Contraseña: $TEST_PASSWORD"
        echo ""
        echo "🎮 Ahora intenta conectarte desde el cliente Metin2"
        echo ""
        exit 0
    else
        echo "   ❌ Error al actualizar la cuenta"
        echo ""
        echo "   Intenta manualmente:"
        echo "   mysql -uroot -pproyectalean -Dmetin2_account -e \"UPDATE account SET password='$ARGON2_HASH' WHERE login='test';\""
    fi
else
    echo "   ❌ Error al generar el hash"
    echo ""
    echo "   Mensaje de error:"
    echo "$ARGON2_HASH" | grep -i error || echo "   (sin detalles)"
    echo ""
    echo "   Verifica que argon2-cffi esté instalado:"
    echo "   python3 -c 'import argon2'"
fi

echo ""

