#!/bin/bash
# Script para diagnosticar qué pasa después del login exitoso
# Uso: bash diagnosticar-despues-login.sh

echo "=========================================="
echo "Diagnóstico Post-Login"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Verificando logs completos después del último login..."
echo ""

if docker ps | grep -q "metin2-server"; then
    echo "   Últimas 100 líneas de logs:"
    docker logs --tail 100 metin2-server 2>&1 | tail -50
    echo ""
    
    echo "   Errores después del login:"
    docker logs --tail 200 metin2-server 2>&1 | grep -A 10 -B 5 "AuthLogin result 1" | grep -iE "error|failed|critical|warning" | tail -20
    echo ""
    
    echo "   Consultas SQL relacionadas con player:"
    docker logs --tail 200 metin2-server 2>&1 | grep -iE "player|character|SELECT.*FROM.*player" | tail -10
    echo ""
else
    echo "   ⚠️  Contenedor no está corriendo"
    echo ""
fi

echo "2. Verificando datos del personaje en la base de datos..."
echo ""

ACCOUNT_ID=$(mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT id FROM account WHERE login='test';" 2>/dev/null | tail -1 | awk '{print $1}')

if [ -n "$ACCOUNT_ID" ] && [ "$ACCOUNT_ID" != "id" ]; then
    echo "   Account ID: $ACCOUNT_ID"
    echo ""
    echo "   Personajes asociados:"
    mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT id, name, level, job, account_id FROM player WHERE account_id=$ACCOUNT_ID;" 2>/dev/null
    echo ""
    echo "   Player index:"
    mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT * FROM player_index WHERE id=$ACCOUNT_ID;" 2>/dev/null
    echo ""
else
    echo "   ⚠️  No se encontró account_id para 'test'"
    echo ""
fi

echo "3. Verificando que el servidor esté procesando correctamente..."
echo ""

if ss -tuln | grep -q ":12345"; then
    echo "   ✅ Puerto 12345 está escuchando"
    
    # Verificar conexiones activas
    CONNECTIONS=$(ss -tn | grep :12345 | grep ESTAB | wc -l)
    echo "   Conexiones activas: $CONNECTIONS"
else
    echo "   ⚠️  Puerto 12345 NO está escuchando"
fi

echo ""
echo "=========================================="
echo "RECOMENDACIONES"
echo "=========================================="
echo ""
echo "Si te quedas en 'you have been connected to the server':"
echo ""
echo "1. Verifica los logs completos (sin filtros) para ver errores:"
echo "   docker logs --tail 100 metin2-server"
echo ""
echo "2. Intenta crear un nuevo personaje desde el cliente"
echo ""
echo "3. Verifica que no haya errores de SQL después del login"
echo ""
echo "4. Asegúrate de que el cliente esté esperando la respuesta del servidor"
echo ""

