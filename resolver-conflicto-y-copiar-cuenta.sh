#!/bin/bash
# Script para resolver conflicto git y copiar cuenta
# Uso: bash resolver-conflicto-y-copiar-cuenta.sh

echo "=========================================="
echo "Resolver Conflicto y Copiar Cuenta"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Resolviendo conflicto git..."
echo ""

# Guardar cambios locales si existen
if [ -f "crear-account-en-player.sh" ]; then
    echo "   Guardando cambios locales..."
    cp crear-account-en-player.sh crear-account-en-player.sh.backup
fi

# Descartar cambios locales y hacer pull
git checkout -- crear-account-en-player.sh 2>/dev/null
git pull origin main

echo ""
echo "2. Copiando cuenta a metin2_player..."
echo ""

# Obtener los datos de la cuenta
ACCOUNT_DATA=$(mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, password, social_id, status FROM account WHERE login='test';" 2>/dev/null | tail -1)

if [ -z "$ACCOUNT_DATA" ]; then
    echo "   ❌ No se encontró la cuenta 'test' en metin2_account"
    exit 1
fi

LOGIN=$(echo "$ACCOUNT_DATA" | awk '{print $1}')
PASSWORD=$(echo "$ACCOUNT_DATA" | awk '{print $2}')
SOCIAL_ID=$(echo "$ACCOUNT_DATA" | awk '{print $3}')
STATUS=$(echo "$ACCOUNT_DATA" | awk '{print $4}')

echo "   Login: $LOGIN"
echo "   Password (primeros 60 chars): ${PASSWORD:0:60}..."
echo "   Social ID: $SOCIAL_ID"
echo "   Status: $STATUS"
echo ""

echo "3. Insertando/actualizando cuenta en metin2_player..."
echo ""

# Insertar con valores válidos para fechas
mysql -uroot -pproyectalean -Dmetin2_player <<EOF
SET SESSION sql_mode = '';
INSERT INTO account (login, password, social_id, status, last_play, create_time)
VALUES ('$LOGIN', '$PASSWORD', '$SOCIAL_ID', '$STATUS', NOW(), NOW())
ON DUPLICATE KEY UPDATE 
    password='$PASSWORD',
    status='$STATUS',
    last_play=NOW();
EOF

if [ $? -eq 0 ]; then
    echo "   ✅ Cuenta copiada exitosamente"
    echo ""
    echo "4. Verificando cuenta en metin2_player..."
    mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT login, LEFT(password, 60) as password_preview, status, last_play FROM account WHERE login='test';" 2>/dev/null
    echo ""
    echo "=========================================="
    echo "✅ Cuenta copiada correctamente"
    echo "=========================================="
    echo ""
    echo "Ahora intenta conectarte desde el cliente con:"
    echo "   Usuario: test"
    echo "   Contraseña: metin2test123"
    echo ""
else
    echo "   ❌ Error al copiar la cuenta"
fi

echo ""

