#!/bin/bash
# Script para recompilar el servidor SIN usar caché de Docker
# Esto asegura que los cambios en el código se incluyan

echo "=========================================="
echo "Recompilación SIN Caché de Docker"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    exit 1
}

echo -e "${YELLOW}⚠️  Esto forzará la recompilación completa (sin caché)${NC}"
echo -e "${YELLOW}   ⏳ Puede tardar 15-25 minutos...${NC}"
echo ""

# 1. Detener y eliminar contenedor actual
echo -e "${GREEN}1. Deteniendo contenedor actual...${NC}"
docker stop metin2-server 2>/dev/null || true
docker rm metin2-server 2>/dev/null || true
echo -e "${GREEN}✅ Contenedor detenido${NC}"
echo ""

# 2. Limpiar build cache
echo -e "${GREEN}2. Limpiando build cache de Docker...${NC}"
docker builder prune -a -f >/dev/null 2>&1 || true
echo -e "${GREEN}✅ Build cache limpiado${NC}"
echo ""

# 3. Asegurar que tenemos los últimos cambios
echo -e "${GREEN}3. Actualizando código desde Git...${NC}"
git pull origin main
echo -e "${GREEN}✅ Código actualizado${NC}"
echo ""

# 4. Reconstruir SIN caché
echo -e "${GREEN}4. Reconstruyendo imagen Docker (SIN caché)...${NC}"
echo -e "${YELLOW}   ⏳ Esto puede tardar 15-25 minutos...${NC}"
echo -e "${YELLOW}   ☕ Tómate un café mientras tanto${NC}"
echo ""

# Usar BuildKit si está disponible
if docker buildx version &>/dev/null; then
    export DOCKER_BUILDKIT=1
    docker build --rm --no-cache -t metin2/server:latest .
else
    unset DOCKER_BUILDKIT
    docker build --rm --no-cache -t metin2/server:latest .
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Imagen Docker reconstruida (sin caché)${NC}"
else
    echo -e "${RED}❌ Error al construir la imagen Docker${NC}"
    exit 1
fi
echo ""

# 5. Limpiar después de construir
echo -e "${GREEN}5. Limpiando build cache después de construir...${NC}"
docker builder prune -f >/dev/null 2>&1 || true
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""

# 6. Iniciar contenedor
echo -e "${GREEN}6. Iniciando contenedor...${NC}"
MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")

if [ "$MYSQL_HOST" = "localhost" ] || [ "$MYSQL_HOST" = "127.0.0.1" ]; then
    docker run -d \
      --name metin2-server \
      --restart unless-stopped \
      --network host \
      --env-file .env \
      metin2/server:latest
else
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
    echo -e "${GREEN}✅ Contenedor iniciado${NC}"
else
    echo -e "${RED}❌ Error al iniciar el contenedor${NC}"
    exit 1
fi
echo ""

# 7. Esperar y verificar
echo -e "${GREEN}7. Esperando 30 segundos para que el servidor inicie...${NC}"
sleep 30
echo ""

echo -e "${GREEN}8. Verificando estado...${NC}"
bash verificar-estado-servidor.sh

echo ""
echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
echo "El servidor ha sido recompilado SIN usar caché."
echo "Todos los cambios en el código deberían estar incluidos."
echo ""
echo "Para verificar que el cambio de fase funciona:"
echo "  1. Conecta el cliente"
echo "  2. Revisa los logs: docker logs -f metin2-server | grep -E 'AuthLogin|PHASE_SELECT'"
echo "  3. Deberías ver: 'AuthLogin: Changed phase to PHASE_SELECT'"
echo ""

