#!/bin/bash
# Script para buscar la carpeta pack/ o package/

echo "=========================================="
echo "Buscando carpeta pack/ o package/"
echo "=========================================="
echo ""

echo "1. Buscando en el directorio actual:"
find . -type d \( -name "pack" -o -name "package" \) 2>/dev/null | head -10

echo ""
echo "2. Buscando en Client-20251206T130044Z-3-001:"
if [ -d "./Client-20251206T130044Z-3-001" ]; then
    find ./Client-20251206T130044Z-3-001 -type d \( -name "pack" -o -name "package" \) 2>/dev/null | head -10
else
    echo "⚠️ Carpeta Client-20251206T130044Z-3-001 no encontrada"
fi

echo ""
echo "3. Buscando en basesfiles:"
if [ -d "./basesfiles" ]; then
    find ./basesfiles -type d \( -name "pack" -o -name "package" \) 2>/dev/null | head -10
else
    echo "⚠️ Carpeta basesfiles no encontrada"
fi

echo ""
echo "4. Verificando si pack/ existe en la ruta esperada:"
if [ -d "./Client-20251206T130044Z-3-001/Client/Client/Client/pack" ]; then
    echo "✅ Encontrada: ./Client-20251206T130044Z-3-001/Client/Client/Client/pack"
    echo ""
    echo "Contenido:"
    ls -la "./Client-20251206T130044Z-3-001/Client/Client/Client/pack" | head -10
elif [ -d "./Client-20251206T130044Z-3-001/Client/Client/Client/package" ]; then
    echo "✅ Encontrada: ./Client-20251206T130044Z-3-001/Client/Client/Client/package"
    echo ""
    echo "Contenido:"
    ls -la "./Client-20251206T130044Z-3-001/Client/Client/Client/package" | head -10
else
    echo "❌ No encontrada en la ruta esperada"
fi

echo ""
echo "5. Verificando package/ en basesfiles:"
if [ -d "./basesfiles/metin2_server+src/metin2/server/share/package" ]; then
    echo "✅ Encontrada: ./basesfiles/metin2_server+src/metin2/server/share/package"
    echo ""
    echo "Contenido:"
    ls -la "./basesfiles/metin2_server+src/metin2/server/share/package" | head -10
else
    echo "❌ No encontrada en basesfiles"
fi

