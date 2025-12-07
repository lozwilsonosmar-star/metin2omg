#!/bin/bash
# Script seguro para corregir columna password con backup

echo "=========================================="
echo "Corrección Segura de Columna Password"
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

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}ANÁLISIS DE RIESGO${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

echo "Operación: ALTER TABLE account MODIFY COLUMN password VARCHAR(255)"
echo ""
echo -e "${YELLOW}RIESGOS:${NC}"
echo "  1. ⚠️  Si falla, la columna podría quedar en estado inconsistente"
echo "  2. ⚠️  Si hay datos, podrían perderse (pero solo si el tipo es incompatible)"
echo "  3. ✅ En este caso es SEGURO porque solo aumentamos el tamaño (VARCHAR(45) → VARCHAR(255))"
echo ""
echo -e "${GREEN}ES SEGURO porque:${NC}"
echo "  - Solo estamos AUMENTANDO el tamaño (no reduciendo)"
echo "  - Los datos existentes caben en el nuevo tamaño"
echo "  - No cambiamos el tipo de dato (sigue siendo VARCHAR)"
echo "  - MySQL puede hacer esto sin perder datos"
echo ""

read -p "¿Continuar con backup de seguridad? (S/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[SsYy]$ ]] && [[ -n "$REPLY" ]]; then
    echo "Operación cancelada"
    unset MYSQL_PWD
    exit 0
fi

echo ""

# Paso 1: Crear backup
echo -e "${YELLOW}1. Creando backup de seguridad...${NC}"
mysqldump -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" "$PLAYER_DB" account > "$BACKUP_FILE" 2>&1

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✅ Backup creado: $BACKUP_FILE ($BACKUP_SIZE)${NC}"
else
    echo -e "${RED}❌ Error al crear backup${NC}"
    echo "¿Continuar sin backup? (no recomendado)"
    read -p "Continuar? (s/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Operación cancelada"
        unset MYSQL_PWD
        exit 1
    fi
fi

echo ""

# Paso 2: Verificar estado actual
echo -e "${YELLOW}2. Verificando estado actual...${NC}"
CURRENT_TYPE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null | awk '{print $2}')

echo "Tipo actual: $CURRENT_TYPE"
ACCOUNT_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
echo "Cuentas existentes: $ACCOUNT_COUNT"
echo ""

# Paso 3: Modificar columna
echo -e "${YELLOW}3. Modificando columna password...${NC}"

mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "
    ALTER TABLE account 
    MODIFY COLUMN password VARCHAR(255) NOT NULL;
" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Columna password modificada exitosamente${NC}"
    
    # Verificar que los datos siguen ahí
    NEW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
    
    if [ "$NEW_COUNT" -eq "$ACCOUNT_COUNT" ]; then
        echo -e "${GREEN}✅ Verificación: Todas las cuentas siguen intactas ($NEW_COUNT)${NC}"
    else
        echo -e "${RED}❌ ERROR: Se perdieron cuentas (tenías $ACCOUNT_COUNT, ahora hay $NEW_COUNT)${NC}"
        echo ""
        echo "Restaurando desde backup..."
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" "$PLAYER_DB" < "$BACKUP_FILE" 2>&1
        echo "Backup restaurado"
        unset MYSQL_PWD
        exit 1
    fi
    
    # Verificar nuevo tipo
    NEW_TYPE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null | awk '{print $2}')
    echo "Nuevo tipo: $NEW_TYPE"
else
    echo -e "${RED}❌ Error al modificar columna${NC}"
    echo ""
    echo "Si algo salió mal, puedes restaurar desde:"
    echo "   mysql -uroot -Dmetin2_player < $BACKUP_FILE"
    unset MYSQL_PWD
    exit 1
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ OPERACIÓN COMPLETADA CON ÉXITO${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo "Backup guardado en: $BACKUP_FILE"
echo ""
echo "Ahora puedes actualizar las contraseñas a Argon2id."
echo ""

unset MYSQL_PWD

