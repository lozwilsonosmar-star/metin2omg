#!/bin/bash
# Script para verificar el estado completo del servidor
# Uso: bash verificar-servidor-completo.sh

echo "=========================================="
echo "Verificación Completa del Servidor"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Verificar contenedor
echo -e "${GREEN}1. Estado del contenedor:${NC}"
if docker ps | grep -q "metin2-server"; then
    echo -e "${GREEN}   ✅ Contenedor corriendo${NC}"
    docker ps | grep metin2-server
else
    echo -e "${RED}   ❌ Contenedor NO está corriendo${NC}"
    exit 1
fi
echo ""

# 2. Verificar puertos
echo -e "${GREEN}2. Puertos escuchando:${NC}"
PORTS_OK=0

if ss -tuln 2>/dev/null | grep -q ":12345"; then
    echo -e "${GREEN}   ✅ Puerto 12345 (GAME) está escuchando${NC}"
    ss -tuln | grep ":12345"
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 12345 (GAME) NO está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":8888"; then
    echo -e "${GREEN}   ✅ Puerto 8888 (DB) está escuchando${NC}"
    ss -tuln | grep ":8888"
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 8888 (DB) NO está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":13200"; then
    echo -e "${GREEN}   ✅ Puerto 13200 (P2P) está escuchando${NC}"
    ss -tuln | grep ":13200"
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 13200 (P2P) NO está escuchando${NC}"
fi
echo ""

# 3. Verificar logs - AUTH_SERVER
echo -e "${GREEN}3. Verificando AUTH_SERVER en logs:${NC}"
if docker logs metin2-server 2>&1 | grep -q "AUTH_SERVER: I am the master"; then
    echo -e "${GREEN}   ✅ AUTH_SERVER configurado correctamente${NC}"
    docker logs metin2-server 2>&1 | grep "AUTH_SERVER" | tail -1
else
    echo -e "${RED}   ❌ AUTH_SERVER NO está configurado${NC}"
fi
echo ""

# 4. Verificar logs - TCP listening
echo -e "${GREEN}4. Verificando TCP listening en logs:${NC}"
TCP_LISTENING=$(docker logs metin2-server 2>&1 | grep -i "TCP listening" || echo "")
if [ -n "$TCP_LISTENING" ]; then
    echo -e "${GREEN}   ✅ Servidor está escuchando${NC}"
    echo "$TCP_LISTENING" | tail -3
else
    echo -e "${YELLOW}   ⚠️  No se encontró 'TCP listening' en los logs${NC}"
    echo "   (Puede estar iniciando aún o puede usar otro mensaje)"
fi
echo ""

# 5. Verificar errores críticos
echo -e "${GREEN}5. Verificando errores críticos:${NC}"
ERRORS=0

if docker logs metin2-server 2>&1 | grep -qi "AUTH_SERVER.*syntax error"; then
    echo -e "${RED}   ❌ Error: AUTH_SERVER syntax error${NC}"
    ERRORS=$((ERRORS + 1))
fi

if docker logs metin2-server 2>&1 | grep -qi "LANGUAGE.*not found"; then
    echo -e "${RED}   ❌ Error: LANGUAGE not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

if docker logs metin2-server 2>&1 | grep -qi "Table.*doesn't exist"; then
    echo -e "${RED}   ❌ Error: Tablas faltantes${NC}"
    docker logs metin2-server 2>&1 | grep -i "Table.*doesn't exist" | tail -2
    ERRORS=$((ERRORS + 1))
fi

if docker logs metin2-server 2>&1 | grep -qi "InitializeSkillTable.*FAILED"; then
    echo -e "${RED}   ❌ Error: InitializeSkillTable FAILED${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}   ✅ No se encontraron errores críticos${NC}"
fi
echo ""

# 6. Últimas líneas de logs
echo -e "${GREEN}6. Últimas 20 líneas de logs:${NC}"
echo -e "${YELLOW}--- INICIO ---${NC}"
docker logs --tail 20 metin2-server 2>&1
echo -e "${YELLOW}--- FIN ---${NC}"
echo ""

# 7. Resumen
echo "=========================================="
echo "RESUMEN"
echo "=========================================="

if [ $PORTS_OK -eq 3 ] && [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ TODO ESTÁ PERFECTO!${NC}"
    echo ""
    echo -e "${BLUE}🎮 El servidor está listo para conectar${NC}"
    echo ""
    echo "   IP: 72.61.12.2"
    echo "   Puerto: 12345"
    echo ""
elif [ $PORTS_OK -gt 0 ]; then
    echo -e "${YELLOW}⚠️  El servidor está iniciando...${NC}"
    echo ""
    echo "   Puertos activos: $PORTS_OK/3"
    echo "   Espera 30-60 segundos más"
    echo ""
else
    echo -e "${YELLOW}⚠️  El servidor aún no está completamente iniciado${NC}"
    echo ""
    echo "Verifica los logs completos:"
    echo "   docker logs -f metin2-server"
fi

echo ""

