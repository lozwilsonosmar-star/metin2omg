#!/bin/bash
# Script para buscar y copiar archivos cshybridcrypt del cliente

echo "=========================================="
echo "Búsqueda y Copia de Archivos cshybridcrypt"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "═══════════════════════════════════════════"
echo "1. BUSCANDO ARCHIVOS EN EL VPS"
echo "═══════════════════════════════════════════"
echo ""

# Buscar en ubicaciones comunes
SEARCH_PATHS=(
    "/opt/metin2omg"
    "/root"
    "/home"
    "/tmp"
    "/var/tmp"
)

FOUND_FILES=()

echo "Buscando archivos 'cshybridcrypt*' en el sistema..."
for path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "   Buscando en: $path"
        FILES=$(find "$path" -name "cshybridcrypt*" -type f 2>/dev/null)
        if [ -n "$FILES" ]; then
            echo "   ✅ Encontrados en: $path"
            while IFS= read -r file; do
                if [ -n "$file" ]; then
                    FOUND_FILES+=("$file")
                    echo "      - $file"
                fi
            done <<< "$FILES"
        fi
    fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "2. RESULTADO DE BÚSQUEDA"
echo "═══════════════════════════════════════════"
echo ""

if [ ${#FOUND_FILES[@]} -eq 0 ]; then
    echo "❌ No se encontraron archivos 'cshybridcrypt*' en el VPS"
    echo ""
    echo "═══════════════════════════════════════════"
    echo "3. INSTRUCCIONES PARA COPIAR DESDE CLIENTE"
    echo "═══════════════════════════════════════════"
    echo ""
    echo "Necesitas encontrar estos archivos en tu cliente (Windows) y copiarlos:"
    echo ""
    echo "1. Busca en el directorio del cliente:"
    echo "   - Busca en la carpeta 'package/' del cliente"
    echo "   - O en el directorio raíz del cliente"
    echo "   - Archivos que empiecen con 'cshybridcrypt'"
    echo ""
    echo "2. Si los encuentras, cópialos al VPS usando SCP o FileZilla:"
    echo "   scp cshybridcrypt* root@TU_VPS_IP:/tmp/"
    echo ""
    echo "3. Luego cópialos al contenedor:"
    echo "   docker cp /tmp/cshybridcrypt* metin2-server:/app/package/"
    echo ""
    echo "4. Reinicia el servidor:"
    echo "   docker restart metin2-server"
    echo ""
    echo "5. Verifica que se cargaron:"
    echo "   docker logs metin2-server | grep -i 'crypt\|package'"
    echo ""
    echo "═══════════════════════════════════════════"
    echo "ALTERNATIVA: GENERAR ARCHIVOS"
    echo "═══════════════════════════════════════════"
    echo ""
    echo "Si no encuentras los archivos, pueden generarse desde el cliente."
    echo "Estos archivos generalmente se crean cuando el cliente se ejecuta"
    echo "o se extraen de los archivos .eix/.epk del cliente."
    echo ""
    echo "Busca herramientas de extracción de Metin2 o consulta la"
    echo "documentación del servidor para generar estos archivos."
else
    echo "✅ Se encontraron ${#FOUND_FILES[@]} archivo(s):"
    for file in "${FOUND_FILES[@]}"; do
        SIZE=$(ls -lh "$file" 2>/dev/null | awk '{print $5}')
        echo "   - $file ($SIZE)"
    done
    
    echo ""
    echo "═══════════════════════════════════════════"
    echo "3. COPIANDO ARCHIVOS AL CONTENEDOR"
    echo "═══════════════════════════════════════════"
    echo ""
    
    COPIED=0
    for file in "${FOUND_FILES[@]}"; do
        FILENAME=$(basename "$file")
        echo "Copiando $FILENAME..."
        if docker cp "$file" metin2-server:/app/package/ 2>/dev/null; then
            echo "   ✅ $FILENAME copiado correctamente"
            COPIED=$((COPIED + 1))
        else
            echo "   ❌ Error al copiar $FILENAME"
        fi
    done
    
    echo ""
    if [ $COPIED -gt 0 ]; then
        echo "✅ Se copiaron $COPIED archivo(s) al contenedor"
        echo ""
        echo "═══════════════════════════════════════════"
        echo "4. VERIFICANDO ARCHIVOS EN CONTENEDOR"
        echo "═══════════════════════════════════════════"
        echo ""
        
        CRYPT_FILES=$(docker exec metin2-server sh -c "ls -1 /app/package/cshybridcrypt* 2>/dev/null" 2>/dev/null)
        if [ -n "$CRYPT_FILES" ]; then
            echo "✅ Archivos en el contenedor:"
            echo "$CRYPT_FILES" | while read line; do
                if [ -n "$line" ]; then
                    SIZE=$(docker exec metin2-server sh -c "ls -lh '$line' 2>/dev/null | awk '{print \$5}'" 2>/dev/null)
                    echo "   - $(basename $line) ($SIZE)"
                fi
            done
        else
            echo "❌ No se encontraron archivos en el contenedor"
        fi
        
        echo ""
        echo "═══════════════════════════════════════════"
        echo "5. REINICIANDO SERVIDOR"
        echo "═══════════════════════════════════════════"
        echo ""
        echo "Reiniciando servidor para cargar los archivos..."
        docker restart metin2-server > /dev/null 2>&1
        echo "✅ Servidor reiniciado"
        echo ""
        echo "Esperando 15 segundos para que el servidor inicie..."
        sleep 15
        
        echo ""
        echo "═══════════════════════════════════════════"
        echo "6. VERIFICANDO CARGA DE ARCHIVOS"
        echo "═══════════════════════════════════════════"
        echo ""
        
        FAILED_LOAD=$(docker logs metin2-server 2>&1 | grep -c "Failed to Load ClientPackageCryptInfo")
        if [ "$FAILED_LOAD" -eq 0 ]; then
            echo "✅ El servidor cargó los archivos correctamente"
            echo ""
            echo "Verificando logs de carga:"
            docker logs metin2-server 2>&1 | grep -i "PackageCryptInfo\|crypt" | tail -5
        else
            echo "❌ El servidor aún no puede cargar los archivos"
            echo ""
            echo "Últimos mensajes de error:"
            docker logs metin2-server 2>&1 | grep -i "Failed to Load\|PackageCryptInfo" | tail -3
        fi
    else
        echo "❌ No se pudo copiar ningún archivo"
    fi
fi

echo ""
echo "═══════════════════════════════════════════"
echo "RESUMEN"
echo "═══════════════════════════════════════════"
echo ""
echo "Archivos encontrados: ${#FOUND_FILES[@]}"
echo "Archivos copiados: ${COPIED:-0}"
echo ""

