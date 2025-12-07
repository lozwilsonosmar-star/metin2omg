#!/bin/bash
# Script para verificar logs recientes después de copiar package/

echo "=========================================="
echo "Verificar Logs Recientes (después de package/)"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "1. Verificando si el error de package/ desapareció (últimos 50 logs):"
docker logs --tail 50 metin2-server 2>&1 | grep -i "Failed to Load ClientPackageCryptInfo\|package" | tail -5

echo ""
echo "2. Logs de AuthLogin más recientes:"
docker logs --tail 100 metin2-server 2>&1 | grep "AuthLogin" | tail -5

echo ""
echo "3. Buscando LOGIN_BY_KEY en todos los logs:"
LOGIN_BY_KEY_COUNT=$(docker logs metin2-server 2>&1 | grep -c "LOGIN_BY_KEY" || echo "0")
echo "   Total de LOGIN_BY_KEY encontrados: $LOGIN_BY_KEY_COUNT"

if [ "$LOGIN_BY_KEY_COUNT" -eq 0 ]; then
    echo "   ⚠️ No se ha encontrado LOGIN_BY_KEY en ningún momento"
fi

echo ""
echo "4. Verificando errores de SEQUENCE recientes:"
docker logs --tail 50 metin2-server 2>&1 | grep -i "SEQUENCE.*mismatch" | tail -3

echo ""
echo "5. Verificando errores de GetRelatedMapSDBStreams:"
docker logs --tail 50 metin2-server 2>&1 | grep -i "GetRelatedMapSDBStreams" | tail -3

echo ""
echo "6. Últimos 20 logs completos (sin filtrar):"
docker logs --tail 20 metin2-server 2>&1 | grep -v "item_proto_test\|No test file\|Setting command privilege"

echo ""
echo "═══════════════════════════════════════════"
echo "ANÁLISIS"
echo "═══════════════════════════════════════════"
echo ""
if [ "$LOGIN_BY_KEY_COUNT" -eq 0 ]; then
    echo "❌ El cliente NO está enviando LOGIN_BY_KEY después del login exitoso"
    echo ""
    echo "Posibles causas:"
    echo "1. El cliente no está recibiendo HEADER_GC_AUTH_SUCCESS correctamente"
    echo "2. Hay un problema con el cifrado que impide la comunicación"
    echo "3. El cliente está esperando algo más antes de enviar LOGIN_BY_KEY"
    echo ""
    echo "Solución: Necesitamos verificar si el cliente está recibiendo"
    echo "el paquete de éxito y si hay errores de cifrado."
else
    echo "✅ Se encontraron LOGIN_BY_KEY en los logs"
fi
echo ""

