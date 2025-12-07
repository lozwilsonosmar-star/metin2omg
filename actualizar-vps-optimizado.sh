#!/bin/bash
# Script para actualizar el servidor en el VPS con limpieza automática
# Uso: bash actualizar-vps-optimizado.sh

set -e

echo "=========================================="
echo "Actualización Optimizada de Metin2 Server"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Por favor ejecuta con sudo:${NC}"
    echo "   sudo bash actualizar-vps-optimizado.sh"
    exit 1
fi

# Verificar espacio antes
echo -e "${GREEN}📊 Espacio en disco disponible:${NC}"
df -h / | tail -1
echo ""

# Paso 0: Limpieza previa (opcional pero recomendado)
read -p "¿Deseas limpiar Docker antes de actualizar? (recomendado) (s/N): " CLEAN_BEFORE
if [[ "$CLEAN_BEFORE" =~ ^[Ss]$ ]]; then
    if [ -f "docker/limpiar-docker.sh" ]; then
        chmod +x docker/limpiar-docker.sh
        bash docker/limpiar-docker.sh
    else
        echo -e "${YELLOW}⚠️  Script de limpieza no encontrado, limpiando manualmente...${NC}"
        docker system prune -f
        docker builder prune -a -f
    fi
fi
echo ""

# Paso 1: Actualizar código desde Git
echo -e "${GREEN}📥 Paso 1: Actualizando código desde Git...${NC}"
cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    exit 1
}

# Guardar cambios locales si existen
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  Hay cambios locales. Guardándolos...${NC}"
    git stash
fi

# Actualizar desde el repositorio
git pull origin main

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al actualizar desde Git${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Código actualizado${NC}"
echo ""

# Paso 1.5: Verificar/crear bases de datos ANTES de compilar
echo -e "${GREEN}📊 Paso 1.5: Verificando/creando bases de datos y tablas...${NC}"

if [ -f ".env" ]; then
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
    MYSQL_PORT=$(grep "^MYSQL_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "3306")
    MYSQL_USER=$(grep "^MYSQL_USER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "metin2")
    MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "changeme")
    
    if [ "$MYSQL_HOST" = "localhost" ]; then
        MYSQL_HOST="127.0.0.1"
    fi
    
    export MYSQL_PWD="$MYSQL_PASSWORD"
    
    # Crear bases de datos si no existen
    echo -e "${YELLOW}   Creando bases de datos si no existen...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_account CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_common CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_player CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_log CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    
    # Ejecutar script SQL básico
    if [ -f "docker/create-all-tables.sql" ]; then
        echo -e "${YELLOW}   Creando/actualizando tablas...${NC}"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" < docker/create-all-tables.sql 2>&1 | grep -v "already exists" || true
        echo -e "${GREEN}   ✅ Bases de datos y tablas verificadas/creadas${NC}"
    fi
    
    unset MYSQL_PWD
else
    echo -e "${YELLOW}⚠️  No se encontró .env. Saltando verificación previa de BD${NC}"
fi

echo ""

# Paso 2: Detener contenedor actual
echo -e "${GREEN}🛑 Paso 2: Deteniendo contenedor actual...${NC}"
docker stop metin2-server 2>/dev/null || true
docker rm metin2-server 2>/dev/null || true
echo -e "${GREEN}✅ Contenedor detenido${NC}"
echo ""

# Paso 3: Limpiar imágenes antiguas antes de construir
echo -e "${GREEN}🧹 Paso 3: Limpiando imágenes antiguas...${NC}"
# Eliminar solo la imagen antigua de metin2/server (no todas)
docker images | grep "metin2/server" | grep -v "latest" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
# Limpiar build cache
docker builder prune -f
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""

# Paso 4: Reconstruir imagen Docker (con --no-cache solo si es necesario)
echo -e "${GREEN}🔨 Paso 4: Reconstruyendo imagen Docker...${NC}"
echo -e "${YELLOW}   Esto puede tardar varios minutos...${NC}"

# Usar BuildKit para mejor gestión de cache
export DOCKER_BUILDKIT=1

# Construir sin cache de capas intermedias innecesarias
docker build --rm --no-cache -t metin2/server:latest .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al construir la imagen Docker${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Imagen Docker reconstruida${NC}"
echo ""

# Paso 5: Crear/actualizar tablas en la base de datos
echo -e "${GREEN}📊 Paso 5: Verificando bases de datos...${NC}"

if [ -f ".env" ]; then
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
    MYSQL_PORT=$(grep "^MYSQL_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "3306")
    MYSQL_USER=$(grep "^MYSQL_USER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "metin2")
    MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "changeme")
    
    if [ "$MYSQL_HOST" = "localhost" ]; then
        MYSQL_HOST="127.0.0.1"
    fi
    
    export MYSQL_PWD="$MYSQL_PASSWORD"
    
    # Verificación exhaustiva
    if [ -f "docker/verificar-y-crear-todo.sh" ]; then
        chmod +x docker/verificar-y-crear-todo.sh
        bash docker/verificar-y-crear-todo.sh
    fi
    
    # Importar datos desde dumps SQL si existen
    if [ -f "docker/importar-datos-dump.sh" ] && [ -d "metin2_mysql_dump" ]; then
        chmod +x docker/importar-datos-dump.sh
        bash docker/importar-datos-dump.sh
    fi
    
    unset MYSQL_PWD
fi

echo ""

# Paso 6: Limpiar después de construir
echo -e "${GREEN}🧹 Paso 6: Limpiando después de construir...${NC}"
# Limpiar build cache
docker builder prune -f
# Eliminar imágenes intermedias
docker image prune -f
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""

# Paso 7: Iniciar contenedor
echo -e "${GREEN}🚀 Paso 7: Iniciando contenedor...${NC}"

MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
USE_HOST_NETWORK=false

if [ "$MYSQL_HOST" = "localhost" ] || [ "$MYSQL_HOST" = "127.0.0.1" ]; then
    echo -e "${YELLOW}⚠️  MySQL está configurado como localhost${NC}"
    echo -e "${YELLOW}   Usando --network host para acceder al MySQL del host${NC}"
    USE_HOST_NETWORK=true
fi

if [ "$USE_HOST_NETWORK" = true ]; then
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
    echo -e "${GREEN}✅ Contenedor iniciado correctamente${NC}"
    echo ""
    
    # Verificar espacio después
    echo -e "${GREEN}📊 Espacio en disco después de la actualización:${NC}"
    df -h / | tail -1
    echo ""
    
    echo -e "${GREEN}📋 Comandos útiles:${NC}"
    echo "   Ver logs: docker logs -f metin2-server"
    echo "   Detener: docker stop metin2-server"
    echo "   Reiniciar: docker restart metin2-server"
    echo "   Limpiar Docker: bash docker/limpiar-docker.sh"
    echo ""
    echo -e "${GREEN}✅ Actualización completada!${NC}"
else
    echo -e "${RED}❌ Error al iniciar el contenedor${NC}"
    exit 1
fi

