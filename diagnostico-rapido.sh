#!/bin/bash
# Script de diagnóstico rápido - Verifica el estado actual
# Uso: bash diagnostico-rapido.sh

echo "=========================================="
echo "DIAGNÓSTICO RÁPIDO - Metin2 Server"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ir al directorio
cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    echo "   Ejecuta: cd /opt/metin2omg"
    exit 1
}

echo -e "${BLUE}📂 Directorio: $(pwd)${NC}"
echo ""

# 1. Verificar contenedor
echo -e "${GREEN}1. Verificando contenedor Docker...${NC}"
if docker ps -a | grep -q "metin2-server"; then
    echo -e "${GREEN}✅ Contenedor existe${NC}"
    
    if docker ps | grep -q "metin2-server"; then
        echo -e "${GREEN}   ✅ Contenedor está CORRIENDO${NC}"
        CONTAINER_RUNNING=true
    else
        echo -e "${RED}   ❌ Contenedor está DETENIDO${NC}"
        CONTAINER_RUNNING=false
    fi
else
    echo -e "${RED}❌ Contenedor NO existe${NC}"
    CONTAINER_RUNNING=false
    CONTAINER_EXISTS=false
fi
echo ""

# 2. Verificar imagen Docker
echo -e "${GREEN}2. Verificando imagen Docker...${NC}"
if docker images | grep -q "metin2/server"; then
    echo -e "${GREEN}✅ Imagen Docker existe${NC}"
    docker images | grep "metin2/server" | head -1
    IMAGE_EXISTS=true
else
    echo -e "${RED}❌ Imagen Docker NO existe${NC}"
    IMAGE_EXISTS=false
fi
echo ""

# 3. Verificar archivo .env
echo -e "${GREEN}3. Verificando archivo .env...${NC}"
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ Archivo .env existe${NC}"
    PUBLIC_IP=$(grep "^PUBLIC_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "NO_CONFIGURADO")
    echo -e "${BLUE}   PUBLIC_IP: $PUBLIC_IP${NC}"
    ENV_EXISTS=true
else
    echo -e "${RED}❌ Archivo .env NO existe${NC}"
    ENV_EXISTS=false
fi
echo ""

# 4. Verificar puertos
echo -e "${GREEN}4. Verificando puertos escuchando...${NC}"
PORTS_LISTENING=0
if ss -tuln 2>/dev/null | grep -q ":12345"; then
    echo -e "${GREEN}✅ Puerto 12345 (GAME) está escuchando${NC}"
    PORTS_LISTENING=$((PORTS_LISTENING + 1))
else
    echo -e "${RED}❌ Puerto 12345 (GAME) NO está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":8888"; then
    echo -e "${GREEN}✅ Puerto 8888 (DB) está escuchando${NC}"
    PORTS_LISTENING=$((PORTS_LISTENING + 1))
else
    echo -e "${RED}❌ Puerto 8888 (DB) NO está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":13200"; then
    echo -e "${GREEN}✅ Puerto 13200 (P2P) está escuchando${NC}"
    PORTS_LISTENING=$((PORTS_LISTENING + 1))
else
    echo -e "${RED}❌ Puerto 13200 (P2P) NO está escuchando${NC}"
fi
echo ""

# 5. Verificar logs (si el contenedor existe)
if [ "$CONTAINER_RUNNING" = true ] || docker ps -a | grep -q "metin2-server"; then
    echo -e "${GREEN}5. Últimas líneas de logs:${NC}"
    docker logs --tail 10 metin2-server 2>&1 | tail -10
    echo ""
fi

# Resumen y recomendaciones
echo "=========================================="
echo "RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""

if [ "$CONTAINER_EXISTS" = false ] && [ "$IMAGE_EXISTS" = false ]; then
    echo -e "${RED}❌ PROBLEMA: No hay contenedor ni imagen${NC}"
    echo ""
    echo -e "${YELLOW}🔧 SOLUCIÓN:${NC}"
    echo "   Ejecuta el setup completo:"
    echo "   sudo bash setup-completo-vps.sh"
    echo ""
    echo "   Esto construirá la imagen y creará el contenedor"
    
elif [ "$CONTAINER_EXISTS" = true ] && [ "$CONTAINER_RUNNING" = false ]; then
    echo -e "${YELLOW}⚠️  PROBLEMA: Contenedor existe pero está detenido${NC}"
    echo ""
    echo -e "${YELLOW}🔧 SOLUCIÓN:${NC}"
    echo "   Iniciar el contenedor:"
    echo "   docker start metin2-server"
    echo ""
    echo "   O usar el script simple:"
    echo "   sudo bash iniciar-servidor-simple.sh"
    
elif [ "$CONTAINER_RUNNING" = true ] && [ $PORTS_LISTENING -eq 0 ]; then
    echo -e "${YELLOW}⚠️  PROBLEMA: Contenedor corre pero puertos no escuchan${NC}"
    echo ""
    echo -e "${YELLOW}🔧 SOLUCIÓN:${NC}"
    echo "   El servidor puede estar iniciando. Espera 30-60 segundos y verifica:"
    echo "   ss -tuln | grep -E '12345|8888'"
    echo ""
    echo "   O ver logs para diagnosticar:"
    echo "   docker logs -f metin2-server"
    
elif [ "$CONTAINER_RUNNING" = true ] && [ $PORTS_LISTENING -gt 0 ]; then
    echo -e "${GREEN}✅ TODO ESTÁ BIEN!${NC}"
    echo ""
    echo -e "${GREEN}El servidor está corriendo y los puertos están escuchando${NC}"
    echo ""
    PUBLIC_IP=$(grep "^PUBLIC_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "NO_CONFIGURADO")
    echo -e "${BLUE}🎮 Configuración del Cliente:${NC}"
    echo "   IP: $PUBLIC_IP"
    echo "   Puerto: 12345"
    
else
    echo -e "${YELLOW}⚠️  Estado desconocido${NC}"
    echo ""
    echo "Verifica manualmente:"
    echo "   docker ps -a"
    echo "   docker logs metin2-server"
fi

echo ""

