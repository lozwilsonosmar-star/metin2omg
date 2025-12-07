#!/bin/bash
# Script para verificar el flujo completo de login
# Uso: bash verificar-flujo-login-completo.sh

echo "=========================================="
echo "Verificación del Flujo Completo de Login"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Conectándote desde el cliente y luego ejecuta este script..."
echo "   (Presiona Ctrl+C para cancelar o espera 10 segundos)"
echo ""
sleep 10

echo "2. Buscando logs relacionados con el login..."
echo ""

if docker ps | grep -q "metin2-server"; then
    echo "   Buscando 'QID_AUTH_LOGIN: SUCCESS'..."
    docker logs metin2-server 2>&1 | grep -A 10 "QID_AUTH_LOGIN: SUCCESS" | tail -15
    echo ""
    
    echo "   Buscando 'LoginPrepare'..."
    docker logs metin2-server 2>&1 | grep -i "LoginPrepare" | tail -5
    echo ""
    
    echo "   Buscando 'SendAuthLogin'..."
    docker logs metin2-server 2>&1 | grep -i "SendAuthLogin" | tail -5
    echo ""
    
    echo "   Últimos logs después del último 'AuthLogin result 1'..."
    docker logs metin2-server 2>&1 | grep -A 30 "AuthLogin result 1" | tail -35
    echo ""
else
    echo "   ⚠️  Contenedor no está corriendo"
fi

echo ""
echo "3. Verificando configuración AUTH_SERVER..."
echo ""

if [ -f ".env" ]; then
    AUTH_SERVER=$(grep "^GAME_AUTH_SERVER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs)
    echo "   GAME_AUTH_SERVER: $AUTH_SERVER"
    
    if [ "$AUTH_SERVER" = "master" ]; then
        echo "   ✅ Configurado como MasterAuth (standalone)"
    else
        echo "   ⚠️  No está configurado como 'master'"
    fi
fi

echo ""
echo "=========================================="
echo "ANÁLISIS"
echo "=========================================="
echo ""
echo "Si NO aparece 'QID_AUTH_LOGIN: SUCCESS':"
echo "   - El flujo no está llegando a LoginPrepare"
echo "   - Puede haber un error antes de llegar ahí"
echo ""
echo "Si aparece 'QID_AUTH_LOGIN: SUCCESS' pero NO 'SendAuthLogin':"
echo "   - LoginPrepare se ejecutó pero SendAuthLogin no"
echo "   - Puede ser un problema con el Matrix Code"
echo ""
echo "Si aparece 'SendAuthLogin' pero el cliente no recibe datos:"
echo "   - El paquete se envió pero hay un problema de comunicación"
echo ""

