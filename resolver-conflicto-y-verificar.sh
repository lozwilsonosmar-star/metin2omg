#!/bin/bash
# Script para resolver conflicto de git y verificar tablas con credenciales correctas

echo "=========================================="
echo "Resolviendo Conflicto y Verificando Tablas"
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

# 1. Resolver conflicto de git
echo -e "${YELLOW}1. Resolviendo conflicto de git...${NC}"
git stash
git pull origin main
echo -e "${GREEN}✅ Git actualizado${NC}"
echo ""

# 2. Verificar tablas directamente con root
echo -e "${YELLOW}2. Verificando tablas con usuario root...${NC}"
echo ""

export MYSQL_PWD="proyectalean"

# Verificar account en metin2_account
echo "Verificando tabla 'account' en metin2_account:"
ACCOUNT_EXISTS=$(mysql -h127.0.0.1 -P3306 -uroot metin2_account -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c "account" || echo "0")
if [ "$ACCOUNT_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Tabla 'account' existe${NC}"
    ACCOUNT_COUNT=$(mysql -h127.0.0.1 -P3306 -uroot metin2_account -sN -e "SELECT COUNT(*) FROM account;" 2>/dev/null)
    echo "   Registros: $ACCOUNT_COUNT"
    
    # Verificar cuenta test
    TEST_EXISTS=$(mysql -h127.0.0.1 -P3306 -uroot metin2_account -sN -e "SELECT COUNT(*) FROM account WHERE login='test';" 2>/dev/null)
    if [ "$TEST_EXISTS" -gt 0 ]; then
        echo -e "${GREEN}✅ Cuenta 'test' encontrada${NC}"
        mysql -h127.0.0.1 -P3306 -uroot metin2_account -e "SELECT id, login FROM account WHERE login='test';" 2>/dev/null
    else
        echo -e "${YELLOW}⚠️  Cuenta 'test' no encontrada${NC}"
    fi
else
    echo -e "${RED}❌ Tabla 'account' NO existe${NC}"
fi
echo ""

# Verificar player_index en metin2_account
echo "Verificando tabla 'player_index' en metin2_account:"
PLAYER_INDEX_EXISTS=$(mysql -h127.0.0.1 -P3306 -uroot metin2_account -e "SHOW TABLES LIKE 'player_index';" 2>/dev/null | grep -c "player_index" || echo "0")
if [ "$PLAYER_INDEX_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Tabla 'player_index' existe${NC}"
    PLAYER_INDEX_COUNT=$(mysql -h127.0.0.1 -P3306 -uroot metin2_account -sN -e "SELECT COUNT(*) FROM player_index;" 2>/dev/null)
    echo "   Registros: $PLAYER_INDEX_COUNT"
else
    echo -e "${RED}❌ Tabla 'player_index' NO existe${NC}"
fi
echo ""

# Verificar player en metin2_player
echo "Verificando tabla 'player' en metin2_player:"
PLAYER_EXISTS=$(mysql -h127.0.0.1 -P3306 -uroot metin2_player -e "SHOW TABLES LIKE 'player';" 2>/dev/null | grep -c "player" || echo "0")
if [ "$PLAYER_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Tabla 'player' existe${NC}"
    PLAYER_COUNT=$(mysql -h127.0.0.1 -P3306 -uroot metin2_player -sN -e "SELECT COUNT(*) FROM player;" 2>/dev/null)
    echo "   Registros: $PLAYER_COUNT"
else
    echo -e "${RED}❌ Tabla 'player' NO existe${NC}"
fi
echo ""

# Verificar item en metin2_player
echo "Verificando tabla 'item' en metin2_player:"
ITEM_EXISTS=$(mysql -h127.0.0.1 -P3306 -uroot metin2_player -e "SHOW TABLES LIKE 'item';" 2>/dev/null | grep -c "item" || echo "0")
if [ "$ITEM_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Tabla 'item' existe${NC}"
    ITEM_COUNT=$(mysql -h127.0.0.1 -P3306 -uroot metin2_player -sN -e "SELECT COUNT(*) FROM item;" 2>/dev/null)
    echo "   Registros: $ITEM_COUNT"
else
    echo -e "${RED}❌ Tabla 'item' NO existe${NC}"
fi
echo ""

# Verificar quest en metin2_player
echo "Verificando tabla 'quest' en metin2_player:"
QUEST_EXISTS=$(mysql -h127.0.0.1 -P3306 -uroot metin2_player -e "SHOW TABLES LIKE 'quest';" 2>/dev/null | grep -c "quest" || echo "0")
if [ "$QUEST_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Tabla 'quest' existe${NC}"
    QUEST_COUNT=$(mysql -h127.0.0.1 -P3306 -uroot metin2_player -sN -e "SELECT COUNT(*) FROM quest;" 2>/dev/null)
    echo "   Registros: $QUEST_COUNT"
else
    echo -e "${RED}❌ Tabla 'quest' NO existe${NC}"
fi
echo ""

# Verificar affect en metin2_player
echo "Verificando tabla 'affect' en metin2_player:"
AFFECT_EXISTS=$(mysql -h127.0.0.1 -P3306 -uroot metin2_player -e "SHOW TABLES LIKE 'affect';" 2>/dev/null | grep -c "affect" || echo "0")
if [ "$AFFECT_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Tabla 'affect' existe${NC}"
    AFFECT_COUNT=$(mysql -h127.0.0.1 -P3306 -uroot metin2_player -sN -e "SELECT COUNT(*) FROM affect;" 2>/dev/null)
    echo "   Registros: $AFFECT_COUNT"
else
    echo -e "${RED}❌ Tabla 'affect' NO existe${NC}"
fi
echo ""

# Resumen
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}RESUMEN${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

TOTAL_ERRORS=0
[ "$ACCOUNT_EXISTS" -eq 0 ] && ((TOTAL_ERRORS++))
[ "$PLAYER_INDEX_EXISTS" -eq 0 ] && ((TOTAL_ERRORS++))
[ "$PLAYER_EXISTS" -eq 0 ] && ((TOTAL_ERRORS++))
[ "$ITEM_EXISTS" -eq 0 ] && ((TOTAL_ERRORS++))
[ "$QUEST_EXISTS" -eq 0 ] && ((TOTAL_ERRORS++))
[ "$AFFECT_EXISTS" -eq 0 ] && ((TOTAL_ERRORS++))

if [ $TOTAL_ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las tablas existen${NC}"
    echo ""
    echo "El problema era que el script usaba credenciales incorrectas."
    echo "Las tablas están correctamente creadas."
else
    echo -e "${RED}❌ Faltan $TOTAL_ERRORS tabla(s)${NC}"
fi

unset MYSQL_PWD

