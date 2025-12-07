#!/bin/bash
# Script directo para actualizar cuenta test
# Uso: bash actualizar-cuenta-directo.sh

echo "=========================================="
echo "Actualización Directa de Cuenta Test"
echo "=========================================="
echo ""

# Credenciales
TEST_USER="test"
PASSWORD_HASH="CC67043C7BCFF5EEA5566BD9B1F3C74FD9A5CF5D"

echo "Actualizando cuenta '$TEST_USER'..."
echo ""

# Actualizar cuenta directamente
mysql -uroot -pproyectalean -Dmetin2_account <<EOF
INSERT INTO account (login, password, social_id, status) 
VALUES ('$TEST_USER', '$PASSWORD_HASH', 'A', 'OK') 
ON DUPLICATE KEY UPDATE password='$PASSWORD_HASH', status='OK';
EOF

if [ $? -eq 0 ]; then
    echo "✅ Cuenta actualizada exitosamente"
    echo ""
    echo "Verificando cuenta..."
    mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, password, social_id, status FROM account WHERE login='$TEST_USER';"
    echo ""
    echo "✅ Listo. Intenta conectarte desde el cliente."
else
    echo "❌ Error al actualizar la cuenta"
fi

echo ""

