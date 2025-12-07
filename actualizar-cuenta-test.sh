#!/bin/bash
# Script para actualizar la cuenta test con el hash de contraseña correcto
# Uso: bash actualizar-cuenta-test.sh

echo "=========================================="
echo "Actualización de Cuenta Test"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Credenciales
TEST_USER="test"
# Hash SHA1 de la contraseña (sin el asterisco inicial)
PASSWORD_HASH="CC67043C7BCFF5EEA5566BD9B1F3C74FD9A5CF5D"

# Usar root ya que metin2 no tiene permisos
MYSQL_USER="root"
MYSQL_PASSWORD="proyectalean"
MYSQL_HOST="localhost"
MYSQL_PORT="3306"

echo "1. Verificando conexión a MySQL como root..."
if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -Dmetin2_account -e "SELECT 1;" 2>/dev/null; then
    echo -e "   ${GREEN}✅ Conexión exitosa${NC}"
else
    echo -e "   ${RED}❌ Error al conectar a MySQL${NC}"
    exit 1
fi
echo ""

echo "2. Verificando cuenta '$TEST_USER'..."
ACCOUNT_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "SELECT COUNT(*) FROM account WHERE login='$TEST_USER';" 2>/dev/null | tail -1 || echo "0")

if [ "$ACCOUNT_EXISTS" -gt 0 ]; then
    echo -e "   ${GREEN}✅ La cuenta existe${NC}"
    echo "   Información actual:"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -Dmetin2_account -e "SELECT login, password, social_id, status FROM account WHERE login='$TEST_USER';" 2>/dev/null
    echo ""
    echo "   Actualizando contraseña y status..."
else
    echo -e "   ${YELLOW}⚠️  La cuenta no existe, creándola...${NC}"
fi

echo ""
echo "3. Actualizando/Creando cuenta con hash correcto..."
echo "   Usuario: $TEST_USER"
echo "   Password Hash: $PASSWORD_HASH"
echo ""

# Actualizar o crear la cuenta
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -Dmetin2_account -e "INSERT INTO account (login, password, social_id, status) VALUES ('$TEST_USER', '$PASSWORD_HASH', 'A', 'OK') ON DUPLICATE KEY UPDATE password='$PASSWORD_HASH', status='OK';" 2>&1

if [ $? -eq 0 ]; then
    echo -e "   ${GREEN}✅ Cuenta actualizada/creada exitosamente${NC}"
else
    echo -e "   ${RED}❌ Error al actualizar la cuenta${NC}"
    echo "   Intentando con REPLACE..."
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -Dmetin2_account -e "REPLACE INTO account (login, password, social_id, status) VALUES ('$TEST_USER', '$PASSWORD_HASH', 'A', 'OK');" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Cuenta actualizada con REPLACE${NC}"
    else
        echo -e "   ${RED}❌ Error persistente${NC}"
        echo "   Verificando estructura de la tabla..."
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -Dmetin2_account -e "DESCRIBE account;" 2>&1
        exit 1
    fi
fi
echo ""

echo "4. Verificando que la cuenta se actualizó correctamente..."
ACCOUNT_INFO=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -Dmetin2_account -e "SELECT login, password, social_id, status FROM account WHERE login='$TEST_USER';" 2>/dev/null | tail -1)

if [ -n "$ACCOUNT_INFO" ] && [ "$ACCOUNT_INFO" != "login	password	social_id	status" ]; then
    echo -e "   ${GREEN}✅ Cuenta verificada${NC}"
    echo "   Información de la cuenta:"
    echo "$ACCOUNT_INFO" | awk '{print "     Login: " $1 "\n     Password (hash): " $2 "\n     Social ID: " $3 "\n     Status: " $4}'
    
    # Verificar que el hash coincide
    CURRENT_HASH=$(echo "$ACCOUNT_INFO" | awk '{print $2}')
    if [ "$CURRENT_HASH" = "$PASSWORD_HASH" ]; then
        echo -e "   ${GREEN}✅ Hash de contraseña correcto${NC}"
    else
        echo -e "   ${YELLOW}⚠️  El hash no coincide exactamente (puede tener formato diferente)${NC}"
        echo "   Hash esperado: $PASSWORD_HASH"
        echo "   Hash actual: $CURRENT_HASH"
    fi
    
    # Verificar status
    CURRENT_STATUS=$(echo "$ACCOUNT_INFO" | awk '{print $4}')
    if [ "$CURRENT_STATUS" = "OK" ]; then
        echo -e "   ${GREEN}✅ Status correcto: OK${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Status: $CURRENT_STATUS (debe ser 'OK')${NC}"
        echo "   Actualizando status..."
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -Dmetin2_account -e "UPDATE account SET status='OK' WHERE login='$TEST_USER';" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "   ${GREEN}✅ Status actualizado${NC}"
        fi
    fi
else
    echo -e "   ${RED}❌ No se pudo verificar la cuenta${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ CUENTA ACTUALIZADA"
echo "=========================================="
echo ""
echo "📋 Credenciales:"
echo "   Usuario: $TEST_USER"
echo "   Password Hash: $PASSWORD_HASH"
echo ""
echo "🎮 Ahora intenta conectarte desde el cliente"
echo "   Si aún no funciona, verifica qué contraseña corresponde a ese hash"
echo ""

