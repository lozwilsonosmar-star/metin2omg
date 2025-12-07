#!/bin/bash
# Script para copiar la carpeta package/ al contenedor

echo "=========================================="
echo "Copiar carpeta package/ al contenedor"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

# Buscar carpeta package/ en el cliente
CLIENT_PACKAGE=""
if [ -d "./Client-20251206T130044Z-3-001/Client/Client/Client/pack" ]; then
    CLIENT_PACKAGE="./Client-20251206T130044Z-3-001/Client/Client/Client/pack"
    echo "✅ Encontrada carpeta pack/ en el cliente"
elif [ -d "./basesfiles/metin2_server+src/metin2/server/share/package" ]; then
    CLIENT_PACKAGE="./basesfiles/metin2_server+src/metin2/server/share/package"
    echo "✅ Encontrada carpeta package/ en basesfiles"
else
    echo "⚠️ No se encontró carpeta package/ o pack/"
    echo ""
    echo "Buscando en el cliente..."
    find ./Client-20251206T130044Z-3-001 -type d -name "pack*" -o -name "package*" 2>/dev/null | head -5
    exit 1
fi

echo ""
echo "1. Verificando contenido de la carpeta:"
ls -la "$CLIENT_PACKAGE" | head -10

echo ""
echo "2. Creando carpeta package/ en el contenedor si no existe:"
docker exec metin2-server mkdir -p /app/package 2>/dev/null || true

echo ""
echo "3. Copiando archivos al contenedor..."
if [ -d "$CLIENT_PACKAGE" ]; then
    # Copiar todos los archivos
    docker cp "$CLIENT_PACKAGE/." metin2-server:/app/package/ 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Archivos copiados exitosamente"
    else
        echo "❌ Error al copiar archivos"
        exit 1
    fi
else
    echo "❌ La carpeta no existe o no es un directorio"
    exit 1
fi

echo ""
echo "4. Verificando archivos copiados:"
docker exec metin2-server ls -la /app/package 2>/dev/null | head -10

echo ""
echo "5. Reiniciando contenedor para aplicar cambios..."
read -p "¿Deseas reiniciar el contenedor ahora? (S/n): " reiniciar
if [ "$reiniciar" != "n" ]; then
    docker restart metin2-server
    echo "✅ Contenedor reiniciado"
    echo ""
    echo "Espera 30 segundos y verifica los logs:"
    echo "   docker logs --tail 50 metin2-server | grep -i package"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "RESUMEN"
echo "═══════════════════════════════════════════"
echo ""
echo "La carpeta package/ contiene archivos de cifrado necesarios"
echo "para que el servidor pueda procesar los paquetes del cliente."
echo ""
echo "Si el error persiste, verifica que:"
echo "1. Los archivos se copiaron correctamente"
echo "2. El servidor puede leer los archivos (permisos)"
echo "3. Los archivos son compatibles con la versión del cliente"
echo ""

