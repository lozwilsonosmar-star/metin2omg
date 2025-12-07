#!/bin/bash
# Script que resuelve conflicto git y verifica mapeo de todas las tablas

echo "=========================================="
echo "Resolviendo Conflicto y Verificando Tablas"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

# 2. Ejecutar verificación
if [ -f "verificar-mapeo-todas-tablas.sh" ]; then
    chmod +x verificar-mapeo-todas-tablas.sh
    bash verificar-mapeo-todas-tablas.sh
else
    echo -e "${YELLOW}⚠️  Script no encontrado, ejecutando verificación manual...${NC}"
    echo ""
    
    export MYSQL_PWD="proyectalean"
    MYSQL_USER="root"
    MYSQL_HOST="127.0.0.1"
    MYSQL_PORT="3306"
    
    # Verificar contenedor
    if ! docker ps | grep -q "metin2-server"; then
        echo -e "${RED}❌ El contenedor metin2-server no está corriendo${NC}"
        unset MYSQL_PWD
        exit 1
    fi
    
    # Buscar game.conf
    GAME_CONF_PATH=$(docker exec metin2-server find / -name "game.conf" 2>/dev/null | head -1)
    
    if [ -z "$GAME_CONF_PATH" ]; then
        echo -e "${RED}❌ game.conf no encontrado${NC}"
        unset MYSQL_PWD
        exit 1
    fi
    
    GAME_CONF_CONTENT=$(docker exec metin2-server cat "$GAME_CONF_PATH" 2>/dev/null)
    
    # Extraer bases de datos
    PLAYER_DB=$(echo "$GAME_CONF_CONTENT" | grep "^PLAYER_SQL:" | awk '{print $5}')
    COMMON_DB=$(echo "$GAME_CONF_CONTENT" | grep "^COMMON_SQL:" | awk '{print $5}')
    
    echo -e "${BLUE}Bases de datos según game.conf:${NC}"
    echo "   PLAYER_SQL → $PLAYER_DB"
    echo "   COMMON_SQL → $COMMON_DB"
    echo ""
    
    # Tablas que deben estar en PLAYER_SQL
    PLAYER_TABLES=("account" "player" "item" "quest" "affect" "skill_proto" "refine_proto" "shop" "player_index" "banword")
    
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}VERIFICANDO TABLAS EN PLAYER_SQL ($PLAYER_DB)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""
    
    ERRORS=0
    
    for table in "${PLAYER_TABLES[@]}"; do
        EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "^$table$" || echo "0")
        EXISTS=$(echo "$EXISTS" | tr -d '\n' | head -1)
        
        if [ "$EXISTS" -gt 0 ] 2>/dev/null; then
            COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$PLAYER_DB" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "0")
            echo -e "${GREEN}✅ $table existe ($COUNT registros)${NC}"
        else
            echo -e "${RED}❌ $table NO existe en $PLAYER_DB${NC}"
            ((ERRORS++))
            
            # Buscar en otras bases
            for db in metin2_account metin2_common metin2_log; do
                if [ "$db" != "$PLAYER_DB" ]; then
                    FOUND=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "^$table$" || echo "0")
                    FOUND=$(echo "$FOUND" | tr -d '\n' | head -1)
                    if [ "$FOUND" -gt 0 ] 2>/dev/null; then
                        FOUND_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$db" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "0")
                        echo -e "${YELLOW}   ⚠️  Encontrada en: $db ($FOUND_COUNT registros)${NC}"
                        echo -e "${YELLOW}   💡 PROBLEMA: Debe estar en $PLAYER_DB${NC}"
                    fi
                fi
            done
        fi
    done
    
    echo ""
    
    # Verificar COMMON_SQL
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}VERIFICANDO TABLAS EN COMMON_SQL ($COMMON_DB)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""
    
    LOCALE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -e "SHOW TABLES LIKE 'locale';" 2>/dev/null | grep -c "^locale$" || echo "0")
    LOCALE_EXISTS=$(echo "$LOCALE_EXISTS" | tr -d '\n' | head -1)
    
    if [ "$LOCALE_EXISTS" -gt 0 ] 2>/dev/null; then
        COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT COUNT(*) FROM locale;" 2>/dev/null || echo "0")
        echo -e "${GREEN}✅ locale existe ($COUNT registros)${NC}"
        
        LANGUAGE_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT COUNT(*) FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null || echo "0")
        if [ "$LANGUAGE_EXISTS" -gt 0 ]; then
            LANGUAGE_VALUE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$COMMON_DB" -sN -e "SELECT mValue FROM locale WHERE mKey='LANGUAGE';" 2>/dev/null)
            echo -e "${GREEN}   ✓ LANGUAGE='$LANGUAGE_VALUE' configurado${NC}"
        else
            echo -e "${RED}   ❌ LANGUAGE no existe en locale${NC}"
            ((ERRORS++))
        fi
    else
        echo -e "${RED}❌ locale NO existe en $COMMON_DB${NC}"
        ((ERRORS++))
    fi
    
    echo ""
    
    # Resumen
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}RESUMEN${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""
    
    if [ $ERRORS -eq 0 ]; then
        echo -e "${GREEN}✅ Todas las tablas están correctamente mapeadas${NC}"
    else
        echo -e "${RED}❌ Se encontraron $ERRORS error(es)${NC}"
        echo ""
        echo -e "${YELLOW}Acciones recomendadas:${NC}"
        echo "   1. Mover tablas faltantes a las bases de datos correctas"
        echo "   2. Ejecutar este script nuevamente para verificar"
    fi
    
    unset MYSQL_PWD
fi

