#!/bin/bash
# Script para mover la tabla account de metin2_account a metin2_player
# El servidor busca account en PLAYER_SQL (metin2_player)

echo "=========================================="
echo "Moviendo tabla account a metin2_player"
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

SOURCE_DB="metin2_account"
TARGET_DB="metin2_player"
TABLE="account"

echo -e "${YELLOW}⚠️  Este script moverá la tabla 'account' de $SOURCE_DB a $TARGET_DB${NC}"
echo -e "${YELLOW}   El servidor busca 'account' en $TARGET_DB (PLAYER_SQL)${NC}"
echo ""
read -p "¿Continuar? (S/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[SsYy]$ ]] && [[ -n "$REPLY" ]]; then
    echo "Operación cancelada"
    unset MYSQL_PWD
    exit 0
fi

echo ""

# 1. Verificar que account existe en SOURCE_DB
echo -e "${YELLOW}1. Verificando tabla 'account' en $SOURCE_DB...${NC}"
ACCOUNT_IN_SOURCE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$SOURCE_DB" -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "^account$" || echo "0")

if [ "$ACCOUNT_IN_SOURCE" -eq 0 ]; then
    echo -e "${RED}❌ Tabla 'account' NO existe en $SOURCE_DB${NC}"
    unset MYSQL_PWD
    exit 1
fi

COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$SOURCE_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
echo -e "${GREEN}✅ Tabla 'account' encontrada en $SOURCE_DB ($COUNT registros)${NC}"
echo ""

# 2. Verificar si account ya existe en TARGET_DB
echo -e "${YELLOW}2. Verificando si 'account' ya existe en $TARGET_DB...${NC}"
ACCOUNT_IN_TARGET=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "^account$" || echo "0")

if [ "$ACCOUNT_IN_TARGET" -gt 0 ]; then
    TARGET_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
    echo -e "${YELLOW}⚠️  Tabla 'account' ya existe en $TARGET_DB ($TARGET_COUNT registros)${NC}"
    echo ""
    read -p "¿Sobrescribir? (S/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[SsYy]$ ]] && [[ -n "$REPLY" ]]; then
        echo "Operación cancelada"
        unset MYSQL_PWD
        exit 0
    fi
    
    echo -e "${YELLOW}   Eliminando tabla existente...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -e "DROP TABLE IF EXISTS account;" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Tabla eliminada${NC}"
    else
        echo -e "${RED}❌ Error al eliminar tabla${NC}"
        unset MYSQL_PWD
        exit 1
    fi
else
    echo -e "${GREEN}✅ Tabla 'account' no existe en $TARGET_DB (procediendo)${NC}"
fi

echo ""

# 3. Crear tabla en TARGET_DB
echo -e "${YELLOW}3. Creando tabla 'account' en $TARGET_DB...${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -e "
    CREATE TABLE account LIKE $SOURCE_DB.account;
" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Tabla creada${NC}"
else
    echo -e "${RED}❌ Error al crear tabla${NC}"
    unset MYSQL_PWD
    exit 1
fi

echo ""

# 4. Copiar datos
echo -e "${YELLOW}4. Copiando datos de $SOURCE_DB a $TARGET_DB...${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -e "
    INSERT INTO account SELECT * FROM $SOURCE_DB.account;
" 2>&1

if [ $? -eq 0 ]; then
    NEW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ Datos copiados ($NEW_COUNT registros)${NC}"
else
    echo -e "${RED}❌ Error al copiar datos${NC}"
    unset MYSQL_PWD
    exit 1
fi

echo ""

# 5. Verificación final
echo -e "${YELLOW}5. Verificación final...${NC}"
FINAL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")

if [ "$FINAL_COUNT" -eq "$COUNT" ]; then
    echo -e "${GREEN}✅ Verificación exitosa: $FINAL_COUNT registros en $TARGET_DB${NC}"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ OPERACIÓN COMPLETADA${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo "La tabla 'account' ahora está en $TARGET_DB donde el servidor la busca."
    echo ""
    echo "Próximos pasos:"
    echo "   1. Reinicia el contenedor: docker restart metin2-server"
    echo "   2. Espera 30 segundos"
    echo "   3. Verifica logs: docker logs --tail 50 metin2-server | grep -E 'TCP listening|MasterAuth|account'"
    echo ""
else
    echo -e "${YELLOW}⚠️  Advertencia: Conteo de registros no coincide${NC}"
    echo "   Original: $COUNT"
    echo "   Nuevo: $FINAL_COUNT"
fi

unset MYSQL_PWD

