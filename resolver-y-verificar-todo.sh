#!/bin/bash
# Script que resuelve el conflicto de git y ejecuta todas las verificaciones

echo "=========================================="
echo "Resolviendo Conflicto y Verificando Todo"
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

# 2. Hacer scripts ejecutables
echo -e "${YELLOW}2. Haciendo scripts ejecutables...${NC}"
chmod +x verificar-mapeo-servidor-bd.sh 2>/dev/null || true
chmod +x corregir-problemas-criticos-inmediato.sh 2>/dev/null || true
echo -e "${GREEN}✅ Scripts preparados${NC}"
echo ""

# 3. Verificar mapeo servidor-BD
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3. VERIFICANDO MAPEO SERVIDOR-BD${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ -f "verificar-mapeo-servidor-bd.sh" ]; then
    bash verificar-mapeo-servidor-bd.sh
else
    echo -e "${RED}❌ Script verificar-mapeo-servidor-bd.sh no encontrado${NC}"
    echo -e "${YELLOW}   Ejecutando verificación manual...${NC}"
    
    export MYSQL_PWD="proyectalean"
    MYSQL_USER="root"
    MYSQL_HOST="127.0.0.1"
    MYSQL_PORT="3306"
    
    echo ""
    echo "Bases de datos que existen:"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys"
    
    echo ""
    echo "Verificando game.conf del contenedor:"
    docker exec metin2-server cat /app/gamefiles/conf/game.conf 2>/dev/null | grep -E "PLAYER_SQL|COMMON_SQL|LOG_SQL" || echo "No se pudo leer game.conf"
    
    unset MYSQL_PWD
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}4. CORRIGIENDO PROBLEMAS CRÍTICOS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ -f "corregir-problemas-criticos-inmediato.sh" ]; then
    bash corregir-problemas-criticos-inmediato.sh
else
    echo -e "${YELLOW}⚠️  Script no encontrado, ejecutando correcciones manuales...${NC}"
    
    export MYSQL_PWD="proyectalean"
    MYSQL_USER="root"
    MYSQL_HOST="127.0.0.1"
    MYSQL_PORT="3306"
    
    # Corregir addon_type
    echo "Corrigiendo addon_type..."
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player -e "
        ALTER TABLE item_proto 
        MODIFY COLUMN addon_type MEDIUMINT UNSIGNED NOT NULL DEFAULT 0;
    " 2>&1 && echo -e "${GREEN}✅ addon_type corregido${NC}" || echo -e "${RED}❌ Error${NC}"
    
    # Insertar LANGUAGE
    echo "Insertando LANGUAGE..."
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_common -e "
        INSERT IGNORE INTO locale (mKey, mValue) VALUES ('LANGUAGE', 'kr');
    " 2>&1 && echo -e "${GREEN}✅ LANGUAGE insertado${NC}" || echo -e "${RED}❌ Error${NC}"
    
    unset MYSQL_PWD
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}RESUMEN${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo "Próximos pasos:"
echo "   1. Reinicia el contenedor: docker restart metin2-server"
echo "   2. Espera 30 segundos"
echo "   3. Verifica logs: docker logs --tail 50 metin2-server"
echo ""

