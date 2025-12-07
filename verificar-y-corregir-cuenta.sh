#!/bin/bash
# Script para verificar y corregir problemas de autenticación
# Uso: bash verificar-y-corregir-cuenta.sh

echo "=========================================="
echo "Verificación y Corrección de Cuenta"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Credenciales de prueba
TEST_USER="test"
TEST_PASSWORD="test123"

# Obtener credenciales MySQL del .env
if [ -f ".env" ]; then
    MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2")
    MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "localhost")
    MYSQL_PORT=$(grep "^MYSQL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "3306")
else
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

export MYSQL_PWD="$MYSQL_PASSWORD"

echo "1. Verificando cuenta '$TEST_USER'..."
echo ""

# Verificar si la cuenta existe
ACCOUNT_INFO=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "SELECT login, password, social_id, status FROM account WHERE login='$TEST_USER';" 2>/dev/null | tail -1)

if [ -z "$ACCOUNT_INFO" ] || [ "$ACCOUNT_INFO" = "login	password	social_id	status" ]; then
    echo -e "   ${RED}❌ La cuenta '$TEST_USER' NO existe${NC}"
    echo ""
    echo "2. Creando cuenta '$TEST_USER'..."
    
    # Crear contraseña SHA1
    PASSWORD_SHA1=$(echo -n "$TEST_PASSWORD" | sha1sum | awk '{print $1}')
    
    # Insertar cuenta
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "INSERT INTO account (login, password, social_id, status) VALUES ('$TEST_USER', '$PASSWORD_SHA1', 'A', 'OK') ON DUPLICATE KEY UPDATE password='$PASSWORD_SHA1', status='OK';" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Cuenta creada/actualizada${NC}"
    else
        echo -e "   ${RED}❌ Error al crear la cuenta${NC}"
        unset MYSQL_PWD
        exit 1
    fi
else
    echo -e "   ${GREEN}✅ La cuenta existe${NC}"
    echo "   Información de la cuenta:"
    echo "$ACCOUNT_INFO" | awk '{print "     Login: " $1 "\n     Password (hash): " $2 "\n     Social ID: " $3 "\n     Status: " $4}'
    
    # Verificar si la contraseña es correcta
    PASSWORD_SHA1=$(echo -n "$TEST_PASSWORD" | sha1sum | awk '{print $1}')
    CURRENT_PASSWORD=$(echo "$ACCOUNT_INFO" | awk '{print $2}')
    
    if [ "$CURRENT_PASSWORD" != "$PASSWORD_SHA1" ]; then
        echo ""
        echo -e "   ${YELLOW}⚠️  La contraseña no coincide${NC}"
        echo "   Actualizando contraseña..."
        
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "UPDATE account SET password='$PASSWORD_SHA1', status='OK' WHERE login='$TEST_USER';" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "   ${GREEN}✅ Contraseña actualizada${NC}"
        else
            echo -e "   ${RED}❌ Error al actualizar la contraseña${NC}"
        fi
    else
        echo -e "   ${GREEN}✅ Contraseña correcta${NC}"
    fi
    
    # Verificar status
    CURRENT_STATUS=$(echo "$ACCOUNT_INFO" | awk '{print $4}')
    if [ "$CURRENT_STATUS" != "OK" ]; then
        echo ""
        echo -e "   ${YELLOW}⚠️  Status de la cuenta: $CURRENT_STATUS (debe ser 'OK')${NC}"
        echo "   Actualizando status..."
        
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "UPDATE account SET status='OK' WHERE login='$TEST_USER';" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "   ${GREEN}✅ Status actualizado a 'OK'${NC}"
        fi
    fi
fi

unset MYSQL_PWD

echo ""
echo "3. Verificando logs del servidor para errores de autenticación..."
echo ""

if docker ps | grep -q "metin2-server"; then
    AUTH_ERRORS=$(docker logs --tail 100 metin2-server 2>&1 | grep -iE "wrongcrd|wrong.*cred|auth.*fail|login.*fail" | tail -5)
    
    if [ -n "$AUTH_ERRORS" ]; then
        echo -e "   ${YELLOW}⚠️  Errores de autenticación encontrados:${NC}"
        echo "$AUTH_ERRORS"
    else
        echo -e "   ${GREEN}✅ No se encontraron errores de autenticación recientes${NC}"
    fi
fi

echo ""
echo "4. Verificando configuración AUTH_SERVER..."
echo ""

if [ -f ".env" ]; then
    AUTH_SERVER=$(grep "^GAME_AUTH_SERVER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    
    if [ "$AUTH_SERVER" = "master" ]; then
        echo -e "   ${GREEN}✅ AUTH_SERVER está en modo 'master' (standalone)${NC}"
        echo "   Esto es correcto para un servidor standalone"
    else
        echo -e "   ${YELLOW}⚠️  AUTH_SERVER: $AUTH_SERVER${NC}"
        echo "   Para servidor standalone debe ser 'master'"
    fi
fi

echo ""
echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
echo "📋 Credenciales de prueba:"
echo "   Usuario: $TEST_USER"
echo "   Contraseña: $TEST_PASSWORD"
echo ""
echo "🔧 Si aún no puedes conectarte:"
echo "   1. Verifica que el servidor esté completamente iniciado (espera 60 segundos)"
echo "   2. Verifica los logs del servidor: docker logs -f metin2-server"
echo "   3. Intenta crear un nuevo personaje si es la primera vez"
echo "   4. Verifica que no haya problemas de red entre tu máquina y el VPS"
echo ""
echo "📝 Nota: El error 'wrongcrd' puede aparecer si:"
echo "   - La cuenta no existe o está bloqueada"
echo "   - La contraseña está mal hasheada"
echo "   - El servidor no está completamente iniciado"
echo "   - Hay un problema con la base de datos"
echo ""

