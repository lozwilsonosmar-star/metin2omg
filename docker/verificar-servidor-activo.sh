#!/bin/bash
# Script para verificar que el servidor está activo y escuchando
# Uso: bash docker/verificar-servidor-activo.sh

set -e

echo "=========================================="
echo "Verificación del Servidor Metin2"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Verificar contenedor
echo -e "${GREEN}🔍 1. Verificando contenedor Docker...${NC}"
if docker ps | grep -q "metin2-server"; then
    echo -e "${GREEN}✅ Contenedor metin2-server está corriendo${NC}"
    docker ps | grep metin2-server
else
    echo -e "${RED}❌ Contenedor metin2-server NO está corriendo${NC}"
    echo ""
    echo "Intentando iniciar el contenedor..."
    if [ -f ".env" ]; then
        MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
        if [ "$MYSQL_HOST" = "localhost" ] || [ "$MYSQL_HOST" = "127.0.0.1" ]; then
            docker run -d --name metin2-server --restart unless-stopped --network host --env-file .env metin2/server:latest
        else
            docker run -d --name metin2-server --restart unless-stopped -p 12345:12345 -p 13200:13200 -p 8888:8888 --env-file .env metin2/server:latest
        fi
        sleep 5
    else
        echo -e "${RED}❌ Archivo .env no encontrado${NC}"
        exit 1
    fi
fi
echo ""

# 2. Verificar puertos escuchando
echo -e "${GREEN}🔍 2. Verificando puertos escuchando...${NC}"

# Verificar puerto 12345 (GAME_PORT)
if ss -tuln | grep -q ":12345"; then
    echo -e "${GREEN}✅ Puerto 12345 (GAME) está escuchando${NC}"
    ss -tuln | grep ":12345"
else
    echo -e "${RED}❌ Puerto 12345 (GAME) NO está escuchando${NC}"
fi

# Verificar puerto 13200 (P2P_PORT)
if ss -tuln | grep -q ":13200"; then
    echo -e "${GREEN}✅ Puerto 13200 (P2P) está escuchando${NC}"
    ss -tuln | grep ":13200"
else
    echo -e "${RED}❌ Puerto 13200 (P2P) NO está escuchando${NC}"
fi

# Verificar puerto 8888 (DB_PORT)
if ss -tuln | grep -q ":8888"; then
    echo -e "${GREEN}✅ Puerto 8888 (DB) está escuchando${NC}"
    ss -tuln | grep ":8888"
else
    echo -e "${RED}❌ Puerto 8888 (DB) NO está escuchando${NC}"
fi
echo ""

# 3. Verificar logs del servidor
echo -e "${GREEN}🔍 3. Verificando logs del servidor (últimas 30 líneas)...${NC}"
echo -e "${YELLOW}--- Logs del servidor ---${NC}"
docker logs --tail 30 metin2-server 2>&1 | tail -30
echo ""

# 4. Verificar errores críticos
echo -e "${GREEN}🔍 4. Buscando errores críticos...${NC}"
ERRORS_FOUND=0

if docker logs metin2-server 2>&1 | grep -q "Table.*doesn't exist"; then
    echo -e "${RED}❌ Error: Tablas faltantes en la base de datos${NC}"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
fi

if docker logs metin2-server 2>&1 | grep -q "AUTH_SERVER.*syntax error"; then
    echo -e "${RED}❌ Error: Configuración AUTH_SERVER incorrecta${NC}"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
fi

if docker logs metin2-server 2>&1 | grep -q "TCP listening"; then
    echo -e "${GREEN}✅ Servidor inició correctamente (TCP listening encontrado)${NC}"
else
    echo -e "${RED}❌ Servidor NO inició correctamente (no se encontró TCP listening)${NC}"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
fi

if docker logs metin2-server 2>&1 | grep -q "FAILED\|ERROR\|CRITICAL" | tail -10; then
    echo -e "${YELLOW}⚠️  Se encontraron errores en los logs${NC}"
    docker logs metin2-server 2>&1 | grep -i "FAILED\|ERROR\|CRITICAL" | tail -5
fi
echo ""

# 5. Verificar procesos dentro del contenedor
echo -e "${GREEN}🔍 5. Verificando procesos dentro del contenedor...${NC}"
if docker exec metin2-server ps aux | grep -q "game\|db"; then
    echo -e "${GREEN}✅ Procesos del servidor están corriendo${NC}"
    docker exec metin2-server ps aux | grep -E "game|db" | grep -v grep
else
    echo -e "${RED}❌ Procesos del servidor NO están corriendo${NC}"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
fi
echo ""

# Resumen
echo "=========================================="
echo "Resumen"
echo "=========================================="
if [ $ERRORS_FOUND -eq 0 ] && ss -tuln | grep -q ":12345"; then
    echo -e "${GREEN}✅ Servidor está activo y escuchando correctamente${NC}"
    echo ""
    echo "📋 Información de conexión:"
    PUBLIC_IP=$(grep "^PUBLIC_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "NO_CONFIGURADO")
    echo "   IP: $PUBLIC_IP"
    echo "   Puerto: 12345"
    exit 0
else
    echo -e "${RED}❌ Hay problemas con el servidor${NC}"
    echo ""
    echo "🔧 Próximos pasos:"
    echo "   1. Ver logs completos: docker logs -f metin2-server"
    echo "   2. Reiniciar servidor: docker restart metin2-server"
    echo "   3. Verificar base de datos: bash docker/verificar-y-crear-todo.sh"
    exit 1
fi

