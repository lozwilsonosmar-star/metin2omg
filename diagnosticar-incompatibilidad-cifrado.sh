#!/bin/bash
# Script para diagnosticar incompatibilidad de cifrado entre cliente y servidor

echo "=========================================="
echo "Diagnóstico de Incompatibilidad de Cifrado"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "═══════════════════════════════════════════"
echo "1. INFORMACIÓN CLAVE"
echo "═══════════════════════════════════════════"
echo ""
echo "⚠️ IMPORTANTE:"
echo "   ShybridCrypt NO es un archivo separado."
echo "   Está EMBEBIDO en metin2client.exe"
echo ""
echo "   Los archivos 'cshybridcrypt*' que el servidor busca son"
echo "   archivos de CONFIGURACIÓN/INFORMACIÓN para sincronizar"
echo "   el cifrado con el cliente."
echo ""

echo "═══════════════════════════════════════════"
echo "2. ESTADO ACTUAL DEL SERVIDOR"
echo "═══════════════════════════════════════════"
echo ""

# Verificar archivos en package/
echo "2.1 Archivos en /app/package/:"
PACKAGE_FILES=$(docker exec metin2-server sh -c "ls -1 /app/package/ 2>/dev/null | head -20" 2>/dev/null)
if [ -n "$PACKAGE_FILES" ]; then
    echo "$PACKAGE_FILES"
else
    echo "   (vacío o no accesible)"
fi

echo ""
echo "2.2 Buscando archivos relacionados con cifrado:"
CRYPT_RELATED=$(docker exec metin2-server sh -c "ls -1 /app/package/*crypt* /app/package/*sdb* /app/package/*.enc 2>/dev/null" 2>/dev/null)
if [ -n "$CRYPT_RELATED" ]; then
    echo "$CRYPT_RELATED"
else
    echo "   ❌ No se encontraron archivos relacionados con cifrado"
fi

echo ""
echo "2.3 Verificando logs de carga:"
FAILED_LOAD=$(docker logs metin2-server 2>&1 | grep -c "Failed to Load ClientPackageCryptInfo")
if [ "$FAILED_LOAD" -gt 0 ]; then
    echo "   ❌ El servidor NO pudo cargar archivos de cifrado ($FAILED_LOAD veces)"
    echo ""
    echo "   Último mensaje:"
    docker logs metin2-server 2>&1 | grep "Failed to Load ClientPackageCryptInfo" | tail -1
else
    echo "   ✅ No se encontró el mensaje de error"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "3. ERRORES DE SEQUENCE"
echo "═══════════════════════════════════════════"
echo ""

SEQUENCE_ERRORS=$(docker logs metin2-server 2>&1 | grep -c "SEQUENCE.*mismatch")
if [ "$SEQUENCE_ERRORS" -gt 0 ]; then
    echo "❌ Se encontraron $SEQUENCE_ERRORS errores de SEQUENCE"
    echo ""
    echo "   Esto indica INCOMPATIBILIDAD de cifrado entre cliente y servidor"
    echo ""
    echo "   Últimos errores:"
    docker logs metin2-server 2>&1 | grep "SEQUENCE.*mismatch" | tail -3
else
    echo "✅ No se encontraron errores de SEQUENCE"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "4. ERRORES DE SDB"
echo "═══════════════════════════════════════════"
echo ""

SDB_ERRORS=$(docker logs metin2-server 2>&1 | grep -c "GetRelatedMapSDBStreams Failed")
if [ "$SDB_ERRORS" -gt 0 ]; then
    echo "⚠️ Se encontraron $SDB_ERRORS errores de SDB"
    echo "   Esto indica que faltan datos de mapas"
else
    echo "✅ No se encontraron errores de SDB"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "5. DIAGNÓSTICO"
echo "═══════════════════════════════════════════"
echo ""

if [ "$SEQUENCE_ERRORS" -gt 0 ]; then
    echo "❌ PROBLEMA CONFIRMADO: Incompatibilidad de cifrado"
    echo ""
    echo "Causa:"
    echo "  - El cliente y el servidor usan versiones diferentes de ShybridCrypt"
    echo "  - El cliente está cifrando con claves que el servidor no reconoce"
    echo "  - O viceversa"
    echo ""
    echo "Esto NO se soluciona copiando archivos porque:"
    echo "  - ShybridCrypt está embebido en metin2client.exe"
    echo "  - Los archivos cshybridcrypt* son solo de configuración"
    echo "  - El problema es la incompatibilidad de versión"
else
    echo "⚠️ No hay errores de SEQUENCE aún, pero puede haber otros problemas"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "6. SOLUCIONES POSIBLES"
echo "═══════════════════════════════════════════"
echo ""

echo "OPCIÓN A: Usar un cliente compatible"
echo "  - Buscar un cliente que use la misma versión de ShybridCrypt"
echo "  - Generalmente clientes de la misma época que el servidor"
echo "  - Verificar la versión del servidor (revisar commits/fechas)"
echo ""

echo "OPCIÓN B: Modificar el servidor para deshabilitar verificación"
echo "  - NO RECOMENDADO - puede causar problemas de seguridad"
echo "  - Requiere modificar el código fuente"
echo ""

echo "OPCIÓN C: Generar archivos de configuración de cifrado"
echo "  - Si el servidor los necesita, pueden generarse"
echo "  - Requiere herramientas especializadas"
echo "  - O extraerlos de un cliente compatible"
echo ""

echo "OPCIÓN D: Verificar versión del servidor"
echo "  - Revisar el código fuente para ver qué versión de cliente espera"
echo "  - Buscar en los commits o documentación"
echo ""

echo "═══════════════════════════════════════════"
echo "7. INFORMACIÓN NECESARIA PARA DIAGNÓSTICO"
echo "═══════════════════════════════════════════"
echo ""

echo "Para un diagnóstico más preciso, necesitarías:"
echo ""
echo "1. Versión del cliente (fecha de compilación, versión del ejecutable)"
echo "2. Lista completa de archivos en pack/package/ del cliente"
echo "3. Logs completos del servidor durante un intento de conexión"
echo "4. Versión del servidor (revisar git log o documentación)"
echo ""

echo "═══════════════════════════════════════════"
echo "RESUMEN"
echo "═══════════════════════════════════════════"
echo ""
echo "Errores de SEQUENCE: $SEQUENCE_ERRORS"
echo "Errores de SDB: $SDB_ERRORS"
echo "Archivos de cifrado cargados: $([ "$FAILED_LOAD" -eq 0 ] && echo "✅ Sí" || echo "❌ No")"
echo ""
echo "Conclusión:"
if [ "$SEQUENCE_ERRORS" -gt 0 ]; then
    echo "  ❌ Hay incompatibilidad de cifrado entre cliente y servidor"
    echo "  → Necesitas un cliente compatible o modificar el servidor"
else
    echo "  ⚠️ No hay errores de SEQUENCE, pero verifica otros problemas"
fi
echo ""

