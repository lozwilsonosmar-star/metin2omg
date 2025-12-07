#!/bin/bash
# Script para extraer ZIPs anidados y buscar pack/

echo "=========================================="
echo "Extraer ZIPs anidados y buscar pack/"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Buscando archivos ZIP dentro del directorio extraído:"
find Client-20251206T130044Z-3-001 -name "*.zip" -type f 2>/dev/null

echo ""
echo "2. Extrayendo Client.zip si existe..."
if [ -f "Client-20251206T130044Z-3-001/Client/Client.zip" ]; then
    echo "   Encontrado: Client/Client.zip"
    cd Client-20251206T130044Z-3-001/Client
    unzip -o -q Client.zip 2>/dev/null
    cd /opt/metin2omg
    echo "   ✅ Extraído"
elif [ -f "Client/Client.zip" ]; then
    echo "   Encontrado: Client/Client.zip"
    cd Client
    unzip -o -q Client.zip 2>/dev/null
    cd /opt/metin2omg
    echo "   ✅ Extraído"
fi

echo ""
echo "3. Buscando carpeta pack/ después de extraer ZIPs anidados:"
PACK_DIR=$(find Client-20251206T130044Z-3-001 -type d -name "pack" 2>/dev/null | head -1)

if [ -z "$PACK_DIR" ]; then
    # Buscar en rutas comunes
    RUTAS=(
        "Client-20251206T130044Z-3-001/Client/Client/Client/pack"
        "Client/Client/Client/pack"
        "Client-20251206T130044Z-3-001/Client/pack"
    )
    
    for ruta in "${RUTAS[@]}"; do
        if [ -d "$ruta" ]; then
            PACK_DIR="$ruta"
            break
        fi
    done
fi

if [ -n "$PACK_DIR" ] && [ -d "$PACK_DIR" ]; then
    echo "✅ Carpeta pack/ encontrada: $PACK_DIR"
    echo ""
    echo "4. Verificando contenido (primeros 10 archivos):"
    ls -lh "$PACK_DIR" | head -10
    echo ""
    echo "5. Copiando al contenedor..."
    docker exec metin2-server mkdir -p /app/package 2>/dev/null || true
    docker cp "$PACK_DIR/." metin2-server:/app/package/ 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Archivos copiados exitosamente"
        echo ""
        echo "6. Reiniciando contenedor..."
        docker restart metin2-server
        echo "✅ Contenedor reiniciado"
        echo ""
        echo "Espera 30 segundos y verifica:"
        echo "   docker logs --tail 50 metin2-server | grep -i package"
    else
        echo "❌ Error al copiar archivos"
    fi
else
    echo "❌ Carpeta pack/ aún no encontrada"
    echo ""
    echo "Buscando archivos .eix o .epk para ubicar pack/:"
    find Client-20251206T130044Z-3-001 -type f \( -name "*.eix" -o -name "*.epk" \) 2>/dev/null | head -3 | while read file; do
        echo "   Archivo: $file"
        echo "   Directorio: $(dirname "$file")"
    done
    echo ""
    echo "Si no encuentra archivos, puede que pack/ esté en otro ZIP."
    echo "Verifica manualmente la estructura del cliente."
fi

