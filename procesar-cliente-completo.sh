#!/bin/bash
# Script para procesar Client-20251206T130044Z-3-001.zip y extraer pack/

echo "=========================================="
echo "Procesar cliente completo y extraer pack/"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Buscar el archivo ZIP
ZIP_FILE=""
if [ -f "Client-20251206T130044Z-3-001.zip" ]; then
    ZIP_FILE="Client-20251206T130044Z-3-001.zip"
    echo "✅ Archivo encontrado: $ZIP_FILE"
elif [ -f "Client-20251206T130044Z-3-001/Client/Client/Client/pack" ]; then
    echo "✅ Carpeta pack/ ya existe en el directorio"
    PACK_DIR="Client-20251206T130044Z-3-001/Client/Client/Client/pack"
else
    echo "❌ No se encontró el archivo ZIP ni la carpeta pack/"
    echo ""
    echo "Buscando archivos relacionados..."
    ls -lh Client*.zip 2>/dev/null | head -5
    exit 1
fi

# Si tenemos el ZIP, extraerlo
if [ -n "$ZIP_FILE" ]; then
    echo ""
    echo "1. Extrayendo $ZIP_FILE..."
    unzip -q "$ZIP_FILE" 2>/dev/null || {
        echo "❌ Error al extraer. Verificando si unzip está instalado..."
        if ! command -v unzip &> /dev/null; then
            echo "Instalando unzip..."
            apt-get update && apt-get install -y unzip 2>/dev/null || \
            yum install -y unzip 2>/dev/null || \
            echo "⚠️ No se pudo instalar unzip. Instálalo manualmente."
            exit 1
        fi
        unzip -q "$ZIP_FILE" || {
            echo "❌ Error al extraer el archivo ZIP"
            exit 1
        }
    }
    echo "✅ Archivo extraído"
fi

echo ""
echo "2. Buscando carpeta pack/..."
PACK_DIR=""
if [ -d "Client-20251206T130044Z-3-001/Client/Client/Client/pack" ]; then
    PACK_DIR="Client-20251206T130044Z-3-001/Client/Client/Client/pack"
    echo "✅ Carpeta pack/ encontrada: $PACK_DIR"
elif [ -d "./pack" ]; then
    PACK_DIR="./pack"
    echo "✅ Carpeta pack/ encontrada en el directorio actual"
else
    echo "⚠️ Carpeta pack/ no encontrada. Buscando..."
    find Client-20251206T130044Z-3-001 -type d -name "pack" 2>/dev/null | head -5
    exit 1
fi

echo ""
echo "3. Verificando contenido de pack/ (primeros 10 archivos):"
ls -lh "$PACK_DIR" | head -10

echo ""
echo "4. Creando carpeta package/ en el contenedor..."
docker exec metin2-server mkdir -p /app/package 2>/dev/null || true

echo ""
echo "5. Copiando archivos al contenedor..."
docker cp "$PACK_DIR/." metin2-server:/app/package/ 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Archivos copiados exitosamente al contenedor"
else
    echo "❌ Error al copiar archivos al contenedor"
    exit 1
fi

echo ""
echo "6. Verificando archivos en el contenedor (primeros 10):"
docker exec metin2-server ls -la /app/package 2>/dev/null | head -10

echo ""
echo "7. Contando archivos copiados:"
FILE_COUNT=$(docker exec metin2-server find /app/package -type f 2>/dev/null | wc -l)
echo "   Total de archivos: $FILE_COUNT"

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
echo ""
echo "Luego intenta conectarte desde el cliente y verifica:"
echo "   docker logs -f metin2-server | grep -E 'AuthLogin|LOGIN_BY_KEY|PHASE_SELECT'"

