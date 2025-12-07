#!/bin/bash
# Script para verificar logs de login inmediatamente
# Uso: bash verificar-login-ahora.sh

echo "=========================================="
echo "Verificación Inmediata de Login"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "Buscando logs relacionados con login..."
echo ""

if docker ps | grep -q "metin2-server"; then
    echo "1. Buscando 'QID_AUTH_LOGIN: SUCCESS'..."
    RESULT=$(docker logs metin2-server 2>&1 | grep -i "QID_AUTH_LOGIN: SUCCESS" | tail -5)
    if [ -n "$RESULT" ]; then
        echo "   ✅ Encontrado:"
        echo "$RESULT"
    else
        echo "   ❌ NO encontrado - El flujo no está llegando a LoginPrepare"
    fi
    echo ""
    
    echo "2. Buscando 'LoginPrepare'..."
    RESULT=$(docker logs metin2-server 2>&1 | grep -i "LoginPrepare" | tail -5)
    if [ -n "$RESULT" ]; then
        echo "   ✅ Encontrado:"
        echo "$RESULT"
    else
        echo "   ❌ NO encontrado"
    fi
    echo ""
    
    echo "3. Buscando 'SendAuthLogin'..."
    RESULT=$(docker logs metin2-server 2>&1 | grep -i "SendAuthLogin" | tail -5)
    if [ -n "$RESULT" ]; then
        echo "   ✅ Encontrado:"
        echo "$RESULT"
    else
        echo "   ❌ NO encontrado"
    fi
    echo ""
    
    echo "4. Últimos logs después del último 'AuthLogin result 1'..."
    docker logs metin2-server 2>&1 | grep -A 30 "AuthLogin result 1" | tail -35
    echo ""
    
    echo "5. Buscando errores después del login..."
    docker logs metin2-server 2>&1 | grep -A 20 "AuthLogin result 1" | grep -iE "error|failed|critical" | tail -10
    echo ""
else
    echo "   ⚠️  Contenedor no está corriendo"
fi

echo ""
echo "=========================================="
echo "INTERPRETACIÓN"
echo "=========================================="
echo ""
echo "Si NO aparece 'QID_AUTH_LOGIN: SUCCESS':"
echo "   - El código no está llegando a LoginPrepare en db.cpp línea 419"
echo "   - Puede haber un error antes (verificación de contraseña, status, etc.)"
echo "   - O la consulta SQL no está devolviendo resultados"
echo ""
echo "Si aparece 'QID_AUTH_LOGIN: SUCCESS' pero NO 'SendAuthLogin':"
echo "   - LoginPrepare se ejecutó pero hay un problema con Matrix Code"
echo "   - O SendAuthLogin no se está llamando"
echo ""
echo "Si aparece 'SendAuthLogin' pero el cliente no recibe datos:"
echo "   - El paquete se envió pero hay un problema de comunicación"
echo ""

