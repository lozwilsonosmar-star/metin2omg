#!/bin/bash
# Script para corregir tamaño de columna password y actualizar contraseñas

echo "=========================================="
echo "Corrección de Columna Password y Actualización"
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

echo -e "${YELLOW}1. Verificando tamaño actual de columna password...${NC}"
CURRENT_TYPE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null | awk '{print $2}')

echo "Tipo actual: $CURRENT_TYPE"
echo ""

# Verificar si necesita corrección
if [[ "$CURRENT_TYPE" == *"varchar(45)"* ]] || [[ "$CURRENT_TYPE" == *"varchar(40)"* ]]; then
    echo -e "${YELLOW}2. Corrigiendo tamaño de columna password a VARCHAR(255)...${NC}"
    
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
        ALTER TABLE account 
        MODIFY COLUMN password VARCHAR(255) NOT NULL;
    " 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Columna password corregida${NC}"
    else
        echo -e "${RED}❌ Error al corregir columna${NC}"
        unset MYSQL_PWD
        exit 1
    fi
else
    echo -e "${GREEN}✅ Columna password ya tiene tamaño suficiente${NC}"
fi

echo ""

# Ver formato actual
echo -e "${YELLOW}3. Formato actual de contraseñas:${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT 
    id,
    login,
    SUBSTRING(password, 1, 40) as password_preview,
    CASE 
        WHEN password LIKE '\$argon2id%' THEN 'Argon2id ✅'
        WHEN password LIKE '*%' THEN 'MySQL hash ❌'
        ELSE 'Otro formato ❌'
    END as formato
FROM account;
" 2>/dev/null

echo ""

# Actualizar contraseña para 'test'
echo -e "${YELLOW}4. Actualizando contraseña para cuenta 'test'...${NC}"
read -sp "Nueva contraseña para 'test': " NEW_PASSWORD
echo ""

if [ -z "$NEW_PASSWORD" ]; then
    echo -e "${RED}❌ Contraseña no puede estar vacía${NC}"
    unset MYSQL_PWD
    exit 1
fi

# Verificar si argon2 está instalado
if ! python3 -c "import argon2" 2>/dev/null; then
    echo -e "${YELLOW}Instalando argon2-cffi...${NC}"
    pip3 install argon2-cffi --quiet 2>&1 || {
        echo -e "${RED}❌ Error al instalar argon2-cffi${NC}"
        echo "Instala manualmente: pip3 install argon2-cffi"
        unset MYSQL_PWD
        exit 1
    }
fi

# Generar hash
echo -e "${YELLOW}Generando hash Argon2id...${NC}"
ARGON2_HASH=$(python3 <<PYTHON
from argon2 import PasswordHasher
ph = PasswordHasher()
hash = ph.hash('$NEW_PASSWORD')
print(hash)
PYTHON
2>&1)

if [ -z "$ARGON2_HASH" ] || [ "${#ARGON2_HASH}" -lt 50 ]; then
    echo -e "${RED}❌ Error al generar hash${NC}"
    unset MYSQL_PWD
    exit 1
fi

echo -e "${GREEN}✅ Hash generado (${#ARGON2_HASH} caracteres)${NC}"
echo ""

# Actualizar contraseña
echo -e "${YELLOW}Actualizando contraseña...${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
UPDATE account 
SET password = '$ARGON2_HASH',
    status = 'OK'
WHERE login = 'test';
" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Contraseña actualizada${NC}"
    echo ""
    echo "Verificación:"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
    SELECT 
        login,
        SUBSTRING(password, 1, 30) as password_preview,
        CASE 
            WHEN password LIKE '\$argon2id%' THEN 'Argon2id ✅'
            ELSE 'Otro formato ❌'
        END as formato,
        status
    FROM account 
    WHERE login = 'test';
    " 2>/dev/null
else
    echo -e "${RED}❌ Error al actualizar contraseña${NC}"
fi

echo ""
unset MYSQL_PWD

