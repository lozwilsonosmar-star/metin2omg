#!/bin/bash
# Script para verificar y corregir problemas con package/

echo "=========================================="
echo "Verificación y Corrección de package/"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "═══════════════════════════════════════════"
echo "1. VERIFICANDO UBICACIÓN Y PERMISOS"
echo "═══════════════════════════════════════════"
echo ""

echo "1.1 Directorio de trabajo del servidor..."
WORKDIR=$(docker exec metin2-server pwd 2>/dev/null)
echo "   Directorio actual: $WORKDIR"

echo ""
echo "1.2 Verificando si existe /app/package/..."
if docker exec metin2-server test -d /app/package 2>/dev/null; then
    echo "✅ Directorio /app/package/ existe"
else
    echo "❌ Directorio /app/package/ NO existe"
    echo "   Creando directorio..."
    docker exec metin2-server mkdir -p /app/package
fi

echo ""
echo "1.3 Contando archivos en /app/package/..."
PACKAGE_COUNT=$(docker exec metin2-server sh -c "ls -1 /app/package/*.eix /app/package/*.epk 2>/dev/null | wc -l" 2>/dev/null)
echo "   Archivos encontrados: $PACKAGE_COUNT"

if [ "$PACKAGE_COUNT" -eq 0 ]; then
    echo "❌ No se encontraron archivos .eix o .epk"
    echo "   Necesitas copiar los archivos desde el cliente"
    exit 1
fi

echo ""
echo "1.4 Verificando permisos de archivos..."
PERMISSIONS=$(docker exec metin2-server sh -c "ls -ld /app/package 2>/dev/null | awk '{print \$1}'" 2>/dev/null)
echo "   Permisos del directorio: $PERMISSIONS"

# Verificar si el servidor puede leer los archivos
FIRST_FILE=$(docker exec metin2-server sh -c "ls -1 /app/package/*.eix 2>/dev/null | head -1" 2>/dev/null)
if [ -n "$FIRST_FILE" ]; then
    if docker exec metin2-server test -r "$FIRST_FILE" 2>/dev/null; then
        echo "✅ El servidor puede leer los archivos"
    else
        echo "❌ El servidor NO puede leer los archivos"
        echo "   Corrigiendo permisos..."
        docker exec metin2-server chmod -R 755 /app/package
    fi
fi

echo ""
echo "═══════════════════════════════════════════"
echo "2. VERIFICANDO LOGS DE CARGA"
echo "═══════════════════════════════════════════"
echo ""

echo "2.1 Buscando mensaje 'Failed to Load ClientPackageCryptInfo'..."
FAILED_LOAD=$(docker logs metin2-server 2>&1 | grep -c "Failed to Load ClientPackageCryptInfo")
if [ "$FAILED_LOAD" -gt 0 ]; then
    echo "❌ El servidor NO pudo cargar los archivos ($FAILED_LOAD veces)"
    echo ""
    echo "   Último mensaje de error:"
    docker logs metin2-server 2>&1 | grep "Failed to Load ClientPackageCryptInfo" | tail -1
else
    echo "✅ No se encontró el mensaje de error (los archivos se cargaron correctamente)"
fi

echo ""
echo "2.2 Verificando desde qué directorio se ejecuta el servidor..."
# El servidor busca "package/" relativo al directorio de trabajo
# Si el servidor se ejecuta desde /app, debería encontrar /app/package/
echo "   El servidor busca 'package/' relativo a su directorio de trabajo"
echo "   Si el servidor se ejecuta desde /app, debería encontrar /app/package/"

echo ""
echo "═══════════════════════════════════════════"
echo "3. VERIFICANDO ESTRUCTURA DE ARCHIVOS"
echo "═══════════════════════════════════════════"
echo ""

echo "3.1 Listando primeros archivos .eix..."
docker exec metin2-server sh -c "ls -1 /app/package/*.eix 2>/dev/null | head -5" 2>/dev/null

echo ""
echo "3.2 Listando primeros archivos .epk..."
docker exec metin2-server sh -c "ls -1 /app/package/*.epk 2>/dev/null | head -5" 2>/dev/null

echo ""
echo "3.3 Verificando tamaño de archivos..."
TOTAL_SIZE=$(docker exec metin2-server sh -c "du -sh /app/package 2>/dev/null | awk '{print \$1}'" 2>/dev/null)
echo "   Tamaño total: $TOTAL_SIZE"

echo ""
echo "═══════════════════════════════════════════"
echo "4. SOLUCIONES"
echo "═══════════════════════════════════════════"
echo ""

if [ "$FAILED_LOAD" -gt 0 ]; then
    echo "❌ PROBLEMA DETECTADO: El servidor no puede cargar los archivos"
    echo ""
    echo "Posibles causas:"
    echo "1. El servidor no se ejecuta desde /app"
    echo "2. Los archivos están corruptos o incompletos"
    echo "3. Los archivos no son compatibles con esta versión del servidor"
    echo ""
    echo "SOLUCIONES:"
    echo ""
    echo "A) Verifica que el servidor se ejecute desde /app:"
    echo "   docker exec metin2-server pwd"
    echo ""
    echo "B) Verifica que los archivos sean del cliente correcto:"
    echo "   Los archivos deben ser de la misma versión que el servidor"
    echo ""
    echo "C) Intenta reiniciar el servidor después de copiar los archivos:"
    echo "   docker restart metin2-server"
    echo "   sleep 10"
    echo "   docker logs --tail 50 metin2-server | grep -i package"
    echo ""
    echo "D) Verifica los logs completos de inicio:"
    echo "   docker logs metin2-server 2>&1 | grep -A 5 -B 5 'package'"
else
    echo "✅ Los archivos se están cargando correctamente"
    echo ""
    echo "Si aún hay errores de SEQUENCE, puede ser:"
    echo "1. Incompatibilidad de versión entre cliente y servidor"
    echo "2. El cliente necesita archivos adicionales"
    echo "3. Problema con la inicialización del cifrado"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "RESUMEN"
echo "═══════════════════════════════════════════"
echo ""
echo "Archivos en /app/package/: $PACKAGE_COUNT"
echo "Servidor cargó archivos: $([ "$FAILED_LOAD" -eq 0 ] && echo "✅ Sí" || echo "❌ No")"
echo ""

