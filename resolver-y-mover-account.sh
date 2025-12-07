#!/bin/bash
# Script que resuelve conflicto git y mueve account a metin2_player

echo "=========================================="
echo "Resolviendo Conflicto y Moviendo account"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio${NC}"
    exit 1
}

# 1. Resolver conflicto
echo -e "${YELLOW}1. Resolviendo conflicto de git...${NC}"
git stash
git pull origin main
echo -e "${GREEN}✅ Git actualizado${NC}"
echo ""

# 2. Hacer script ejecutable
echo -e "${YELLOW}2. Preparando script...${NC}"
chmod +x mover-account-a-player.sh 2>/dev/null || true

if [ ! -f "mover-account-a-player.sh" ]; then
    echo -e "${YELLOW}⚠️  Script no encontrado, ejecutando movimiento manual...${NC}"
    echo ""
    
    export MYSQL_PWD="proyectalean"
    MYSQL_USER="root"
    MYSQL_HOST="127.0.0.1"
    MYSQL_PORT="3306"
    
    SOURCE_DB="metin2_account"
    TARGET_DB="metin2_player"
    
    echo -e "${YELLOW}⚠️  Moviendo tabla 'account' de $SOURCE_DB a $TARGET_DB${NC}"
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
    
    # Verificar que account existe en SOURCE_DB
    echo -e "${YELLOW}Verificando tabla 'account' en $SOURCE_DB...${NC}"
    ACCOUNT_IN_SOURCE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$SOURCE_DB" -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "^account$" || echo "0")
    
    if [ "$ACCOUNT_IN_SOURCE" -eq 0 ]; then
        echo -e "${RED}❌ Tabla 'account' NO existe en $SOURCE_DB${NC}"
        unset MYSQL_PWD
        exit 1
    fi
    
    COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$SOURCE_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ Tabla 'account' encontrada ($COUNT registros)${NC}"
    echo ""
    
    # Verificar si account ya existe en TARGET_DB
    ACCOUNT_IN_TARGET=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "^account$" || echo "0")
    
    if [ "$ACCOUNT_IN_TARGET" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Tabla 'account' ya existe en $TARGET_DB${NC}"
        read -p "¿Sobrescribir? (S/n): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[SsYy]$ ]] && [[ -n "$REPLY" ]]; then
            echo "Operación cancelada"
            unset MYSQL_PWD
            exit 0
        fi
        
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -e "DROP TABLE IF EXISTS account;" 2>&1
    fi
    
    # Crear tabla en TARGET_DB
    echo -e "${YELLOW}Creando tabla 'account' en $TARGET_DB...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -e "
        CREATE TABLE account LIKE $SOURCE_DB.account;
    " 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error al crear tabla${NC}"
        unset MYSQL_PWD
        exit 1
    fi
    
    echo -e "${GREEN}✅ Tabla creada${NC}"
    echo ""
    
    # Copiar datos
    echo -e "${YELLOW}Copiando datos...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -e "
        INSERT INTO account SELECT * FROM $SOURCE_DB.account;
    " 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error al copiar datos${NC}"
        unset MYSQL_PWD
        exit 1
    fi
    
    NEW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$TARGET_DB" -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ Datos copiados ($NEW_COUNT registros)${NC}"
    echo ""
    
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ OPERACIÓN COMPLETADA${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo "La tabla 'account' ahora está en $TARGET_DB donde el servidor la busca."
    echo ""
    
    unset MYSQL_PWD
else
    echo -e "${GREEN}✅ Script encontrado, ejecutando...${NC}"
    echo ""
    bash mover-account-a-player.sh
fi

echo ""
echo "Próximos pasos:"
echo "   1. Reinicia el contenedor: docker restart metin2-server"
echo "   2. Espera 30 segundos"
echo "   3. Verifica logs: docker logs --tail 50 metin2-server | grep -E 'TCP listening|MasterAuth|account|AuthLogin'"
echo ""

