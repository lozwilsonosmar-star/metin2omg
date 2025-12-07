#!/bin/bash
# Script para verificar que package/ se cargó correctamente

echo "=========================================="
echo "Verificar que package/ se cargó correctamente"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "Esperando 30 segundos para que el servidor inicie..."
sleep 30

echo ""
echo "1. Verificando archivos en /app/package/ del contenedor:"
docker exec metin2-server ls -la /app/package 2>/dev/null | head -10

echo ""
echo "2. Contando archivos:"
FILE_COUNT=$(docker exec metin2-server find /app/package -type f 2>/dev/null | wc -l)
echo "   Total: $FILE_COUNT archivos"

echo ""
echo "3. Verificando logs sobre package/ (últimos 100 logs):"
docker logs --tail 100 metin2-server 2>&1 | grep -i "package\|crypt" | tail -10

echo ""
echo "4. Buscando error 'Failed to Load ClientPackageCryptInfo Files':"
ERROR_COUNT=$(docker logs --tail 200 metin2-server 2>&1 | grep -c "Failed to Load ClientPackageCryptInfo Files" || echo "0")
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "   ✅ No se encontró el error (los archivos se cargaron correctamente)"
else
    echo "   ⚠️ Aún aparece el error ($ERROR_COUNT veces)"
fi

echo ""
echo "5. Verificando logs de AuthLogin y LOGIN_BY_KEY (últimos 50 logs):"
docker logs --tail 50 metin2-server 2>&1 | grep -E "AuthLogin|LOGIN_BY_KEY|PHASE_SELECT" | tail -10

echo ""
echo "═══════════════════════════════════════════"
echo "RESUMEN"
echo "═══════════════════════════════════════════"
echo ""
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ Los archivos de package/ se cargaron correctamente"
    echo ""
    echo "Ahora intenta conectarte desde el cliente y deberías ver:"
    echo "1. AuthLogin result 1 (login exitoso)"
    echo "2. LOGIN_BY_KEY (cliente envía petición de personajes)"
    echo "3. LoginSuccess (servidor envía lista de personajes)"
    echo ""
    echo "Para monitorear en tiempo real:"
    echo "   docker logs -f metin2-server | grep -E 'AuthLogin|LOGIN_BY_KEY|LoginSuccess|PHASE_SELECT'"
else
    echo "⚠️ Aún hay errores. Verifica que los archivos estén en /app/package/"
fi
echo ""

