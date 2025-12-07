#!/bin/bash
# Script para importar datos mínimos de skill_proto y otras tablas críticas
# Esto permite que el servidor inicie, aunque no tendrá todas las habilidades
# Uso: bash docker/importar-datos-minimos-skill.sh

set -e

echo "=========================================="
echo "Importación de Datos Mínimos"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Obtener credenciales de MySQL desde .env si existe
if [ -f ".env" ]; then
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
    MYSQL_PORT=$(grep "^MYSQL_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "3306")
    MYSQL_USER=$(grep "^MYSQL_USER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "metin2")
    MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "changeme")
    
    # Convertir localhost a 127.0.0.1
    if [ "$MYSQL_HOST" = "localhost" ]; then
        MYSQL_HOST="127.0.0.1"
    fi
    
    echo -e "${YELLOW}Usando credenciales de .env${NC}"
    echo -e "${YELLOW}Host: ${MYSQL_HOST}:${MYSQL_PORT}${NC}"
    echo -e "${YELLOW}Usuario: ${MYSQL_USER}${NC}"
    echo ""
else
    echo -e "${RED}❌ No se encontró archivo .env${NC}"
    exit 1
fi

# Exportar contraseña para mysql
export MYSQL_PWD="$MYSQL_PASSWORD"

echo -e "${YELLOW}⚠️  IMPORTANTE: Estos son datos MÍNIMOS para que el servidor inicie${NC}"
echo -e "${YELLOW}   El servidor funcionará pero tendrá habilidades limitadas${NC}"
echo -e "${YELLOW}   Para datos completos, importa los dumps SQL completos${NC}"
echo ""

# Verificar si skill_proto ya tiene datos
SKILL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM skill_proto;" 2>/dev/null || echo "0")

if [ "$SKILL_COUNT" != "0" ] && [ -n "$SKILL_COUNT" ] && [ "$SKILL_COUNT" != "0" ]; then
    echo -e "${GREEN}✅ skill_proto ya tiene $SKILL_COUNT registros${NC}"
    echo -e "${YELLOW}   No se importarán datos mínimos (ya hay datos)${NC}"
    exit 0
fi

echo -e "${GREEN}📊 Insertando datos mínimos en skill_proto...${NC}"

# Insertar un skill dummy básico (vnum 1, tipo básico)
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player <<EOF 2>&1 | grep -v "Duplicate entry" || true
INSERT IGNORE INTO skill_proto (
    dwVnum, szName, bType, bMaxLevel, dwSplashRange,
    szPointOn, szPointPoly, szSPCostPoly, szDurationPoly, szDurationSPCostPoly,
    szCooldownPoly, szMasterBonusPoly, setFlag, setAffectFlag,
    szPointOn2, szPointPoly2, szDurationPoly2, setAffectFlag2,
    szPointOn3, szPointPoly3, szDurationPoly3, szGrandMasterAddSPCostPoly,
    bLevelStep, bLevelLimit, prerequisiteSkillVnum, prerequisiteSkillLevel,
    iMaxHit, szSplashAroundDamageAdjustPoly, eSkillType, dwTargetRange
) VALUES (
    1, 'Basic Skill', 0, 1, 0,
    '0', '0', '0', '0', '0',
    '0', '0', 0, 0,
    '0', '0', '0', 0,
    '0', '0', '0', '0',
    0, 0, 0, 0,
    0, '0', 0, 0
);
EOF

# Verificar refine_proto
REFINE_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM refine_proto;" 2>/dev/null || echo "0")

if [ "$REFINE_COUNT" = "0" ] || [ -z "$REFINE_COUNT" ]; then
    echo -e "${GREEN}📊 Insertando datos mínimos en refine_proto...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player <<EOF 2>&1 | grep -v "Duplicate entry" || true
INSERT IGNORE INTO refine_proto (vnum, prob, cost, prob_break) VALUES (1, 100, 1000, 0);
EOF
fi

# Verificar shop
SHOP_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM shop;" 2>/dev/null || echo "0")

if [ "$SHOP_COUNT" = "0" ] || [ -z "$SHOP_COUNT" ]; then
    echo -e "${GREEN}📊 Insertando datos mínimos en shop...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player <<EOF 2>&1 | grep -v "Duplicate entry" || true
INSERT IGNORE INTO shop (vnum, npc_vnum) VALUES (1, 0);
EOF
fi

# Verificar resultados
echo ""
echo -e "${GREEN}🔍 Verificando datos importados...${NC}"

SKILL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM skill_proto;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   skill_proto: ${SKILL_COUNT} registros${NC}"

REFINE_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM refine_proto;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   refine_proto: ${REFINE_COUNT} registros${NC}"

SHOP_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM shop;" 2>/dev/null || echo "0")
echo -e "${YELLOW}   shop: ${SHOP_COUNT} registros${NC}"

echo ""
if [ "$SKILL_COUNT" != "0" ] && [ -n "$SKILL_COUNT" ]; then
    echo -e "${GREEN}✅ Datos mínimos importados correctamente${NC}"
    echo -e "${YELLOW}   ⚠️  El servidor debería poder iniciar ahora${NC}"
    echo -e "${YELLOW}   ⚠️  Para datos completos, importa los dumps SQL completos${NC}"
else
    echo -e "${RED}❌ Error al importar datos mínimos${NC}"
fi

unset MYSQL_PWD

