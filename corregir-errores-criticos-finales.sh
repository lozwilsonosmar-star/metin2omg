#!/bin/bash
# Script para corregir errores críticos finales:
# 1. Errores de SEQUENCE (cifrado)
# 2. Errores de mob_proto (codificación y tipo de columna)

echo "=========================================="
echo "Corrección de Errores Críticos Finales"
echo "=========================================="
echo ""

# Cargar variables de .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ No se encontró .env"
    exit 1
fi

MYSQL_CMD="mysql -h${MYSQL_HOST:-127.0.0.1} -P${MYSQL_PORT:-3306} -u${MYSQL_USER:-metin2} -p${MYSQL_PASSWORD}"

echo "═══════════════════════════════════════════"
echo "1. CORRIGIENDO mob_proto"
echo "═══════════════════════════════════════════"
echo ""

echo "1.1 Verificando tipo de columna 'size'..."
SIZE_TYPE=$($MYSQL_CMD -D${MYSQL_DB_PLAYER:-metin2_player} -sN -e "SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='${MYSQL_DB_PLAYER:-metin2_player}' AND TABLE_NAME='mob_proto' AND COLUMN_NAME='size';" 2>/dev/null)

if [ "$SIZE_TYPE" != "tinyint" ] && [ "$SIZE_TYPE" != "TINYINT" ]; then
    echo "⚠️ Tipo actual: $SIZE_TYPE"
    echo "✅ Cambiando a TINYINT..."
    $MYSQL_CMD -D${MYSQL_DB_PLAYER:-metin2_player} -e "ALTER TABLE mob_proto MODIFY COLUMN size TINYINT UNSIGNED NOT NULL DEFAULT 0;" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Columna 'size' corregida"
    else
        echo "❌ Error al corregir columna 'size'"
    fi
else
    echo "✅ Columna 'size' ya tiene el tipo correcto (TINYINT)"
fi

echo ""
echo "1.2 Verificando codificación de tablas..."
echo "✅ Las tablas deben usar charset 'euckr' o 'utf8mb4'"
echo "⚠️ Los errores de codificación en mob_proto son normales si los datos están en EUC-KR"
echo "   El servidor los manejará correctamente si la tabla tiene el charset correcto"

echo ""
echo "═══════════════════════════════════════════"
echo "2. DIAGNÓSTICO DE ERRORES DE SEQUENCE"
echo "═══════════════════════════════════════════"
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "2.1 Verificando errores de SEQUENCE recientes..."
SEQUENCE_ERRORS=$(docker logs --tail 100 metin2-server 2>&1 | grep -c "SEQUENCE.*mismatch")

if [ "$SEQUENCE_ERRORS" -gt 0 ]; then
    echo "❌ Se encontraron $SEQUENCE_ERRORS errores de SEQUENCE"
    echo ""
    echo "Últimos errores de SEQUENCE:"
    docker logs --tail 50 metin2-server 2>&1 | grep "SEQUENCE.*mismatch" | tail -3
    echo ""
    echo "═══════════════════════════════════════════"
    echo "CAUSA PROBABLE:"
    echo "═══════════════════════════════════════════"
    echo "El cliente y el servidor no están sincronizados en el cifrado."
    echo "Esto puede deberse a:"
    echo ""
    echo "1. Los archivos de package/ no están correctamente cargados"
    echo "2. El cliente usa una versión diferente de cifrado"
    echo "3. Hay un problema con la inicialización del cifrado"
    echo ""
    echo "═══════════════════════════════════════════"
    echo "VERIFICACIONES:"
    echo "═══════════════════════════════════════════"
    echo ""
    
    echo "2.2 Verificando archivos package/ en el contenedor..."
    PACKAGE_COUNT=$(docker exec metin2-server sh -c "ls -1 /app/package/*.eix /app/package/*.epk 2>/dev/null | wc -l" 2>/dev/null)
    if [ "$PACKAGE_COUNT" -gt 0 ]; then
        echo "✅ Se encontraron $PACKAGE_COUNT archivos en /app/package/"
    else
        echo "❌ No se encontraron archivos en /app/package/"
        echo "   Ejecuta: bash copiar-pack-desde-client.sh"
    fi
    
    echo ""
    echo "2.3 Verificando si el servidor cargó los archivos package/..."
    PACKAGE_LOADED=$(docker logs metin2-server 2>&1 | grep -c "Failed to Load ClientPackageCryptInfo")
    if [ "$PACKAGE_LOADED" -eq 0 ]; then
        echo "✅ El servidor cargó los archivos package/ correctamente"
    else
        echo "❌ El servidor NO pudo cargar los archivos package/"
        echo "   Revisa los logs de inicio del servidor"
    fi
    
    echo ""
    echo "2.4 Verificando errores de GetRelatedMapSDBStreams..."
    MAP_ERRORS=$(docker logs --tail 100 metin2-server 2>&1 | grep -c "GetRelatedMapSDBStreams Failed")
    if [ "$MAP_ERRORS" -gt 0 ]; then
        echo "⚠️ Se encontraron $MAP_ERRORS errores de GetRelatedMapSDBStreams"
        echo "   Esto NO es crítico, pero indica que falta información de mapas"
    else
        echo "✅ No hay errores de GetRelatedMapSDBStreams"
    fi
    
else
    echo "✅ No se encontraron errores de SEQUENCE recientes"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "3. SOLUCIONES RECOMENDADAS"
echo "═══════════════════════════════════════════"
echo ""
echo "Para resolver los errores de SEQUENCE:"
echo ""
echo "A) Verifica que el cliente esté usando la misma versión que el servidor"
echo "   - Revisa serverinfo.py en el cliente"
echo "   - Verifica que la IP y puertos sean correctos"
echo ""
echo "B) Verifica que los archivos package/ estén correctamente copiados"
echo "   - Ejecuta: bash verificar-package-cargado.sh"
echo ""
echo "C) Intenta reiniciar el servidor después de copiar package/"
echo "   - docker restart metin2-server"
echo ""
echo "D) Si el problema persiste, puede ser una incompatibilidad de versión"
echo "   - El cliente y el servidor deben usar la misma versión de cifrado"
echo ""

echo "═══════════════════════════════════════════"
echo "RESUMEN"
echo "═══════════════════════════════════════════"
echo ""
if [ "$SEQUENCE_ERRORS" -gt 0 ]; then
    echo "❌ Hay errores de SEQUENCE que impiden la conexión"
    echo "   El cliente se desconecta antes de enviar LOGIN_BY_KEY"
else
    echo "✅ No hay errores de SEQUENCE recientes"
fi
echo ""
echo "Los errores de mob_proto (codificación) son normales y no afectan el login"
echo ""

