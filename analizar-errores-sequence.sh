#!/bin/bash
# Script para analizar errores de SEQUENCE

echo "=========================================="
echo "Análisis de Errores de SEQUENCE"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "Los errores de SEQUENCE indican problemas con el cifrado/protocolo"
echo "entre el cliente y el servidor."
echo ""

echo "═══════════════════════════════════════════"
echo "1. ÚLTIMOS ERRORES DE SEQUENCE"
echo "═══════════════════════════════════════════"
echo ""

docker logs --tail 200 metin2-server 2>&1 | grep -A 2 "SEQUENCE.*mismatch" | tail -20

echo ""
echo "═══════════════════════════════════════════"
echo "2. ERRORES DE GetRelatedMapSDBStreams"
echo "═══════════════════════════════════════════"
echo ""

docker logs --tail 200 metin2-server 2>&1 | grep -B 2 -A 2 "GetRelatedMapSDBStreams" | tail -10

echo ""
echo "═══════════════════════════════════════════"
echo "3. MENSAJES DE AuthLogin (para correlacionar)"
echo "═══════════════════════════════════════════"
echo ""

docker logs --tail 200 metin2-server 2>&1 | grep -E "AuthLogin|LOGIN_BY_KEY|PHASE_SELECT" | tail -10

echo ""
echo "═══════════════════════════════════════════"
echo "4. ANÁLISIS"
echo "═══════════════════════════════════════════"
echo ""

echo "Los errores de SEQUENCE pueden indicar:"
echo "1. Incompatibilidad de versión entre cliente y servidor"
echo "2. Problemas con el cifrado del cliente (package/)"
echo "3. El cliente está enviando paquetes con formato incorrecto"
echo ""
echo "El error 'GetRelatedMapSDBStreams Failed' indica que:"
echo "- Falta información de cifrado del cliente en package/"
echo "- El servidor no puede procesar correctamente los paquetes del cliente"
echo ""
echo "═══════════════════════════════════════════"
echo "5. VERIFICAR ARCHIVOS DE CIFRADO"
echo "═══════════════════════════════════════════"
echo ""

echo "Buscando archivos package/ en el contenedor:"
docker exec metin2-server find /app -name "package" -type d 2>/dev/null | head -5
docker exec metin2-server ls -la /app/package 2>/dev/null | head -10

echo ""
echo "Verificando logs sobre package:"
docker logs --tail 100 metin2-server 2>&1 | grep -i "package\|crypt\|ClientPackage" | tail -10

