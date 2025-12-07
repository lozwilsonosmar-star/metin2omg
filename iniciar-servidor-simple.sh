#!/bin/bash
# Script simple para iniciar el servidor si no está corriendo
# Uso: sudo bash iniciar-servidor-simple.sh

set -e

echo "=========================================="
echo "Iniciar Servidor Metin2"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ir al directorio
cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    exit 1
}

# Verificar si el contenedor existe
if docker ps -a | grep -q "metin2-server"; then
    echo -e "${YELLOW}📦 Contenedor encontrado${NC}"
    
    # Verificar si está corriendo
    if docker ps | grep -q "metin2-server"; then
        echo -e "${GREEN}✅ Contenedor ya está corriendo${NC}"
        echo ""
        echo "Ver logs: docker logs -f metin2-server"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Contenedor existe pero está detenido${NC}"
        echo -e "${YELLOW}   Iniciando contenedor...${NC}"
        docker start metin2-server
        echo -e "${GREEN}✅ Contenedor iniciado${NC}"
        echo ""
        echo "Esperando 15 segundos para que el servidor inicie..."
        sleep 15
    fi
else
    echo -e "${YELLOW}⚠️  Contenedor no existe. Creando nuevo contenedor...${NC}"
    
    # Verificar que existe .env
    if [ ! -f ".env" ]; then
        echo -e "${RED}❌ Archivo .env no encontrado${NC}"
        echo "   Por favor crea el archivo .env con las credenciales de MySQL"
        exit 1
    fi
    
    # Obtener configuración
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
    
    # Crear contenedor
    if [ "$MYSQL_HOST" = "localhost" ] || [ "$MYSQL_HOST" = "127.0.0.1" ]; then
        echo -e "${YELLOW}   Usando --network host (MySQL en localhost)${NC}"
        docker run -d \
          --name metin2-server \
          --restart unless-stopped \
          --network host \
          --env-file .env \
          metin2/server:latest
    else
        echo -e "${YELLOW}   Usando mapeo de puertos${NC}"
        docker run -d \
          --name metin2-server \
          --restart unless-stopped \
          -p 12345:12345 \
          -p 13200:13200 \
          -p 8888:8888 \
          --env-file .env \
          metin2/server:latest
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Contenedor creado e iniciado${NC}"
        echo ""
        echo "Esperando 15 segundos para que el servidor inicie..."
        sleep 15
    else
        echo -e "${RED}❌ Error al crear el contenedor${NC}"
        exit 1
    fi
fi

# Verificar que está corriendo
echo ""
echo -e "${GREEN}🔍 Verificando estado...${NC}"
if docker ps | grep -q "metin2-server"; then
    echo -e "${GREEN}✅ Contenedor está corriendo${NC}"
else
    echo -e "${RED}❌ Contenedor NO está corriendo${NC}"
    echo ""
    echo "Ver logs para diagnosticar:"
    echo "   docker logs metin2-server"
    exit 1
fi

# Verificar puertos
echo ""
echo -e "${GREEN}🔍 Verificando puertos...${NC}"
sleep 5

PORTS_FOUND=0
if ss -tuln 2>/dev/null | grep -q ":12345"; then
    echo -e "${GREEN}✅ Puerto 12345 (GAME) está escuchando${NC}"
    PORTS_FOUND=$((PORTS_FOUND + 1))
else
    echo -e "${YELLOW}⚠️  Puerto 12345 (GAME) aún NO está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":8888"; then
    echo -e "${GREEN}✅ Puerto 8888 (DB) está escuchando${NC}"
    PORTS_FOUND=$((PORTS_FOUND + 1))
else
    echo -e "${YELLOW}⚠️  Puerto 8888 (DB) aún NO está escuchando${NC}"
fi

# Mostrar logs recientes
echo ""
echo -e "${GREEN}📋 Últimas líneas de logs:${NC}"
docker logs --tail 20 metin2-server 2>&1 | tail -20

echo ""
if [ $PORTS_FOUND -gt 0 ]; then
    echo -e "${GREEN}✅ Servidor iniciado correctamente${NC}"
    echo ""
    echo "📋 Comandos útiles:"
    echo "   Ver logs: docker logs -f metin2-server"
    echo "   Ver estado: docker ps"
else
    echo -e "${YELLOW}⚠️  El servidor está iniciando, pero los puertos aún no están listos${NC}"
    echo ""
    echo "💡 Espera 30-60 segundos más y verifica:"
    echo "   ss -tuln | grep -E '12345\|8888'"
    echo ""
    echo "📋 Ver logs en tiempo real:"
    echo "   docker logs -f metin2-server"
fi

