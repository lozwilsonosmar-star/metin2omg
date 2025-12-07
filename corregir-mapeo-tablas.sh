#!/bin/bash
# Script para corregir el mapeo de tablas entre bases de datos
# Elimina duplicados y mueve tablas a las bases de datos correctas

echo "=========================================="
echo "Corrección de Mapeo de Tablas"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    exit 1
}

# Obtener credenciales
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

source .env 2>/dev/null || true

MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USER=${MYSQL_USER:-metin2}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-Osmar2405}

if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

export MYSQL_PWD="$MYSQL_PASSWORD"

echo -e "${YELLOW}⚠️  Este script eliminará tablas duplicadas en bases de datos incorrectas${NC}"
echo -e "${YELLOW}   Asegúrate de tener un backup antes de continuar${NC}"
echo ""
read -p "¿Continuar? (S/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Ss]$ ]] && [ -n "$CONFIRM" ]; then
    echo "Operación cancelada"
    unset MYSQL_PWD
    exit 0
fi

echo ""

# ============================================================
# CORRECCIONES
# ============================================================

ERRORS=0

# 1. Eliminar account de metin2_player (debe estar solo en metin2_account)
echo -e "${BLUE}1. Corrigiendo tabla 'account'...${NC}"
ACCOUNT_IN_PLAYER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SHOW TABLES LIKE 'account';" 2>/dev/null | wc -l)
if [ "$ACCOUNT_IN_PLAYER" -gt 0 ]; then
    echo -e "${YELLOW}   Eliminando 'account' de metin2_player...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -e "DROP TABLE IF EXISTS account;" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✅ Tabla 'account' eliminada de metin2_player${NC}"
    else
        echo -e "${RED}   ❌ Error al eliminar 'account' de metin2_player${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${GREEN}   ✅ 'account' no está en metin2_player (correcto)${NC}"
fi
echo ""

# 2. Eliminar player_index de metin2_player (debe estar solo en metin2_account)
echo -e "${BLUE}2. Corrigiendo tabla 'player_index'...${NC}"
PLAYER_INDEX_IN_PLAYER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SHOW TABLES LIKE 'player_index';" 2>/dev/null | wc -l)
if [ "$PLAYER_INDEX_IN_PLAYER" -gt 0 ]; then
    # Verificar si tiene datos importantes
    ROW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM player_index;" 2>/dev/null || echo "0")
    if [ "$ROW_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}   ⚠️  player_index en metin2_player tiene $ROW_COUNT registros${NC}"
        echo -e "${YELLOW}   Copiando datos a metin2_account antes de eliminar...${NC}"
        
        # Copiar datos a metin2_account si no existen
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -e "
            INSERT IGNORE INTO player_index 
            SELECT * FROM metin2_player.player_index;
        " 2>/dev/null
        
        echo -e "${GREEN}   ✅ Datos copiados a metin2_account${NC}"
    fi
    
    echo -e "${YELLOW}   Eliminando 'player_index' de metin2_player...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -e "DROP TABLE IF EXISTS player_index;" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✅ Tabla 'player_index' eliminada de metin2_player${NC}"
    else
        echo -e "${RED}   ❌ Error al eliminar 'player_index' de metin2_player${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${GREEN}   ✅ 'player_index' no está en metin2_player (correcto)${NC}"
fi
echo ""

# 3. Eliminar skill_proto de metin2_common (debe estar solo en metin2_player)
echo -e "${BLUE}3. Corrigiendo tabla 'skill_proto'...${NC}"
SKILL_PROTO_IN_COMMON=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -sN -e "SHOW TABLES LIKE 'skill_proto';" 2>/dev/null | wc -l)
if [ "$SKILL_PROTO_IN_COMMON" -gt 0 ]; then
    ROW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -sN -e "SELECT COUNT(*) FROM skill_proto;" 2>/dev/null || echo "0")
    if [ "$ROW_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}   Eliminando 'skill_proto' vacía de metin2_common...${NC}"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -e "DROP TABLE IF EXISTS skill_proto;" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}   ✅ Tabla 'skill_proto' eliminada de metin2_common${NC}"
        else
            echo -e "${RED}   ❌ Error al eliminar 'skill_proto' de metin2_common${NC}"
            ((ERRORS++))
        fi
    else
        echo -e "${YELLOW}   ⚠️  skill_proto en metin2_common tiene $ROW_COUNT registros${NC}"
        echo -e "${YELLOW}   Copiando datos a metin2_player antes de eliminar...${NC}"
        
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -e "
            INSERT IGNORE INTO skill_proto 
            SELECT * FROM metin2_common.skill_proto;
        " 2>/dev/null
        
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -e "DROP TABLE IF EXISTS skill_proto;" 2>/dev/null
        echo -e "${GREEN}   ✅ Datos copiados y tabla eliminada de metin2_common${NC}"
    fi
else
    echo -e "${GREEN}   ✅ 'skill_proto' no está en metin2_common (correcto)${NC}"
fi
echo ""

# 4. Eliminar banword de metin2_common (debe estar solo en metin2_player)
echo -e "${BLUE}4. Corrigiendo tabla 'banword'...${NC}"
BANWORD_IN_COMMON=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -sN -e "SHOW TABLES LIKE 'banword';" 2>/dev/null | wc -l)
if [ "$BANWORD_IN_COMMON" -gt 0 ]; then
    ROW_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -sN -e "SELECT COUNT(*) FROM banword;" 2>/dev/null || echo "0")
    if [ "$ROW_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}   Eliminando 'banword' vacía de metin2_common...${NC}"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -e "DROP TABLE IF EXISTS banword;" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}   ✅ Tabla 'banword' eliminada de metin2_common${NC}"
        else
            echo -e "${RED}   ❌ Error al eliminar 'banword' de metin2_common${NC}"
            ((ERRORS++))
        fi
    else
        echo -e "${YELLOW}   ⚠️  banword en metin2_common tiene $ROW_COUNT registros${NC}"
        echo -e "${YELLOW}   Copiando datos a metin2_player antes de eliminar...${NC}"
        
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -e "
            INSERT IGNORE INTO banword 
            SELECT * FROM metin2_common.banword;
        " 2>/dev/null
        
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -e "DROP TABLE IF EXISTS banword;" 2>/dev/null
        echo -e "${GREEN}   ✅ Datos copiados y tabla eliminada de metin2_common${NC}"
    fi
else
    echo -e "${GREEN}   ✅ 'banword' no está en metin2_common (correcto)${NC}"
fi
echo ""

# ============================================================
# VERIFICACIÓN FINAL
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}VERIFICACIÓN FINAL${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Verificar que las correcciones funcionaron
echo -e "${YELLOW}Verificando mapeo correcto...${NC}"
echo ""

# account solo en metin2_account
ACCOUNT_IN_ACCOUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -sN -e "SHOW TABLES LIKE 'account';" 2>/dev/null | wc -l)
ACCOUNT_IN_PLAYER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SHOW TABLES LIKE 'account';" 2>/dev/null | wc -l)
if [ "$ACCOUNT_IN_ACCOUNT" -gt 0 ] && [ "$ACCOUNT_IN_PLAYER" -eq 0 ]; then
    echo -e "${GREEN}✅ 'account' está solo en metin2_account${NC}"
else
    echo -e "${RED}❌ 'account' aún tiene problemas de mapeo${NC}"
    ((ERRORS++))
fi

# player_index solo en metin2_account
PLAYER_INDEX_IN_ACCOUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_account -sN -e "SHOW TABLES LIKE 'player_index';" 2>/dev/null | wc -l)
PLAYER_INDEX_IN_PLAYER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SHOW TABLES LIKE 'player_index';" 2>/dev/null | wc -l)
if [ "$PLAYER_INDEX_IN_ACCOUNT" -gt 0 ] && [ "$PLAYER_INDEX_IN_PLAYER" -eq 0 ]; then
    echo -e "${GREEN}✅ 'player_index' está solo en metin2_account${NC}"
else
    echo -e "${RED}❌ 'player_index' aún tiene problemas de mapeo${NC}"
    ((ERRORS++))
fi

# skill_proto solo en metin2_player
SKILL_PROTO_IN_COMMON=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -sN -e "SHOW TABLES LIKE 'skill_proto';" 2>/dev/null | wc -l)
SKILL_PROTO_IN_PLAYER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SHOW TABLES LIKE 'skill_proto';" 2>/dev/null | wc -l)
if [ "$SKILL_PROTO_IN_COMMON" -eq 0 ] && [ "$SKILL_PROTO_IN_PLAYER" -gt 0 ]; then
    echo -e "${GREEN}✅ 'skill_proto' está solo en metin2_player${NC}"
else
    echo -e "${RED}❌ 'skill_proto' aún tiene problemas de mapeo${NC}"
    ((ERRORS++))
fi

# banword solo en metin2_player
BANWORD_IN_COMMON=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_common -sN -e "SHOW TABLES LIKE 'banword';" 2>/dev/null | wc -l)
BANWORD_IN_PLAYER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SHOW TABLES LIKE 'banword';" 2>/dev/null | wc -l)
if [ "$BANWORD_IN_COMMON" -eq 0 ] && [ "$BANWORD_IN_PLAYER" -gt 0 ]; then
    echo -e "${GREEN}✅ 'banword' está solo en metin2_player${NC}"
else
    echo -e "${RED}❌ 'banword' aún tiene problemas de mapeo${NC}"
    ((ERRORS++))
fi

echo ""

# ============================================================
# RESUMEN
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Mapeo de tablas corregido correctamente${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "   1. Ejecuta: bash verificar-tablas-columnas-completas.sh"
    echo "   2. Verifica que todas las tablas estén en las bases correctas"
    echo "   3. Reinicia el servidor si es necesario"
else
    echo -e "${RED}❌ Se encontraron $ERRORS error(es)${NC}"
    echo "   Revisa los mensajes arriba para más detalles"
fi

unset MYSQL_PWD

