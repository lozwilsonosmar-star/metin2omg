#!/bin/bash
# Script para verificar archivos de cifrado necesarios

echo "=========================================="
echo "Verificación de Archivos de Cifrado"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "═══════════════════════════════════════════"
echo "1. ARCHIVOS QUE EL SERVIDOR BUSCA"
echo "═══════════════════════════════════════════"
echo ""
echo "El servidor busca archivos que contengan 'cshybridcrypt' en el nombre"
echo "Estos archivos NO son .eix o .epk, son archivos especiales de cifrado"
echo ""

echo "1.1 Buscando archivos 'cshybridcrypt*' en /app/package/..."
CRYPT_FILES=$(docker exec metin2-server sh -c "ls -1 /app/package/cshybridcrypt* 2>/dev/null" 2>/dev/null)
CRYPT_COUNT=$(docker exec metin2-server sh -c "ls -1 /app/package/cshybridcrypt* 2>/dev/null | wc -l" 2>/dev/null)

if [ "$CRYPT_COUNT" -gt 0 ]; then
    echo "✅ Se encontraron $CRYPT_COUNT archivos de cifrado:"
    echo "$CRYPT_FILES" | while read line; do
        if [ -n "$line" ]; then
            SIZE=$(docker exec metin2-server sh -c "ls -lh '$line' 2>/dev/null | awk '{print \$5}'" 2>/dev/null)
            echo "   - $(basename $line) ($SIZE)"
        fi
    done
else
    echo "❌ NO se encontraron archivos 'cshybridcrypt*'"
    echo ""
    echo "   Este es el problema: el servidor necesita estos archivos para cargar el cifrado"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "2. ARCHIVOS ACTUALES EN /app/package/"
echo "═══════════════════════════════════════════"
echo ""

echo "2.1 Listando TODOS los archivos en /app/package/ (primeros 20)..."
docker exec metin2-server sh -c "ls -1 /app/package/ 2>/dev/null | head -20" 2>/dev/null

echo ""
echo "2.2 Contando tipos de archivos..."
EIX_COUNT=$(docker exec metin2-server sh -c "ls -1 /app/package/*.eix 2>/dev/null | wc -l" 2>/dev/null)
EPK_COUNT=$(docker exec metin2-server sh -c "ls -1 /app/package/*.epk 2>/dev/null | wc -l" 2>/dev/null)
TOTAL_FILES=$(docker exec metin2-server sh -c "ls -1 /app/package/ 2>/dev/null | wc -l" 2>/dev/null)

echo "   Archivos .eix: $EIX_COUNT"
echo "   Archivos .epk: $EPK_COUNT"
echo "   Total archivos: $TOTAL_FILES"

echo ""
echo "═══════════════════════════════════════════"
echo "3. DIAGNÓSTICO"
echo "═══════════════════════════════════════════"
echo ""

if [ "$CRYPT_COUNT" -eq 0 ]; then
    echo "❌ PROBLEMA IDENTIFICADO:"
    echo ""
    echo "   El servidor NO puede cargar los archivos porque faltan los archivos"
    echo "   de cifrado 'cshybridcrypt*'."
    echo ""
    echo "   Los archivos .eix y .epk son del cliente, pero el servidor necesita"
    echo "   archivos especiales de cifrado que generalmente se generan o extraen"
    echo "   del cliente."
    echo ""
    echo "═══════════════════════════════════════════"
    echo "4. SOLUCIÓN"
    echo "═══════════════════════════════════════════"
    echo ""
    echo "Necesitas encontrar y copiar los archivos 'cshybridcrypt*' del cliente."
    echo ""
    echo "Estos archivos generalmente están en:"
    echo "   - El directorio 'package/' del cliente"
    echo "   - O en el directorio raíz del cliente"
    echo ""
    echo "Para copiarlos:"
    echo "   1. Encuentra los archivos 'cshybridcrypt*' en tu cliente"
    echo "   2. Cópialos al contenedor:"
    echo "      docker cp /ruta/local/cshybridcrypt* metin2-server:/app/package/"
    echo "   3. Reinicia el servidor:"
    echo "      docker restart metin2-server"
    echo ""
    echo "O si están en el VPS:"
    echo "   docker cp /ruta/vps/cshybridcrypt* metin2-server:/app/package/"
else
    echo "✅ Los archivos de cifrado están presentes"
    echo ""
    echo "Si el servidor aún no los carga, verifica:"
    echo "   1. Permisos de lectura: docker exec metin2-server ls -l /app/package/cshybridcrypt*"
    echo "   2. Logs del servidor: docker logs metin2-server | grep -i 'crypt\|package'"
    echo "   3. Formato de los archivos (pueden estar corruptos)"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "RESUMEN"
echo "═══════════════════════════════════════════"
echo ""
echo "Archivos cshybridcrypt* encontrados: $CRYPT_COUNT"
echo "Archivos .eix: $EIX_COUNT"
echo "Archivos .epk: $EPK_COUNT"
echo ""

