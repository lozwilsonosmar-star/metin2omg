#!/bin/bash
# Script para diagnosticar problemas después de conexión exitosa
# Uso: bash diagnosticar-conexion-exitosa.sh

echo "=========================================="
echo "Diagnóstico de Conexión Exitosa"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Verificando logs del servidor (últimas 50 líneas)..."
echo ""

if docker ps | grep -q "metin2-server"; then
    echo "   Logs relacionados con 'test' o login:"
    docker logs --tail 100 metin2-server 2>&1 | grep -iE "test|login|connected|player|character|create" | tail -20
    echo ""
    
    echo "   Errores recientes:"
    docker logs --tail 50 metin2-server 2>&1 | grep -iE "error|failed|critical" | tail -10
    echo ""
else
    echo "   ⚠️  Contenedor no está corriendo"
    echo ""
fi

echo "2. Verificando si hay personajes creados para la cuenta 'test'..."
echo ""

PLAYER_COUNT=$(mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT COUNT(*) as total FROM player WHERE account_id IN (SELECT id FROM account WHERE login='test');" 2>/dev/null | tail -1 | awk '{print $1}')

if [ "$PLAYER_COUNT" -gt 0 ]; then
    echo "   ✅ Hay $PLAYER_COUNT personaje(s) creado(s) para la cuenta 'test'"
    echo ""
    echo "   Personajes:"
    mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT id, name, level, job FROM player WHERE account_id IN (SELECT id FROM account WHERE login='test');" 2>/dev/null
    echo ""
else
    echo "   ⚠️  No hay personajes creados para la cuenta 'test'"
    echo ""
    echo "   Esto es normal si es la primera vez que te conectas."
    echo "   Deberías poder crear un personaje desde el cliente."
    echo ""
fi

echo "3. Verificando player_index para la cuenta..."
echo ""

mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT * FROM player_index WHERE id IN (SELECT id FROM account WHERE login='test');" 2>/dev/null

echo ""
echo "4. Verificando que el servidor esté escuchando correctamente..."
echo ""

if ss -tuln | grep -q ":12345"; then
    echo "   ✅ Puerto 12345 está escuchando"
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
echo "1. Verifica que puedas crear un personaje desde el cliente"
echo "2. Si no puedes crear personaje, revisa los logs del servidor"
echo "3. Verifica que las tablas player y player_index existan"
echo "4. Asegúrate de que el servidor tenga los datos necesarios (mob_proto, item_proto, etc.)"
echo ""

