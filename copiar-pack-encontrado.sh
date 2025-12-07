#!/bin/bash
# Script para buscar y copiar pack/ al contenedor

echo "=========================================="
echo "Buscar y copiar pack/ al contenedor"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Buscando carpeta pack/..."
PACK_DIR=$(find Client-20251206T130044Z-3-001 -type d -name "pack" 2>/dev/null | head -1)

if [ -z "$PACK_DIR" ]; then
    echo "⚠️ No se encontró carpeta pack/ con find"
    echo ""
    echo "Buscando manualmente en rutas comunes..."
    
    # Intentar rutas comunes
    RUTAS=(
        "Client-20251206T130044Z-3-001/Client/Client/Client/pack"
        "Client/Client/Client/pack"
        "Client-20251206T130044Z-3-001/Client/pack"
    )
    
    for ruta in "${RUTAS[@]}"; do
        if [ -d "$ruta" ]; then
            PACK_DIR="$ruta"
            echo "✅ Encontrada en: $PACK_DIR"
            break
        fi
    done
fi

if [ -z "$PACK_DIR" ] || [ ! -d "$PACK_DIR" ]; then
    echo "❌ Carpeta pack/ no encontrada"
    echo ""
    echo "Buscando archivos .eix o .epk para ubicar pack/:"
    find Client-20251206T130044Z-3-001 -type f \( -name "*.eix" -o -name "*.epk" \) 2>/dev/null | head -3 | while read file; do
        echo "   Archivo encontrado: $file"
        echo "   Directorio padre: $(dirname "$file")"
    done
    exit 1
fi

echo "✅ Carpeta pack/ encontrada: $PACK_DIR"
echo ""

echo "2. Verificando contenido (primeros 10 archivos):"
ls -lh "$PACK_DIR" | head -10

echo ""
echo "3. Contando archivos en pack/:"
FILE_COUNT=$(find "$PACK_DIR" -type f | wc -l)
echo "   Total: $FILE_COUNT archivos"

echo ""
echo "4. Creando carpeta package/ en el contenedor..."
docker exec metin2-server mkdir -p /app/package 2>/dev/null || true

echo ""
echo "5. Copiando archivos al contenedor..."
docker cp "$PACK_DIR/." metin2-server:/app/package/ 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Archivos copiados exitosamente"
else
    echo "❌ Error al copiar archivos"
    exit 1
fi

echo ""
echo "6. Verificando archivos en el contenedor (primeros 10):"
docker exec metin2-server ls -la /app/package 2>/dev/null | head -10

echo ""
echo "7. Contando archivos copiados:"
CONTAINER_COUNT=$(docker exec metin2-server find /app/package -type f 2>/dev/null | wc -l)
echo "   Total en contenedor: $CONTAINER_COUNT archivos"

echo ""
echo "8. Reiniciando contenedor..."
docker restart metin2-server

echo ""
echo "✅ Proceso completado!"
echo ""
echo "Espera 30 segundos y verifica los logs:"
echo "   docker logs --tail 50 metin2-server | grep -i package"
echo ""
echo "Si ya no ves 'Failed to Load ClientPackageCryptInfo Files',"
echo "entonces los archivos se cargaron correctamente."

