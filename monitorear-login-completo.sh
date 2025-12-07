#!/bin/bash
# Script mejorado para monitorear TODO el flujo de login

echo "=========================================="
echo "Monitor Completo de Login"
echo "=========================================="
echo ""
echo "Este script mostrará TODOS los mensajes relacionados con conexiones y login."
echo "Presiona Ctrl+C para detener."
echo ""
echo "═══════════════════════════════════════════"
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

# Monitorear TODOS los logs sin filtrar demasiado
docker logs -f metin2-server 2>&1 | while IFS= read -r line; do
    # Filtrar solo líneas relevantes pero mostrar más información
    if echo "$line" | grep -qE "LOGIN|login|Login|AUTH|auth|Auth|PHASE|Phase|player_index|test|admin|SendLogin|LoginSuccess|HEADER|QID|RESULT|Connection|connected|connect|TCP|listening|port|12345|8888|13200"; then
        # Colorear según el tipo de mensaje
        if echo "$line" | grep -qE "success|SUCCESS|Success|connected|listening"; then
            echo -e "\033[0;32m✅ $line\033[0m"
        elif echo "$line" | grep -qE "error|ERROR|Error|fail|FAIL|Fail|critical|CRITICAL"; then
            # Ignorar errores de archivos de test
            if ! echo "$line" | grep -qE "item_proto_test|No test file"; then
                echo -e "\033[0;31m❌ $line\033[0m"
            fi
        elif echo "$line" | grep -qE "LOGIN_BY_KEY|RESULT_LOGIN|QID_LOGIN|HEADER_DG_LOGIN"; then
            echo -e "\033[0;34m🔵 $line\033[0m"
        elif echo "$line" | grep -qE "LoginSuccess|SendLoginSuccessPacket|PHASE_SELECT"; then
            echo -e "\033[0;33m🟡 $line\033[0m"
        elif echo "$line" | grep -qE "TCP|listening|port"; then
            echo -e "\033[0;36m🔷 $line\033[0m"
        else
            echo "$line"
        fi
    fi
done

