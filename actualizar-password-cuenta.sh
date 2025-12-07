#!/bin/bash
# Script para actualizar contraseña de una cuenta con Argon2id

echo "=========================================="
echo "Actualización de Contraseña con Argon2id"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

export MYSQL_PWD="proyectalean"
MYSQL_USER="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"

PLAYER_DB="metin2_player"

# Ver cuentas existentes
echo "Cuentas disponibles:"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT 
    id,
    login,
    CASE 
        WHEN passwd LIKE '\$argon2id%' THEN 'Argon2id ✅'
        ELSE 'Otro formato ❌'
    END as formato
FROM account;
" 2>/dev/null

echo ""
read -p "Ingresa el nombre de usuario (login): " USERNAME
read -sp "Ingresa la nueva contraseña: " PASSWORD
echo ""

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo -e "${RED}❌ Usuario y contraseña son requeridos${NC}"
    unset MYSQL_PWD
    exit 1
fi

echo ""
echo -e "${YELLOW}Generando hash Argon2id...${NC}"

# Generar hash Argon2id
ARGON2_HASH=$(python3 <<PYTHON
try:
    from argon2 import PasswordHasher
    ph = PasswordHasher()
    hash = ph.hash('$PASSWORD')
    print(hash)
except ImportError:
    print("")
    import sys
    sys.stderr.write("Error: argon2 no está instalado. Instala con: pip3 install argon2-cffi\n")
except Exception as e:
    print("")
    import sys
    sys.stderr.write(f"Error: {e}\n")
PYTHON
2>&1)

if [ -z "$ARGON2_HASH" ] || [ "${#ARGON2_HASH}" -lt 50 ]; then
    echo -e "${RED}❌ Error al generar hash Argon2id${NC}"
    echo ""
    echo "Instala argon2-cffi:"
    echo "   pip3 install argon2-cffi"
    echo ""
    echo "O usa el método alternativo con el contenedor Docker"
    unset MYSQL_PWD
    exit 1
fi

echo -e "${GREEN}✅ Hash generado${NC}"
echo ""

# Actualizar contraseña
echo -e "${YELLOW}Actualizando contraseña para usuario '$USERNAME'...${NC}"

mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
UPDATE account 
SET passwd = '$ARGON2_HASH', 
    status = 'OK'
WHERE login = '$USERNAME';
" 2>&1

if [ $? -eq 0 ]; then
    AFFECTED=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT ROW_COUNT();" 2>/dev/null || echo "0")
    
    if [ "$AFFECTED" -gt 0 ]; then
        echo -e "${GREEN}✅ Contraseña actualizada exitosamente${NC}"
        echo ""
        echo "Verificación:"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
        SELECT 
            login,
            SUBSTRING(passwd, 1, 30) as passwd_preview,
            CASE 
                WHEN passwd LIKE '\$argon2id%' THEN 'Argon2id ✅'
                ELSE 'Otro formato ❌'
            END as formato,
            status
        FROM account 
        WHERE login = '$USERNAME';
        " 2>/dev/null
    else
        echo -e "${YELLOW}⚠️  No se actualizó ninguna cuenta${NC}"
        echo "   Verifica que el usuario '$USERNAME' existe"
    fi
else
    echo -e "${RED}❌ Error al actualizar contraseña${NC}"
fi

echo ""
unset MYSQL_PWD

