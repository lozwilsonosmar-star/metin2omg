#!/bin/bash
# Script para verificar si el cliente está intentando conectarse

echo "=========================================="
echo "Verificación de Conexión del Cliente"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "1. Verificando puertos escuchando:"
echo ""
netstat -tuln 2>/dev/null | grep -E "12345|8888|13200" || ss -tuln 2>/dev/null | grep -E "12345|8888|13200"

echo ""
echo "2. Verificando conexiones activas:"
echo ""
netstat -an 2>/dev/null | grep -E "12345|8888|13200" | head -10 || ss -an 2>/dev/null | grep -E "12345|8888|13200" | head -10

echo ""
echo "3. Últimos logs de conexión (últimas 50 líneas):"
echo ""
docker logs --tail 50 metin2-server 2>&1 | grep -E "Connection|connected|TCP|accept|socket|bind|listen" | tail -20

echo ""
echo "4. Verificando configuración del cliente:"
echo ""
if [ -f "./Client-20251206T130044Z-3-001/Client/Client/Client/Eternexus/root/serverinfo.py" ]; then
    echo "✅ serverinfo.py encontrado:"
    grep -E "SERVER_IP|PORT" "./Client-20251206T130044Z-3-001/Client/Client/Client/Eternexus/root/serverinfo.py" | head -5
else
    echo "⚠️ serverinfo.py no encontrado en la ruta esperada"
fi

echo ""
echo "5. Verificando IP pública del servidor:"
echo ""
if [ -f ".env" ]; then
    grep "PUBLIC_IP" .env | head -1
else
    echo "⚠️ .env no encontrado"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "INSTRUCCIONES:"
echo "═══════════════════════════════════════════"
echo ""
echo "1. Verifica que el cliente tenga la IP correcta:"
echo "   - Debe ser la IP pública del servidor (72.61.12.2)"
echo "   - NO debe ser localhost o 127.0.0.1"
echo ""
echo "2. Verifica que los puertos estén abiertos en el firewall"
echo ""
echo "3. Intenta conectarte desde el cliente y observa si aparecen"
echo "   conexiones en el paso 2"
echo ""

