#!/bin/bash
# Script para verificar si la consulta SQL de login devuelve resultados
# Uso: bash verificar-consulta-login.sh

echo "=========================================="
echo "Verificación de Consulta SQL de Login"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Ejecutando la misma consulta SQL que usa el servidor..."
echo ""

# La consulta exacta que usa el servidor
QUERY="SELECT password,securitycode,social_id,id,status,availDt - NOW() > 0,UNIX_TIMESTAMP(silver_expire),UNIX_TIMESTAMP(gold_expire),UNIX_TIMESTAMP(safebox_expire),UNIX_TIMESTAMP(autoloot_expire),UNIX_TIMESTAMP(fish_mind_expire),UNIX_TIMESTAMP(marriage_fast_expire),UNIX_TIMESTAMP(money_drop_rate_expire),UNIX_TIMESTAMP(create_time) FROM account WHERE login='test'"

echo "   Consulta: $QUERY"
echo ""

RESULT=$(mysql -uroot -pproyectalean -Dmetin2_player -e "$QUERY" 2>&1)

if [ $? -eq 0 ]; then
    echo "   ✅ Consulta ejecutada exitosamente"
    echo ""
    echo "   Resultados:"
    echo "$RESULT" | tail -5
    echo ""
    
    ROW_COUNT=$(echo "$RESULT" | grep -v "password" | grep -v "^$" | wc -l)
    echo "   Número de filas: $ROW_COUNT"
    echo ""
    
    if [ "$ROW_COUNT" -eq 0 ]; then
        echo "   ⚠️  La consulta NO devuelve resultados"
        echo "   Esto explicaría por qué no aparece 'QID_AUTH_LOGIN: SUCCESS'"
        echo ""
        echo "   Verificando si la cuenta existe..."
        mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT login, id, status FROM account WHERE login='test';" 2>/dev/null
    else
        echo "   ✅ La consulta devuelve resultados"
        echo ""
        echo "   Verificando campos específicos..."
        mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT login, id, status, LEFT(password, 30) as pwd_preview FROM account WHERE login='test';" 2>/dev/null
    fi
else
    echo "   ❌ Error al ejecutar la consulta:"
    echo "$RESULT"
    echo ""
fi

echo ""
echo "2. Verificando si hay campos NULL o valores problemáticos..."
echo ""

mysql -uroot -pproyectalean -Dmetin2_player <<EOF
SELECT 
    login,
    id,
    status,
    CASE WHEN password IS NULL THEN 'NULL' ELSE 'OK' END as password_status,
    CASE WHEN securitycode IS NULL THEN 'NULL' ELSE 'OK' END as securitycode_status,
    CASE WHEN social_id IS NULL THEN 'NULL' ELSE 'OK' END as social_id_status,
    CASE WHEN create_time IS NULL OR create_time = '0000-00-00 00:00:00' THEN 'INVALID' ELSE 'OK' END as create_time_status
FROM account 
WHERE login='test';
EOF

echo ""
echo "=========================================="
echo "ANÁLISIS"
echo "=========================================="
echo ""
echo "Si la consulta NO devuelve resultados:"
echo "   - El servidor no puede autenticar"
echo "   - Verifica que la cuenta exista en metin2_player"
echo ""
echo "Si la consulta devuelve resultados pero hay NULLs:"
echo "   - Puede causar errores en el código C++"
echo "   - Verifica que todos los campos requeridos tengan valores"
echo ""
echo "Si la consulta devuelve resultados correctos:"
echo "   - El problema está en el código C++"
echo "   - Puede haber un error silencioso en AnalyzeReturnQuery"
echo ""

