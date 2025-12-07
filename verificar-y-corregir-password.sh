#!/bin/bash
# Script para verificar y corregir contraseñas de cuentas

echo "=========================================="
echo "Verificación y Corrección de Contraseñas"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

export MYSQL_PWD="proyectalean"
MYSQL_USER="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"

PLAYER_DB="metin2_player"

echo -e "${BLUE}Verificando cuentas y contraseñas...${NC}"
echo ""

# Ver estructura de la tabla account
echo "Estructura de la tabla 'account':"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "DESCRIBE account;" 2>/dev/null
echo ""

# Ver cuentas existentes (sin mostrar contraseñas completas)
echo "Cuentas existentes:"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
SELECT 
    id,
    login,
    SUBSTRING(passwd, 1, 20) as passwd_preview,
    LENGTH(passwd) as passwd_length,
    status
FROM account;
" 2>/dev/null
echo ""

# Verificar si las contraseñas están en formato Argon2id
echo -e "${YELLOW}Verificando formato de contraseñas...${NC}"
ARGON2_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "
SELECT COUNT(*) 
FROM account 
WHERE passwd LIKE '\$argon2id%';
" 2>/dev/null || echo "0")

TOTAL_ACCOUNTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")

echo "Cuentas con formato Argon2id: $ARGON2_COUNT de $TOTAL_ACCOUNTS"
echo ""

if [ "$ARGON2_COUNT" -lt "$TOTAL_ACCOUNTS" ]; then
    echo -e "${YELLOW}⚠️  Algunas cuentas NO tienen contraseñas en formato Argon2id${NC}"
    echo ""
    echo "El servidor usa Argon2id para verificar contraseñas."
    echo "Si las contraseñas no están en este formato, el login fallará."
    echo ""
    read -p "¿Quieres ver qué cuentas necesitan corrección? (S/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[SsYy]$ ]] || [[ -z "$REPLY" ]]; then
        echo ""
        echo "Cuentas que NO tienen formato Argon2id:"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
        SELECT 
            id,
            login,
            SUBSTRING(passwd, 1, 30) as passwd_preview,
            CASE 
                WHEN passwd LIKE '\$argon2id%' THEN 'Argon2id'
                WHEN passwd LIKE '\$2a\$%' THEN 'bcrypt'
                WHEN passwd LIKE '*%' THEN 'MySQL hash'
                ELSE 'Desconocido'
            END as formato
        FROM account;
        " 2>/dev/null
        echo ""
        
        echo -e "${YELLOW}Para corregir las contraseñas, necesitas:${NC}"
        echo "   1. Saber la contraseña en texto plano"
        echo "   2. Generar el hash Argon2id"
        echo ""
        echo "Puedes usar el script: actualizar-cuenta-argon2-final.sh"
        echo "O generar el hash manualmente con: generar-hash-argon2.sh"
    fi
else
    echo -e "${GREEN}✅ Todas las cuentas tienen formato Argon2id${NC}"
    echo ""
    echo "Si aún recibes 'wrongcrd', verifica:"
    echo "   1. Que la contraseña en el cliente sea la correcta"
    echo "   2. Que el hash en la base de datos sea válido"
    echo "   3. Los logs del servidor para más detalles"
fi

echo ""
echo -e "${BLUE}Para ver logs de autenticación en tiempo real:${NC}"
echo "   docker logs -f metin2-server | grep -E 'AuthLogin|WRONGCRD|login'"
echo ""

unset MYSQL_PWD

