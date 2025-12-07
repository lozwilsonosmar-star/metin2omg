#!/bin/bash
# Script para limpiar Docker y liberar espacio en disco
# Uso: bash docker/limpiar-docker.sh

set -e

echo "=========================================="
echo "Limpieza de Docker - Liberar Espacio"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar espacio antes
echo -e "${GREEN}📊 Espacio en disco ANTES de la limpieza:${NC}"
df -h / | tail -1
echo ""

# Verificar uso de Docker
echo -e "${GREEN}🐳 Uso de Docker:${NC}"
docker system df
echo ""

# Preguntar confirmación
read -p "¿Deseas continuar con la limpieza? Esto eliminará imágenes no usadas, contenedores detenidos, etc. (s/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
    echo "Limpieza cancelada"
    exit 0
fi

echo ""
echo -e "${YELLOW}🧹 Limpiando Docker...${NC}"

# 1. Detener y eliminar contenedores detenidos
echo -e "${YELLOW}   1. Eliminando contenedores detenidos...${NC}"
docker container prune -f

# 2. Eliminar imágenes no usadas (sin etiquetas)
echo -e "${YELLOW}   2. Eliminando imágenes no etiquetadas (dangling)...${NC}"
docker image prune -f

# 3. Eliminar imágenes no usadas (más agresivo)
echo -e "${YELLOW}   3. Eliminando imágenes no usadas...${NC}"
docker image prune -a -f

# 4. Eliminar volúmenes no usados
echo -e "${YELLOW}   4. Eliminando volúmenes no usados...${NC}"
docker volume prune -f

# 5. Eliminar redes no usadas
echo -e "${YELLOW}   5. Eliminando redes no usadas...${NC}"
docker network prune -f

# 6. Limpieza completa del sistema
echo -e "${YELLOW}   6. Limpieza completa del sistema Docker...${NC}"
docker system prune -a -f --volumes

# 7. Limpiar build cache (muy importante para liberar espacio)
echo -e "${YELLOW}   7. Limpiando build cache...${NC}"
docker builder prune -a -f

echo ""
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""

# Verificar espacio después
echo -e "${GREEN}📊 Espacio en disco DESPUÉS de la limpieza:${NC}"
df -h / | tail -1
echo ""

# Verificar uso de Docker después
echo -e "${GREEN}🐳 Uso de Docker después:${NC}"
docker system df
echo ""

echo -e "${GREEN}✅ Limpieza finalizada!${NC}"

