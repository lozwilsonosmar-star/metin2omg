#!/bin/bash
# Script para ver TODOS los logs mientras hay una conexión activa

echo "=========================================="
echo "Logs Completos Durante Conexión Activa"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "Mostrando los últimos 100 logs (sin filtrar errores de test):"
echo ""

# Mostrar logs sin filtrar, pero excluyendo errores de archivos de test
docker logs --tail 100 metin2-server 2>&1 | grep -v "item_proto_test\|No test file" | tail -50

echo ""
echo "═══════════════════════════════════════════"
echo "Buscando mensajes específicos de login:"
echo "═══════════════════════════════════════════"
echo ""

echo "1. Mensajes de AuthLogin:"
docker logs --tail 200 metin2-server 2>&1 | grep -i "AuthLogin" | tail -10

echo ""
echo "2. Mensajes de LOGIN_BY_KEY:"
docker logs --tail 200 metin2-server 2>&1 | grep -i "LOGIN_BY_KEY" | tail -10

echo ""
echo "3. Mensajes de LoginSuccess:"
docker logs --tail 200 metin2-server 2>&1 | grep -i "LoginSuccess\|login_success" | tail -10

echo ""
echo "4. Mensajes de PHASE:"
docker logs --tail 200 metin2-server 2>&1 | grep -i "PHASE" | tail -10

echo ""
echo "5. Mensajes de player_index:"
docker logs --tail 200 metin2-server 2>&1 | grep -i "player_index" | tail -10

echo ""
echo "6. Mensajes de QID_LOGIN o RESULT_LOGIN:"
docker logs --tail 200 metin2-server 2>&1 | grep -i "QID_LOGIN\|RESULT_LOGIN" | tail -10

echo ""
echo "═══════════════════════════════════════════"
echo "INSTRUCCIONES:"
echo "═══════════════════════════════════════════"
echo ""
echo "Si no ves mensajes de login, el cliente se conectó pero:"
echo "1. No está enviando paquetes de login"
echo "2. Los paquetes se están perdiendo"
echo "3. Hay un problema con el handshake inicial"
echo ""
echo "Ejecuta esto mientras intentas conectarte:"
echo "   docker logs -f metin2-server 2>&1 | grep -v 'item_proto_test\|No test file'"
echo ""

