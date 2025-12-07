#!/bin/bash
# Script para monitorear el flujo completo de login en tiempo real

echo "=========================================="
echo "Monitor de Login en Tiempo Real"
echo "=========================================="
echo ""
echo "Este script monitoreará los logs mientras intentas conectarte."
echo "Presiona Ctrl+C para detener."
echo ""
echo "═══════════════════════════════════════════"
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

# Monitorear logs relacionados con login
docker logs -f metin2-server 2>&1 | grep --line-buffered -E "LOGIN_BY_KEY|RESULT_LOGIN|HEADER_DG_LOGIN_SUCCESS|LoginSuccess|SendLoginSuccessPacket|PHASE_SELECT|player_index|QID_LOGIN|test|admin" | while IFS= read -r line; do
    # Colorear según el tipo de mensaje
    if echo "$line" | grep -qE "success|SUCCESS|Success"; then
        echo -e "\033[0;32m✅ $line\033[0m"
    elif echo "$line" | grep -qE "error|ERROR|Error|fail|FAIL|Fail"; then
        echo -e "\033[0;31m❌ $line\033[0m"
    elif echo "$line" | grep -qE "LOGIN_BY_KEY|RESULT_LOGIN|QID_LOGIN"; then
        echo -e "\033[0;34m🔵 $line\033[0m"
    elif echo "$line" | grep -qE "LoginSuccess|SendLoginSuccessPacket|PHASE_SELECT"; then
        echo -e "\033[0;33m🟡 $line\033[0m"
    else
        echo "$line"
    fi
done

