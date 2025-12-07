#!/bin/bash
# Script simple para actualizar cuenta test usando root
# Uso: bash actualizar-cuenta-simple.sh

echo "=========================================="
echo "Actualización Simple de Cuenta Test"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Credenciales
TEST_USER="test"
PASSWORD_HASH="CC67043C7BCFF5EEA5566BD9B1F3C74FD9A5CF5D"

echo "Actualizando cuenta '$TEST_USER' con hash: $PASSWORD_HASH"
echo ""

# Usar root directamente
mysql -uroot -pproyectalean -Dmetin2_account <<EOF
INSERT INTO account (login, password, social_id, status) 
VALUES ('$TEST_USER', '$PASSWORD_HASH', 'A', 'OK') 
ON DUPLICATE KEY UPDATE password='$PASSWORD_HASH', status='OK';
SELECT login, password, social_id, status FROM account WHERE login='$TEST_USER';
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Cuenta actualizada exitosamente"
    echo ""
    echo "Verificando cuenta..."
    mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, password, social_id, status FROM account WHERE login='$TEST_USER';"
    echo ""
    echo "✅ Listo. Intenta conectarte desde el cliente."
else
    echo ""
    echo "❌ Error al actualizar la cuenta"
    echo "Verificando estructura de la tabla..."
    mysql -uroot -pproyectalean -Dmetin2_account -e "DESCRIBE account;"
fi

echo ""

