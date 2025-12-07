#!/bin/bash
# Script para diagnosticar el flujo completo después del login exitoso

echo "=========================================="
echo "Diagnóstico: Flujo Completo después del Login"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

if ! docker ps | grep -q "metin2-server"; then
    echo -e "${RED}❌ Contenedor no está corriendo${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}LOGS COMPLETOS DEL PROCESO DE LOGIN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

echo "Mostrando últimos 200 logs relacionados con login:"
echo ""

# Buscar logs relacionados con el flujo de login
docker logs --tail 200 metin2-server 2>&1 | grep -E "AuthLogin|LOGIN_BY_KEY|LoginSuccess|PHASE_SELECT|SendLoginSuccess|player_index|QID_LOGIN|RESULT_LOGIN|test|admin" | tail -50

echo ""
echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}VERIFICANDO ERRORES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

ERRORS=$(docker logs --tail 200 metin2-server 2>&1 | grep -iE "error|critical|fail|exception" | grep -v "item_proto_test.txt\|No test file" | tail -10)

if [ -n "$ERRORS" ]; then
    echo -e "${RED}Errores encontrados:${NC}"
    echo "$ERRORS"
else
    echo -e "${GREEN}✅ No se encontraron errores críticos${NC}"
fi

echo ""
echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}INSTRUCCIONES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

echo "Para diagnosticar en tiempo real:"
echo ""
echo "1. Abre una terminal y ejecuta:"
echo "   docker logs -f metin2-server | grep -E 'AuthLogin|LOGIN_BY_KEY|LoginSuccess|PHASE_SELECT|SendLoginSuccess|QID_LOGIN|RESULT_LOGIN'"
echo ""
echo "2. En otra terminal, intenta conectarte desde el cliente"
echo ""
echo "3. Observa qué mensajes aparecen en los logs"
echo ""
echo "Busca específicamente:"
echo "   - 'LOGIN_BY_KEY success' (DB server encontró la cuenta)"
echo "   - 'RESULT_LOGIN_BY_KEY' (DB server cargó player_index)"
echo "   - 'QID_LOGIN' (DB server cargó personajes)"
echo "   - 'LoginSuccess' (Game server recibió datos)"
echo "   - 'PHASE_SELECT' (Fase cambiada correctamente)"
echo "   - 'SendLoginSuccessPacket' (Lista enviada al cliente)"
echo ""

