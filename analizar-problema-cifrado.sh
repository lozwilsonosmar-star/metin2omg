#!/bin/bash
# Script para analizar el problema de cifrado y posibles soluciones

echo "=========================================="
echo "Análisis del Problema de Cifrado"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "═══════════════════════════════════════════"
echo "1. ESTADO ACTUAL"
echo "═══════════════════════════════════════════"
echo ""

# Verificar si hay archivos cshybridcrypt
CRYPT_COUNT=$(docker exec metin2-server sh -c "ls -1 /app/package/cshybridcrypt* 2>/dev/null | wc -l" 2>/dev/null)
echo "Archivos cshybridcrypt* en contenedor: $CRYPT_COUNT"

# Verificar logs de carga
FAILED_LOAD=$(docker logs metin2-server 2>&1 | grep -c "Failed to Load ClientPackageCryptInfo")
echo "Intentos fallidos de carga: $FAILED_LOAD"

# Verificar errores de SEQUENCE
SEQUENCE_ERRORS=$(docker logs metin2-server 2>&1 | grep -c "SEQUENCE.*mismatch")
echo "Errores de SEQUENCE: $SEQUENCE_ERRORS"

echo ""
echo "═══════════════════════════════════════════"
echo "2. ANÁLISIS DEL CÓDIGO"
echo "═══════════════════════════════════════════"
echo ""
echo "El servidor verifica 'if( packet.KeyStreamLen > 0 )' antes de enviar"
echo "las claves de cifrado. Si KeyStreamLen == 0, no envía el paquete."
echo ""
echo "Esto puede causar problemas si:"
echo "  - El cliente espera recibir el paquete de cifrado"
echo "  - El cliente y servidor no están sincronizados en el cifrado"
echo ""

echo "═══════════════════════════════════════════"
echo "3. POSIBLES SOLUCIONES"
echo "═══════════════════════════════════════════"
echo ""

if [ "$CRYPT_COUNT" -eq 0 ]; then
    echo "❌ No hay archivos cshybridcrypt*"
    echo ""
    echo "OPCIÓN A: Los archivos están dentro de los .eix/.epk"
    echo "  - Necesitarías herramientas de extracción de Metin2"
    echo "  - Busca 'Metin2 Package Extractor' o similar"
    echo ""
    echo "OPCIÓN B: El cliente no usa cifrado híbrido"
    echo "  - Tu versión del cliente puede ser antigua"
    echo "  - El servidor puede funcionar sin estos archivos"
    echo "  - PERO puede haber problemas de sincronización"
    echo ""
    echo "OPCIÓN C: Deshabilitar verificación de cifrado (NO RECOMENDADO)"
    echo "  - Modificar el código del servidor"
    echo "  - Puede causar problemas de seguridad"
    echo ""
    echo "OPCIÓN D: Usar un cliente compatible"
    echo "  - Buscar un cliente que incluya los archivos cshybridcrypt*"
    echo "  - O usar una versión del servidor compatible con tu cliente"
else
    echo "✅ Hay archivos cshybridcrypt*, pero el servidor no los carga"
    echo ""
    echo "Verifica:"
    echo "  1. Permisos de lectura"
    echo "  2. Formato de los archivos"
    echo "  3. Logs de error específicos"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "4. VERIFICACIÓN DE ERRORES DE SEQUENCE"
echo "═══════════════════════════════════════════"
echo ""

if [ "$SEQUENCE_ERRORS" -gt 0 ]; then
    echo "⚠️ Se encontraron $SEQUENCE_ERRORS errores de SEQUENCE"
    echo ""
    echo "Últimos errores:"
    docker logs metin2-server 2>&1 | grep "SEQUENCE.*mismatch" | tail -3
    echo ""
    echo "Estos errores indican que:"
    echo "  - El cliente y servidor no están sincronizados en el cifrado"
    echo "  - Puede ser por falta de archivos cshybridcrypt*"
    echo "  - O por incompatibilidad de versión"
else
    echo "✅ No se encontraron errores de SEQUENCE recientes"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "5. RECOMENDACIONES"
echo "═══════════════════════════════════════════"
echo ""

if [ "$CRYPT_COUNT" -eq 0 ] && [ "$SEQUENCE_ERRORS" -gt 0 ]; then
    echo "1. Intenta extraer los archivos de los .eix/.epk del cliente"
    echo "2. Busca herramientas de extracción de Metin2"
    echo "3. Verifica si tu cliente genera estos archivos al ejecutarse"
    echo "4. Considera usar un cliente diferente o actualizar el servidor"
elif [ "$CRYPT_COUNT" -gt 0 ] && [ "$FAILED_LOAD" -gt 0 ]; then
    echo "1. Verifica los permisos de los archivos"
    echo "2. Verifica el formato de los archivos (pueden estar corruptos)"
    echo "3. Revisa los logs completos: docker logs metin2-server | grep -i crypt"
else
    echo "El problema puede ser otro. Revisa los logs completos del servidor."
fi

echo ""
echo "═══════════════════════════════════════════"
echo "RESUMEN"
echo "═══════════════════════════════════════════"
echo ""
echo "Archivos cshybridcrypt*: $CRYPT_COUNT"
echo "Errores de carga: $FAILED_LOAD"
echo "Errores de SEQUENCE: $SEQUENCE_ERRORS"
echo ""

