#!/bin/bash
# Solución rápida para problemas en VPS
# Uso: bash solucion-rapida-vps.sh

set -e

echo "=========================================="
echo "Solución Rápida - VPS"
echo "=========================================="
echo ""

cd /opt/metin2omg

# 1. Resolver conflicto de git
echo "1. Resolviendo conflicto de git..."
git stash
git pull origin main
echo "✅ Git actualizado"
echo ""

# 2. Verificar/corregir AUTH_SERVER
echo "2. Verificando AUTH_SERVER..."
if grep -q "^GAME_AUTH_SERVER=master" .env; then
    echo "✅ AUTH_SERVER ya está en 'master'"
else
    echo "⚠️  Corrigiendo AUTH_SERVER..."
    sed -i 's/^GAME_AUTH_SERVER=.*/GAME_AUTH_SERVER=master/' .env
    echo "✅ AUTH_SERVER corregido a 'master'"
fi
echo ""

# 3. Obtener credenciales
MYSQL_HOST=$(grep "^MYSQL_HOST=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "localhost")
MYSQL_PORT=$(grep "^MYSQL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "3306")
MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2")
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

export MYSQL_PWD="$MYSQL_PASSWORD"

# 4. Insertar datos en skill_proto
echo "3. Verificando e insertando datos en skill_proto..."
SKILL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM skill_proto;" 2>/dev/null || echo "0")

if [ "$SKILL_COUNT" = "0" ] || [ -z "$SKILL_COUNT" ]; then
    echo "⚠️  skill_proto está vacía..."
    
    # Intentar importar desde player.sql si existe
    if [ -f "metin2_mysql_dump/player.sql" ]; then
        echo "✅ Encontrado player.sql, importando datos completos..."
        sed 's/INSERT INTO/INSERT IGNORE INTO/g' metin2_mysql_dump/player.sql | \
            mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player 2>&1 | \
            grep -v "already exists\|Duplicate entry\|Warning" || true
        echo "✅ Datos de player.sql importados"
    else
        echo "⚠️  player.sql no encontrado, insertando datos mínimos..."
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
        echo "✅ Datos mínimos insertados"
    fi
    
    SKILL_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM skill_proto;" 2>/dev/null || echo "0")
    if [ "$SKILL_COUNT" != "0" ]; then
        echo "✅ skill_proto ahora tiene $SKILL_COUNT registros"
    else
        echo "❌ Error al insertar datos"
    fi
else
    echo "✅ skill_proto ya tiene $SKILL_COUNT registros"
fi
echo ""

# 5. Verificar shop
echo "4. Verificando shop..."
SHOP_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -Dmetin2_player -sN -e "SELECT COUNT(*) FROM shop;" 2>/dev/null || echo "0")
if [ "$SHOP_COUNT" = "0" ]; then
    echo "⚠️  shop está vacía, insertando registro mínimo..."
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" metin2_player -e "INSERT IGNORE INTO shop (vnum, npc_vnum) VALUES (1, 0);" 2>&1 | grep -v "Duplicate entry" || true
    echo "✅ shop corregida"
else
    echo "✅ shop tiene $SHOP_COUNT registros"
fi
echo ""

unset MYSQL_PWD

# 6. Reiniciar contenedor
echo "5. Reiniciando contenedor para aplicar cambios..."
docker restart metin2-server
echo "✅ Contenedor reiniciado"
echo ""

echo "=========================================="
echo "✅ Correcciones aplicadas"
echo "=========================================="
echo ""
echo "Espera 30-60 segundos y verifica:"
echo "   bash verificar-estado-servidor.sh"
echo ""

