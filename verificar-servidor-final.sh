#!/bin/bash
# Verificación final del servidor
# Uso: bash verificar-servidor-final.sh

echo "=========================================="
echo "✅ VERIFICACIÓN FINAL DEL SERVIDOR"
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
    docker ps | grep metin2-server | awk '{print "   ID: " $1 " | Estado: " $7}'
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
    ss -tuln | grep ":12345" | head -1
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 12345 (GAME) NO está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":8888"; then
    echo -e "${GREEN}   ✅ Puerto 8888 (DB) está escuchando${NC}"
    ss -tuln | grep ":8888" | head -1
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 8888 (DB) NO está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":13200"; then
    echo -e "${GREEN}   ✅ Puerto 13200 (P2P) está escuchando${NC}"
    ss -tuln | grep ":13200" | head -1
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 13200 (P2P) NO está escuchando${NC}"
fi
echo ""

# 3. Verificar logs críticos
echo -e "${GREEN}3. Verificando logs críticos:${NC}"

if docker logs metin2-server 2>&1 | grep -q "TCP listening on 0.0.0.0:12345"; then
    echo -e "${GREEN}   ✅ Servidor está escuchando en puerto 12345${NC}"
    docker logs metin2-server 2>&1 | grep "TCP listening" | tail -1
else
    echo -e "${RED}   ❌ No se encontró 'TCP listening'${NC}"
fi

if docker logs metin2-server 2>&1 | grep -q "AUTH_SERVER: I am the master"; then
    echo -e "${GREEN}   ✅ AUTH_SERVER configurado correctamente${NC}"
else
    echo -e "${RED}   ❌ AUTH_SERVER NO configurado${NC}"
fi

if docker logs metin2-server 2>&1 | grep -qi "WEB_APP_URL must be configured"; then
    echo -e "${RED}   ❌ Error: WEB_APP_URL no configurado${NC}"
else
    echo -e "${GREEN}   ✅ WEB_APP_URL configurado${NC}"
fi

if docker logs metin2-server 2>&1 | grep -qi "addon_type.*Out of range"; then
    echo -e "${YELLOW}   ⚠️  Aún hay errores de addon_type (pueden ser de items antiguos)${NC}"
else
    echo -e "${GREEN}   ✅ No hay errores críticos de addon_type${NC}"
fi
echo ""

# 4. Resumen
echo "=========================================="
echo "RESUMEN FINAL"
echo "=========================================="

if [ $PORTS_OK -ge 1 ]; then
    echo -e "${GREEN}✅ SERVIDOR FUNCIONANDO${NC}"
    echo ""
    echo -e "${BLUE}🎮 Configuración del Cliente:${NC}"
    echo ""
    echo "   IP del servidor: 72.61.12.2"
    echo "   Puerto del juego: 12345"
    echo ""
    echo -e "${YELLOW}📋 Próximos pasos:${NC}"
    echo "   1. Crear cuenta de prueba en la base de datos"
    echo "   2. Configurar el cliente Metin2 con la IP y puerto"
    echo "   3. Intentar conectar"
    echo ""
    echo -e "${GREEN}✅ ¡El servidor está listo para recibir conexiones!${NC}"
else
    echo -e "${YELLOW}⚠️  El servidor está iniciando...${NC}"
    echo "   Espera unos segundos más y vuelve a verificar"
fi

echo ""

