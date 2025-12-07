#!/bin/bash
# Script para procesar pack.tar.gz subido por FileZilla

echo "=========================================="
echo "Procesar pack.tar.gz subido"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Buscar el archivo pack.tar.gz
if [ -f "pack.tar.gz" ]; then
    echo "✅ Archivo pack.tar.gz encontrado"
    echo ""
    
    # Verificar tamaño del archivo
    SIZE=$(du -h pack.tar.gz | cut -f1)
    echo "Tamaño: $SIZE"
    echo ""
    
    # Extraer el archivo
    echo "1. Extrayendo pack.tar.gz..."
    tar -xzf pack.tar.gz
    if [ $? -eq 0 ]; then
        echo "✅ Archivo extraído correctamente"
    else
        echo "❌ Error al extraer el archivo"
        exit 1
    fi
    
    echo ""
    echo "2. Verificando carpeta pack/ extraída..."
    if [ -d "pack" ]; then
        echo "✅ Carpeta pack/ encontrada"
        echo ""
        echo "Contenido (primeros 10 archivos):"
        ls -lh pack/ | head -10
    else
        echo "⚠️ Carpeta pack/ no encontrada después de extraer"
        echo "Buscando estructura..."
        find . -type d -name "pack" 2>/dev/null | head -5
        exit 1
    fi
    
    echo ""
    echo "3. Creando carpeta package/ en el contenedor..."
    docker exec metin2-server mkdir -p /app/package 2>/dev/null || true
    
    echo ""
    echo "4. Copiando archivos al contenedor..."
    docker cp pack/. metin2-server:/app/package/ 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Archivos copiados exitosamente al contenedor"
    else
        echo "❌ Error al copiar archivos al contenedor"
        exit 1
    fi
    
    echo ""
    echo "5. Verificando archivos en el contenedor..."
    docker exec metin2-server ls -la /app/package 2>/dev/null | head -10
    
    echo ""
    echo "6. Reiniciando contenedor..."
    docker restart metin2-server
    
    echo ""
    echo "✅ Proceso completado!"
    echo ""
    echo "Espera 30 segundos y verifica los logs:"
    echo "   docker logs --tail 50 metin2-server | grep -i package"
    echo ""
    echo "Si ves 'Failed to Load ClientPackageCryptInfo Files',"
    echo "verifica que los archivos se copiaron correctamente."
    
else
    echo "❌ Archivo pack.tar.gz no encontrado en /opt/metin2omg"
    echo ""
    echo "Asegúrate de que:"
    echo "1. El archivo se haya subido completamente"
    echo "2. El nombre del archivo sea exactamente 'pack.tar.gz'"
    echo "3. El archivo esté en /opt/metin2omg"
    echo ""
    echo "Archivos .tar.gz encontrados:"
    ls -lh *.tar.gz 2>/dev/null | head -5
fi

