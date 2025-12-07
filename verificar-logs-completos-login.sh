#!/bin/bash
# Script para ver logs completos alrededor del login
# Uso: bash verificar-logs-completos-login.sh

echo "=========================================="
echo "Logs Completos del Último Login"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "Buscando todas las líneas relacionadas con el último login..."
echo ""

if docker ps | grep -q "metin2-server"; then
    # Buscar el último AuthLogin result y mostrar contexto
    docker logs metin2-server 2>&1 | grep -A 30 "AuthLogin result 1" | tail -35
    echo ""
    echo "=========================================="
    echo "Buscando 'LoginPrepare' o 'SendAuthLogin'..."
    echo "=========================================="
    docker logs metin2-server 2>&1 | grep -iE "LoginPrepare|SendAuthLogin|QID_AUTH_LOGIN.*SUCCESS" | tail -10
    echo ""
    echo "=========================================="
    echo "Buscando errores después del login..."
    echo "=========================================="
    docker logs metin2-server 2>&1 | grep -A 20 "AuthLogin result 1" | grep -iE "error|failed|critical|warning" | tail -10
else
    echo "   ⚠️  Contenedor no está corriendo"
fi

echo ""

