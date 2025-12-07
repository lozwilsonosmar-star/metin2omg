#!/bin/bash
# Script para reiniciar el servidor después de crear tabla account
# Uso: bash reiniciar-servidor-para-account.sh

echo "=========================================="
echo "Reiniciar Servidor para Reconocer Tabla Account"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Verificando que la tabla account existe en metin2_player..."
echo ""

ACCOUNT_EXISTS=$(mysql -uroot -pproyectalean -Dmetin2_player -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c account)

if [ "$ACCOUNT_EXISTS" -eq 0 ]; then
    echo "   ❌ La tabla account NO existe en metin2_player"
    echo "   Ejecuta primero: bash crear-account-en-player.sh"
    exit 1
fi

echo "   ✅ La tabla account existe"
echo ""

echo "2. Verificando que hay una cuenta 'test'..."
echo ""

TEST_ACCOUNT=$(mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT COUNT(*) FROM account WHERE login='test';" 2>/dev/null | tail -1 | awk '{print $1}')

if [ "$TEST_ACCOUNT" -eq 0 ]; then
    echo "   ⚠️  No hay cuenta 'test' en metin2_player"
    echo "   Copiando cuenta..."
    
    PASSWORD=$(mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT password FROM account WHERE login='test';" 2>/dev/null | tail -1 | awk '{print $1}')
    
    mysql -uroot -pproyectalean -Dmetin2_player <<EOF
SET SESSION sql_mode = '';
INSERT INTO account (login, password, social_id, status, last_play, create_time)
VALUES ('test', '$PASSWORD', 'A', 'OK', NOW(), NOW())
ON DUPLICATE KEY UPDATE 
    password='$PASSWORD',
    status='OK',
    last_play=NOW();
EOF
    
    echo "   ✅ Cuenta copiada"
else
    echo "   ✅ La cuenta 'test' existe"
fi

echo ""
echo "3. Reiniciando contenedor para que el servidor reconozca la tabla..."
echo ""

if docker ps | grep -q "metin2-server"; then
    echo "   Reiniciando contenedor..."
    docker restart metin2-server
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Contenedor reiniciado"
        echo ""
        echo "4. Esperando 30 segundos para que el servidor inicie..."
        sleep 30
        echo ""
        echo "5. Verificando que el servidor está corriendo..."
        
        if docker ps | grep -q "metin2-server"; then
            echo "   ✅ Contenedor está corriendo"
            echo ""
            echo "6. Verificando logs del servidor..."
            echo ""
            docker logs --tail 20 metin2-server | grep -iE "connected|listening|error" | tail -10
            echo ""
            echo "=========================================="
            echo "✅ Servidor reiniciado"
            echo "=========================================="
            echo ""
            echo "Ahora intenta conectarte nuevamente desde el cliente:"
            echo "   Usuario: test"
            echo "   Contraseña: metin2test123"
            echo ""
        else
            echo "   ❌ El contenedor no está corriendo"
        fi
    else
        echo "   ❌ Error al reiniciar el contenedor"
    fi
else
    echo "   ⚠️  El contenedor no está corriendo"
    echo "   Iniciando contenedor..."
    docker start metin2-server
    sleep 30
fi

echo ""

