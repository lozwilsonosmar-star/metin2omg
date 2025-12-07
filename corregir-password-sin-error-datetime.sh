#!/bin/bash
# Script para corregir columna password deshabilitando modo estricto temporalmente

echo "=========================================="
echo "Corrección de Columna Password (sin errores datetime)"
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
BACKUP_FILE="/tmp/account_backup_$(date +%Y%m%d_%H%M%S).sql"

echo -e "${YELLOW}1. Creando backup...${NC}"
mysqldump -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" "$PLAYER_DB" account > "$BACKUP_FILE" 2>&1

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✅ Backup creado: $BACKUP_FILE ($BACKUP_SIZE)${NC}"
else
    echo -e "${RED}❌ Error al crear backup${NC}"
    unset MYSQL_PWD
    exit 1
fi

echo ""

echo -e "${YELLOW}2. Verificando estado actual...${NC}"
CURRENT_TYPE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null | awk '{print $2}')
ACCOUNT_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")

echo "Tipo actual: $CURRENT_TYPE"
echo "Cuentas existentes: $ACCOUNT_COUNT"
echo ""

echo -e "${YELLOW}3. Modificando columna password (deshabilitando modo estricto)...${NC}"

# Deshabilitar modo estricto temporalmente
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
    SET SESSION sql_mode = '';
    ALTER TABLE account 
    MODIFY COLUMN password VARCHAR(255) NOT NULL;
" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Columna password modificada exitosamente${NC}"
    
    # Verificar que los datos siguen ahí
    NEW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
    
    if [ "$NEW_COUNT" -eq "$ACCOUNT_COUNT" ]; then
        echo -e "${GREEN}✅ Verificación: Todas las cuentas siguen intactas ($NEW_COUNT)${NC}"
        
        # Verificar nuevo tipo
        NEW_TYPE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null | awk '{print $2}')
        echo "Nuevo tipo: $NEW_TYPE"
        
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════${NC}"
        echo -e "${GREEN}✅ OPERACIÓN COMPLETADA${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════${NC}"
        echo ""
        echo "Ahora puedes actualizar las contraseñas a Argon2id."
        echo "Ejecuta: bash corregir-columna-password-y-actualizar.sh"
    else
        echo -e "${RED}❌ ERROR: Se perdieron cuentas${NC}"
        echo "Restaurando desde backup..."
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" "$PLAYER_DB" < "$BACKUP_FILE" 2>&1
        echo "Backup restaurado"
        unset MYSQL_PWD
        exit 1
    fi
else
    echo -e "${RED}❌ Error al modificar columna${NC}"
    echo ""
    echo "Si algo salió mal, restaura desde:"
    echo "   mysql -uroot -Dmetin2_player < $BACKUP_FILE"
    unset MYSQL_PWD
    exit 1
fi

echo ""
unset MYSQL_PWD

