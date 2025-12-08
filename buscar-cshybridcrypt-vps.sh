#!/bin/bash
# Script para buscar archivos cshybridcrypt en el VPS

echo "=========================================="
echo "Búsqueda de Archivos cshybridcrypt en VPS"
echo "=========================================="
echo ""

echo "Buscando archivos 'cshybridcrypt*' en el sistema..."
echo ""

# Buscar en ubicaciones comunes
SEARCH_PATHS=(
    "/opt"
    "/root"
    "/home"
    "/tmp"
    "/var/tmp"
    "/opt/metin2omg"
)

FOUND=0

for path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "Buscando en: $path"
        FILES=$(find "$path" -name "cshybridcrypt*" -type f 2>/dev/null)
        if [ -n "$FILES" ]; then
            echo "   ✅ ENCONTRADOS:"
            echo "$FILES" | while read line; do
                if [ -n "$line" ]; then
                    SIZE=$(ls -lh "$line" 2>/dev/null | awk '{print $5}')
                    echo "      - $line ($SIZE)"
                    FOUND=1
                fi
            done
        fi
    fi
done

echo ""
if [ $FOUND -eq 0 ]; then
    echo "❌ No se encontraron archivos 'cshybridcrypt*' en el VPS"
    echo ""
    echo "═══════════════════════════════════════════"
    echo "INSTRUCCIONES"
    echo "═══════════════════════════════════════════"
    echo ""
    echo "Los archivos NO están en el VPS. Necesitas buscarlos en tu"
    echo "cliente de Windows y copiarlos aquí."
    echo ""
    echo "PASOS:"
    echo ""
    echo "1. En tu Windows, abre PowerShell o CMD en el directorio del cliente"
    echo ""
    echo "2. Busca los archivos:"
    echo "   PowerShell:"
    echo "   Get-ChildItem -Path . -Filter 'cshybridcrypt*' -Recurse"
    echo ""
    echo "   CMD:"
    echo "   dir /s cshybridcrypt*"
    echo ""
    echo "3. Si los encuentras, cópialos al VPS usando SCP o FileZilla:"
    echo "   scp cshybridcrypt* root@TU_VPS_IP:/tmp/"
    echo ""
    echo "4. Luego ejecuta en el VPS:"
    echo "   docker cp /tmp/cshybridcrypt* metin2-server:/app/package/"
    echo "   docker restart metin2-server"
    echo ""
else
    echo "✅ Se encontraron archivos. Copiando al contenedor..."
    echo ""
    for file in $FILES; do
        if [ -n "$file" ]; then
            FILENAME=$(basename "$file")
            echo "Copiando $FILENAME..."
            docker cp "$file" metin2-server:/app/package/ 2>/dev/null && echo "   ✅ Copiado" || echo "   ❌ Error"
        fi
    done
    echo ""
    echo "Reiniciando servidor..."
    docker restart metin2-server
    echo "✅ Servidor reiniciado"
fi

echo ""

