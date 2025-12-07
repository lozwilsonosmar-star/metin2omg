#!/bin/bash
# Script para crear cuenta con hash Argon2id correcto
# Uso: bash crear-cuenta-argon2.sh

echo "=========================================="
echo "Creación de Cuenta con Hash Argon2id"
echo "=========================================="
echo ""

cd /opt/metin2omg

TEST_USER="test"
TEST_PASSWORD="metin2test123"

echo "⚠️  IMPORTANTE: El servidor usa Argon2id, no SHA1"
echo ""
echo "Para generar el hash Argon2id correcto, necesitamos:"
echo "1. Instalar la librería argon2"
echo "2. Usar un programa que genere el hash"
echo ""
echo "Mientras tanto, vamos a intentar usar el contenedor del servidor"
echo "para generar el hash correcto..."
echo ""

# Verificar si el contenedor está corriendo
if ! docker ps | grep -q "metin2-server"; then
    echo "❌ El contenedor no está corriendo. Iniciándolo..."
    docker start metin2-server
    sleep 5
fi

echo "Intentando generar hash Argon2id usando el contenedor..."
echo ""

# Intentar usar argon2 desde el contenedor si está disponible
ARGON2_HASH=$(docker exec metin2-server sh -c "which argon2 2>/dev/null && echo '$TEST_PASSWORD' | argon2 'salt123456789012345678901234567890' -id -t 3 -m 12 -p 1 -l 32 2>/dev/null | grep 'Encoded' | awk '{print \$2}'" 2>/dev/null)

if [ -z "$ARGON2_HASH" ]; then
    echo "⚠️  No se pudo generar hash Argon2id automáticamente"
    echo ""
    echo "SOLUCIÓN ALTERNATIVA:"
    echo "1. Instala argon2 en el VPS:"
    echo "   sudo apt-get update"
    echo "   sudo apt-get install -y argon2"
    echo ""
    echo "2. Luego ejecuta este comando para generar el hash:"
    echo "   echo -n '$TEST_PASSWORD' | argon2 'salt123456789012345678901234567890' -id -t 3 -m 12 -p 1 -l 32"
    echo ""
    echo "3. O usa este script Python (si tienes python3):"
    echo "   python3 -c \"import argon2; ph = argon2.PasswordHasher(); print(ph.hash('$TEST_PASSWORD'))\""
    echo ""
    echo "4. Una vez tengas el hash, actualiza la cuenta:"
    echo "   mysql -uroot -pproyectalean -Dmetin2_account -e \"UPDATE account SET password='TU_HASH_AQUI' WHERE login='test';\""
    echo ""
    exit 1
fi

echo "✅ Hash Argon2id generado: $ARGON2_HASH"
echo ""

echo "Actualizando cuenta '$TEST_USER'..."
mysql -uroot -pproyectalean -Dmetin2_account <<EOF
UPDATE account SET password='$ARGON2_HASH', status='OK', last_play=NOW() WHERE login='$TEST_USER';
EOF

if [ $? -eq 0 ]; then
    echo "✅ Cuenta actualizada con hash Argon2id"
    echo ""
    echo "Verificando cuenta..."
    mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, LEFT(password, 50) as password_preview, status FROM account WHERE login='$TEST_USER';" 2>/dev/null
    echo ""
    echo "✅ Listo. Intenta conectarte con:"
    echo "   Usuario: $TEST_USER"
    echo "   Contraseña: $TEST_PASSWORD"
else
    echo "❌ Error al actualizar la cuenta"
fi

echo ""

