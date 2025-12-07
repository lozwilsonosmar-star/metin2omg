#!/bin/bash
# Script mejorado para crear cuenta manualmente con diagnóstico
# Uso: bash crear-cuenta-manual.sh

echo "=========================================="
echo "Creación Manual de Cuenta con Diagnóstico"
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

echo "1. Verificando conexión a MySQL..."
echo "   Host: $MYSQL_HOST"
echo "   Port: $MYSQL_PORT"
echo "   User: $MYSQL_USER"
echo ""

export MYSQL_PWD="$MYSQL_PASSWORD"

# Verificar conexión
if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SELECT 1;" 2>/dev/null; then
    echo -e "   ${GREEN}✅ Conexión a MySQL exitosa${NC}"
else
    echo -e "   ${RED}❌ Error al conectar a MySQL${NC}"
    echo "   Intentando con contraseña interactiva..."
    unset MYSQL_PWD
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" 2>&1
    if [ $? -eq 0 ]; then
        export MYSQL_PWD="$MYSQL_PASSWORD"
        echo -e "   ${GREEN}✅ Conexión exitosa con contraseña interactiva${NC}"
    else
        echo -e "   ${RED}❌ No se pudo conectar a MySQL${NC}"
        unset MYSQL_PWD
        exit 1
    fi
fi
echo ""

echo "2. Verificando que la base de datos metin2_account existe..."
if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "USE metin2_account; SELECT 1;" 2>/dev/null; then
    echo -e "   ${GREEN}✅ Base de datos metin2_account existe${NC}"
else
    echo -e "   ${RED}❌ Base de datos metin2_account NO existe${NC}"
    echo "   Creando base de datos..."
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_account;" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Base de datos creada${NC}"
    else
        echo -e "   ${RED}❌ Error al crear la base de datos${NC}"
        unset MYSQL_PWD
        exit 1
    fi
fi
echo ""

echo "3. Verificando estructura de la tabla account..."
TABLE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "account" || echo "0")

if [ "$TABLE_EXISTS" -eq 0 ]; then
    echo -e "   ${RED}❌ La tabla 'account' NO existe${NC}"
    echo "   Necesitas ejecutar el script de creación de tablas primero"
    echo "   Ejecuta: bash docker/create-all-tables.sql o importa las tablas"
    unset MYSQL_PWD
    exit 1
else
    echo -e "   ${GREEN}✅ La tabla 'account' existe${NC}"
    
    # Mostrar estructura de la tabla
    echo "   Estructura de la tabla:"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "DESCRIBE account;" 2>/dev/null | head -10
fi
echo ""

echo "4. Verificando si la cuenta '$TEST_USER' existe..."
ACCOUNT_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "SELECT COUNT(*) FROM account WHERE login='$TEST_USER';" 2>/dev/null | tail -1 || echo "0")

if [ "$ACCOUNT_EXISTS" -gt 0 ]; then
    echo -e "   ${YELLOW}⚠️  La cuenta '$TEST_USER' ya existe${NC}"
    echo "   Información actual:"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "SELECT login, password, social_id, status FROM account WHERE login='$TEST_USER';" 2>/dev/null
    
    echo ""
    echo "   ¿Deseas eliminar y recrear la cuenta? (s/N): "
    read -r respuesta
    if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
        echo "   Eliminando cuenta existente..."
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "DELETE FROM account WHERE login='$TEST_USER';" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "   ${GREEN}✅ Cuenta eliminada${NC}"
        else
            echo -e "   ${RED}❌ Error al eliminar la cuenta${NC}"
            unset MYSQL_PWD
            exit 1
        fi
    else
        echo "   Actualizando contraseña de la cuenta existente..."
        PASSWORD_SHA1=$(echo -n "$TEST_PASSWORD" | sha1sum | awk '{print $1}')
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "UPDATE account SET password='$PASSWORD_SHA1', status='OK' WHERE login='$TEST_USER';" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "   ${GREEN}✅ Contraseña actualizada${NC}"
        else
            echo -e "   ${RED}❌ Error al actualizar la contraseña${NC}"
            echo "   Intentando método alternativo..."
        fi
        unset MYSQL_PWD
        exit 0
    fi
else
    echo -e "   ${GREEN}✅ La cuenta no existe, procediendo a crearla${NC}"
fi
echo ""

echo "5. Creando cuenta '$TEST_USER'..."
echo "   Usuario: $TEST_USER"
echo "   Contraseña: $TEST_PASSWORD"

# Crear contraseña SHA1
PASSWORD_SHA1=$(echo -n "$TEST_PASSWORD" | sha1sum | awk '{print $1}')
echo "   Password SHA1: $PASSWORD_SHA1"
echo ""

# Intentar INSERT con diferentes métodos
echo "   Intentando método 1: INSERT estándar..."
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "INSERT INTO account (login, password, social_id, status) VALUES ('$TEST_USER', '$PASSWORD_SHA1', 'A', 'OK');" 2>&1

if [ $? -eq 0 ]; then
    echo -e "   ${GREEN}✅ Cuenta creada exitosamente${NC}"
else
    echo -e "   ${YELLOW}⚠️  Método 1 falló, intentando método 2: INSERT IGNORE${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "INSERT IGNORE INTO account (login, password, social_id, status) VALUES ('$TEST_USER', '$PASSWORD_SHA1', 'A', 'OK');" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Cuenta creada con INSERT IGNORE${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Método 2 falló, intentando método 3: REPLACE${NC}"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "REPLACE INTO account (login, password, social_id, status) VALUES ('$TEST_USER', '$PASSWORD_SHA1', 'A', 'OK');" 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "   ${GREEN}✅ Cuenta creada con REPLACE${NC}"
        else
            echo -e "   ${RED}❌ Todos los métodos fallaron${NC}"
            echo ""
            echo "   Verificando estructura de la tabla para diagnóstico..."
            mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "DESCRIBE account;" 2>&1
            unset MYSQL_PWD
            exit 1
        fi
    fi
fi
echo ""

echo "6. Verificando que la cuenta se creó correctamente..."
ACCOUNT_INFO=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "SELECT login, password, social_id, status FROM account WHERE login='$TEST_USER';" 2>/dev/null | tail -1)

if [ -n "$ACCOUNT_INFO" ] && [ "$ACCOUNT_INFO" != "login	password	social_id	status" ]; then
    echo -e "   ${GREEN}✅ Cuenta verificada${NC}"
    echo "   Información de la cuenta:"
    echo "$ACCOUNT_INFO" | awk '{print "     Login: " $1 "\n     Password (hash): " $2 "\n     Social ID: " $3 "\n     Status: " $4}'
else
    echo -e "   ${RED}❌ La cuenta no se encontró después de crearla${NC}"
    unset MYSQL_PWD
    exit 1
fi

unset MYSQL_PWD

echo ""
echo "=========================================="
echo "✅ CUENTA CREADA EXITOSAMENTE"
echo "=========================================="
echo ""
echo "📋 Credenciales:"
echo "   Usuario: $TEST_USER"
echo "   Contraseña: $TEST_PASSWORD"
echo ""
echo "🎮 Ahora puedes intentar conectarte desde el cliente"
echo ""

