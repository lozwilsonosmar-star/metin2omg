#!/bin/bash
# Script para diagnosticar problemas del servidor
# Uso: bash diagnosticar-servidor.sh

echo "=========================================="
echo "Diagnóstico del Servidor Metin2"
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
    docker ps | grep metin2-server
else
    echo -e "${RED}   ❌ Contenedor NO está corriendo${NC}"
    echo ""
    echo "Ver contenedores detenidos:"
    docker ps -a | grep metin2-server
    exit 1
fi
echo ""

# 2. Ver logs completos (últimas 50 líneas)
echo -e "${GREEN}2. Logs del servidor (últimas 50 líneas):${NC}"
echo -e "${YELLOW}--- INICIO DE LOGS ---${NC}"
docker logs --tail 50 metin2-server 2>&1
echo -e "${YELLOW}--- FIN DE LOGS ---${NC}"
echo ""

# 3. Buscar errores críticos
echo -e "${GREEN}3. Buscando errores críticos:${NC}"
ERRORS=0

if docker logs metin2-server 2>&1 | grep -qi "Table.*doesn't exist"; then
    echo -e "${RED}   ❌ Error: Tablas faltantes${NC}"
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

if docker logs metin2-server 2>&1 | grep -qi "TCP listening"; then
    echo -e "${GREEN}   ✅ Servidor inició correctamente (TCP listening encontrado)${NC}"
else
    echo -e "${YELLOW}   ⚠️  No se encontró 'TCP listening' (puede estar iniciando aún)${NC}"
fi
echo ""

# 4. Verificar puertos
echo -e "${GREEN}4. Puertos escuchando:${NC}"
if ss -tuln 2>/dev/null | grep -q ":12345"; then
    echo -e "${GREEN}   ✅ Puerto 12345 (GAME) está escuchando${NC}"
    ss -tuln | grep ":12345"
else
    echo -e "${RED}   ❌ Puerto 12345 (GAME) NO está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":8888"; then
    echo -e "${GREEN}   ✅ Puerto 8888 (DB) está escuchando${NC}"
    ss -tuln | grep ":8888"
else
    echo -e "${RED}   ❌ Puerto 8888 (DB) NO está escuchando${NC}"
fi
echo ""

# 5. Verificar IP pública
echo -e "${GREEN}5. Configuración de IP:${NC}"
if [ -f ".env" ]; then
    PUBLIC_IP=$(grep "^PUBLIC_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "NO_CONFIGURADO")
    echo -e "${BLUE}   PUBLIC_IP en .env: $PUBLIC_IP${NC}"
    
    # Obtener IP real del servidor
    REAL_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    echo -e "${BLUE}   IP real del servidor: $REAL_IP${NC}"
    
    if [ "$PUBLIC_IP" != "$REAL_IP" ] && [ "$PUBLIC_IP" != "72.61.12.2" ]; then
        echo -e "${YELLOW}   ⚠️  La IP en .env puede estar incorrecta${NC}"
        echo -e "${YELLOW}   Debe ser: 72.61.12.2${NC}"
    fi
else
    echo -e "${RED}   ❌ Archivo .env no encontrado${NC}"
fi
echo ""

# 6. Resumen y recomendaciones
echo "=========================================="
echo "RESUMEN"
echo "=========================================="

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Se encontraron $ERRORS error(es)${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Soluciones:${NC}"
    echo ""
    
    if docker logs metin2-server 2>&1 | grep -qi "Table.*doesn't exist"; then
        echo -e "${YELLOW}1. Tablas faltantes:${NC}"
        echo "   bash docker/verificar-y-crear-todo.sh"
    fi
    
    if docker logs metin2-server 2>&1 | grep -qi "AUTH_SERVER.*syntax error"; then
        echo -e "${YELLOW}2. Error AUTH_SERVER:${NC}"
        echo "   Verificar .env: GAME_AUTH_SERVER=localhost"
    fi
    
    if docker logs metin2-server 2>&1 | grep -qi "SKILL_PERCENT"; then
        echo -e "${YELLOW}3. Error SKILL_POWER_BY_LEVEL:${NC}"
        echo "   bash docker/corregir-problemas-inicializacion.sql"
    fi
    
    echo ""
    echo "Ver logs completos:"
    echo "   docker logs -f metin2-server"
else
    if ss -tuln 2>/dev/null | grep -q ":12345"; then
        echo -e "${GREEN}✅ TODO ESTÁ BIEN!${NC}"
        echo ""
        echo -e "${BLUE}🎮 El servidor está listo para conectar${NC}"
        echo ""
        PUBLIC_IP=$(grep "^PUBLIC_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "72.61.12.2")
        echo "   IP: $PUBLIC_IP"
        echo "   Puerto: 12345"
    else
        echo -e "${YELLOW}⚠️  El servidor está iniciando...${NC}"
        echo ""
        echo "Espera 30-60 segundos más y verifica:"
        echo "   ss -tuln | grep 12345"
        echo ""
        echo "O ver logs en tiempo real:"
        echo "   docker logs -f metin2-server"
    fi
fi

echo ""

