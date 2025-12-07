#!/bin/bash
# Script para buscar la carpeta pack/ después de extraer

echo "=========================================="
echo "Buscando carpeta pack/ extraída"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Buscando carpeta pack/ en todo el directorio extraído:"
find Client-20251206T130044Z-3-001 -type d -name "pack" 2>/dev/null

echo ""
echo "2. Listando estructura del directorio extraído:"
ls -la Client-20251206T130044Z-3-001/ 2>/dev/null | head -10

echo ""
echo "3. Buscando en Client/Client/Client:"
if [ -d "Client-20251206T130044Z-3-001/Client" ]; then
    ls -la Client-20251206T130044Z-3-001/Client/ 2>/dev/null | head -10
    if [ -d "Client-20251206T130044Z-3-001/Client/Client" ]; then
        ls -la Client-20251206T130044Z-3-001/Client/Client/ 2>/dev/null | head -10
        if [ -d "Client-20251206T130044Z-3-001/Client/Client/Client" ]; then
            ls -la Client-20251206T130044Z-3-001/Client/Client/Client/ 2>/dev/null | head -20
        fi
    fi
fi

echo ""
echo "4. Buscando cualquier carpeta que contenga 'pack' en el nombre:"
find Client-20251206T130044Z-3-001 -type d -iname "*pack*" 2>/dev/null | head -10

echo ""
echo "5. Buscando archivos .eix o .epk (archivos típicos de pack/):"
find Client-20251206T130044Z-3-001 -type f \( -name "*.eix" -o -name "*.epk" \) 2>/dev/null | head -5

echo ""
echo "6. Si encontraste la carpeta pack/, ejecuta:"
echo "   docker exec metin2-server mkdir -p /app/package"
echo "   docker cp RUTA_ENCONTRADA/. metin2-server:/app/package/"
echo "   docker restart metin2-server"

