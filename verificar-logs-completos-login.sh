#!/bin/bash
# Script para ver logs completos del proceso de login

echo "=========================================="
echo "Logs Completos del Proceso de Login"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "Mostrando últimos 100 logs relacionados con login y personajes:"
echo ""
echo "═══════════════════════════════════════════"
echo "LOGS COMPLETOS"
echo "═══════════════════════════════════════════"
echo ""

docker logs --tail 100 metin2-server 2>&1 | grep -E "AuthLogin|PHASE|Character|player_index|LoginSuccess|SendLoad|test|admin|WRONGCRD|ERROR|CRITICAL" | tail -30

echo ""
echo "═══════════════════════════════════════════"
echo "PARA VER EN TIEMPO REAL:"
echo "═══════════════════════════════════════════"
echo ""
echo "Ejecuta esto mientras intentas conectarte:"
echo "   docker logs -f metin2-server | grep -E 'AuthLogin|PHASE|Character|SendLoad|LoginSuccess'"
echo ""
