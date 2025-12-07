#!/bin/bash
# Script para explorar la estructura del cliente extraído

echo "=========================================="
echo "Explorar estructura del cliente"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Estructura del directorio raíz:"
ls -la Client-20251206T130044Z-3-001/ 2>/dev/null | head -20

echo ""
echo "2. Buscando cualquier carpeta que contenga 'pack' o 'package':"
find Client-20251206T130044Z-3-001 -type d \( -iname "*pack*" -o -iname "*package*" \) 2>/dev/null

echo ""
echo "3. Buscando archivos .eix o .epk (archivos de pack/):"
find Client-20251206T130044Z-3-001 -type f \( -name "*.eix" -o -name "*.epk" \) 2>/dev/null | head -5 | while read file; do
    echo "   Archivo: $file"
    echo "   Directorio: $(dirname "$file")"
    echo ""
done

echo ""
echo "4. Explorando Client/ si existe:"
if [ -d "Client-20251206T130044Z-3-001/Client" ]; then
    echo "   Contenido de Client/:"
    ls -la Client-20251206T130044Z-3-001/Client/ 2>/dev/null | head -15
    
    if [ -d "Client-20251206T130044Z-3-001/Client/Client" ]; then
        echo ""
        echo "   Contenido de Client/Client/:"
        ls -la Client-20251206T130044Z-3-001/Client/Client/ 2>/dev/null | head -15
        
        if [ -d "Client-20251206T130044Z-3-001/Client/Client/Client" ]; then
            echo ""
            echo "   Contenido de Client/Client/Client/:"
            ls -la Client-20251206T130044Z-3-001/Client/Client/Client/ 2>/dev/null | head -20
        fi
    fi
fi

echo ""
echo "5. Buscando en toda la estructura (primeros 30 directorios):"
find Client-20251206T130044Z-3-001 -type d 2>/dev/null | head -30

echo ""
echo "6. Si encuentras la carpeta pack/, ejecuta:"
echo "   docker exec metin2-server mkdir -p /app/package"
echo "   docker cp RUTA_COMPLETA/. metin2-server:/app/package/"
echo "   docker restart metin2-server"

