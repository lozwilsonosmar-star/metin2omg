#!/bin/bash
# Script para buscar el archivo pack.tar.gz

echo "=========================================="
echo "Buscando archivo pack.tar.gz"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Buscando archivos .tar.gz en /opt/metin2omg:"
ls -lh *.tar.gz 2>/dev/null || echo "   No se encontraron archivos .tar.gz"

echo ""
echo "2. Buscando archivos con 'pack' en el nombre:"
find . -maxdepth 1 -type f -iname "*pack*" 2>/dev/null | head -10

echo ""
echo "3. Buscando archivos .tar.gz en todo el directorio:"
find . -maxdepth 2 -type f -name "*.tar.gz" 2>/dev/null | head -10

echo ""
echo "4. Listando todos los archivos en /opt/metin2omg:"
ls -lh | grep -E "pack|tar|gz" | head -10

echo ""
echo "5. Verificando si hay archivos recién subidos (últimos 5 minutos):"
find . -maxdepth 1 -type f -mmin -5 2>/dev/null | head -10

echo ""
echo "═══════════════════════════════════════════"
echo "INSTRUCCIONES"
echo "═══════════════════════════════════════════"
echo ""
echo "Si el archivo tiene otro nombre, puedes:"
echo "1. Renombrarlo: mv nombre_archivo.tar.gz pack.tar.gz"
echo "2. O modificar el script procesar-pack-subido.sh para usar el nombre correcto"
echo ""

