#!/bin/bash
# Script para verificar el estado del servidor después de cambios
# Uso: bash verificar-estado-servidor.sh

echo "=========================================="
echo "Verificación del Estado del Servidor"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || exit 1

# 1. Verificar contenedor
echo -e "${GREEN}1. Estado del contenedor:${NC}"
if docker ps | grep -q "metin2-server"; then
    echo -e "${GREEN}   ✅ Contenedor está corriendo${NC}"
    docker ps | grep metin2-server | awk '{print "   ID: " $1 " | Estado: " $7 " | Desde: " $5}'
else
    echo -e "${RED}   ❌ Contenedor NO está corriendo${NC}"
    exit 1
fi
echo ""

# 2. Verificar IP en .env
echo -e "${GREEN}2. Configuración de IP:${NC}"
PUBLIC_IP=$(grep "^PUBLIC_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "NO_ENCONTRADO")
if [[ "$PUBLIC_IP" == *":"* ]]; then
    echo -e "${RED}   ❌ IP es IPv6: $PUBLIC_IP (debe ser IPv4)${NC}"
elif [ "$PUBLIC_IP" = "72.61.12.2" ]; then
    echo -e "${GREEN}   ✅ IP correcta (IPv4): $PUBLIC_IP${NC}"
else
    echo -e "${YELLOW}   ⚠️  IP: $PUBLIC_IP (verifica que sea correcta)${NC}"
fi
echo ""

# 3. Verificar puertos escuchando
echo -e "${GREEN}3. Puertos escuchando:${NC}"
PORTS_OK=0

if ss -tuln 2>/dev/null | grep -q ":12345"; then
    echo -e "${GREEN}   ✅ Puerto 12345 (GAME) está escuchando${NC}"
    ss -tuln | grep ":12345" | head -1
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 12345 (GAME) NO está escuchando aún${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":8888"; then
    echo -e "${GREEN}   ✅ Puerto 8888 (DB) está escuchando${NC}"
    ss -tuln | grep ":8888" | head -1
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 8888 (DB) NO está escuchando aún${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":13200"; then
    echo -e "${GREEN}   ✅ Puerto 13200 (P2P) está escuchando${NC}"
    ss -tuln | grep ":13200" | head -1
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 13200 (P2P) NO está escuchando aún${NC}"
fi
echo ""

# 4. Verificar logs (últimas 30 líneas)
echo -e "${GREEN}4. Logs del servidor (últimas 30 líneas):${NC}"
echo -e "${YELLOW}--- INICIO DE LOGS ---${NC}"
docker logs --tail 30 metin2-server 2>&1 | tail -30
echo -e "${YELLOW}--- FIN DE LOGS ---${NC}"
echo ""

# 5. Buscar indicadores clave
echo -e "${GREEN}5. Indicadores clave en logs:${NC}"

# Buscar TCP listening
if docker logs metin2-server 2>&1 | grep -qi "TCP listening"; then
    echo -e "${GREEN}   ✅ Servidor inició correctamente (TCP listening encontrado)${NC}"
    docker logs metin2-server 2>&1 | grep -i "TCP listening" | tail -1
else
    echo -e "${YELLOW}   ⚠️  No se encontró 'TCP listening' (puede estar iniciando aún)${NC}"
fi

# Buscar errores críticos
ERRORS=0
if docker logs metin2-server 2>&1 | grep -qi "Table.*doesn't exist"; then
    echo -e "${RED}   ❌ Error: Tablas faltantes${NC}"
    docker logs metin2-server 2>&1 | grep -i "Table.*doesn't exist" | tail -3
    ERRORS=$((ERRORS + 1))
fi

if docker logs metin2-server 2>&1 | grep -qi "AUTH_SERVER.*syntax error"; then
    echo -e "${RED}   ❌ Error: Configuración AUTH_SERVER incorrecta${NC}"
    ERRORS=$((ERRORS + 1))
fi

if docker logs metin2-server 2>&1 | grep -qi "SKILL_PERCENT.*not enough"; then
    echo -e "${RED}   ❌ Error: Datos de SKILL_POWER_BY_LEVEL faltantes${NC}"
    ERRORS=$((ERRORS + 1))
fi

if docker logs metin2-server 2>&1 | grep -qi "InitializeShopTable.*Table count is zero"; then
    echo -e "${RED}   ❌ Error: Tabla shop vacía${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}   ✅ No se encontraron errores críticos${NC}"
fi
echo ""

# 6. Resumen
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
    echo -e "${YELLOW}📋 Próximos pasos:${NC}"
    echo "   1. Crear cuenta de prueba (ver PASOS_FINALES_CLIENTE.md)"
    echo "   2. Configurar cliente con IP: 72.61.12.2 y Puerto: 12345"
    echo "   3. Intentar conectar"
elif [ $PORTS_OK -gt 0 ]; then
    echo -e "${YELLOW}⚠️  El servidor está iniciando...${NC}"
    echo ""
    echo "   Puertos activos: $PORTS_OK/3"
    echo ""
    echo "Espera 30-60 segundos más y ejecuta:"
    echo "   bash verificar-estado-servidor.sh"
else
    echo -e "${RED}❌ El servidor aún no está listo${NC}"
    echo ""
    echo "Verifica los logs para más detalles:"
    echo "   docker logs -f metin2-server"
fi

echo ""

