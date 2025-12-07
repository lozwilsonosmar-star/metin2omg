#!/bin/bash
# Script completo para actualizar cuenta test con todos los campos requeridos
# Uso: bash actualizar-cuenta-completo.sh

echo "=========================================="
echo "Actualización Completa de Cuenta Test"
echo "=========================================="
echo ""

# Credenciales
TEST_USER="test"
PASSWORD_HASH="CC67043C7BCFF5EEA5566BD9B1F3C74FD9A5CF5D"

echo "1. Verificando estructura de la tabla account..."
echo ""
mysql -uroot -pproyectalean -Dmetin2_account -e "DESCRIBE account;" 2>/dev/null | head -15
echo ""

echo "2. Actualizando cuenta '$TEST_USER'..."
echo ""

# Intentar INSERT con todos los campos comunes
mysql -uroot -pproyectalean -Dmetin2_account <<EOF
INSERT INTO account (login, password, social_id, status, last_play) 
VALUES ('$TEST_USER', '$PASSWORD_HASH', 'A', 'OK', NOW()) 
ON DUPLICATE KEY UPDATE password='$PASSWORD_HASH', status='OK', last_play=NOW();
EOF

if [ $? -eq 0 ]; then
    echo "✅ Cuenta actualizada exitosamente"
    echo ""
    echo "3. Verificando cuenta..."
    mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, password, social_id, status, last_play FROM account WHERE login='$TEST_USER';" 2>/dev/null
    echo ""
    echo "✅ Listo. Intenta conectarte desde el cliente."
else
    echo "❌ Error al actualizar la cuenta"
    echo ""
    echo "Intentando método alternativo (solo campos esenciales)..."
    
    # Método alternativo: UPDATE si existe, o INSERT mínimo
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
UPDATE account SET password='$PASSWORD_HASH', status='OK' WHERE login='$TEST_USER';
INSERT INTO account (login, password, social_id, status) 
SELECT '$TEST_USER', '$PASSWORD_HASH', 'A', 'OK'
WHERE NOT EXISTS (SELECT 1 FROM account WHERE login='$TEST_USER');
EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ Cuenta actualizada con método alternativo"
        mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, password, social_id, status FROM account WHERE login='$TEST_USER';" 2>/dev/null
    else
        echo "❌ Error persistente"
        echo "Verificando estructura completa de la tabla..."
        mysql -uroot -pproyectalean -Dmetin2_account -e "DESCRIBE account;" 2>&1
    fi
fi

echo ""

