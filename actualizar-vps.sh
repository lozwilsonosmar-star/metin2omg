#!/bin/bash
# Script para actualizar el servidor en el VPS con los nuevos cambios
# Uso: bash actualizar-vps.sh

set -e

echo "=========================================="
echo "Actualización de Metin2 Server en VPS"
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
    echo "   sudo bash actualizar-vps.sh"
    exit 1
fi

# Paso 1: Actualizar código desde Git
echo -e "${GREEN}📥 Paso 1: Actualizando código desde Git...${NC}"
cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    echo "   Por favor ejecuta este script desde el directorio del proyecto"
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

# Paso 2: Detener contenedor actual
echo -e "${GREEN}🛑 Paso 2: Deteniendo contenedor actual...${NC}"
docker stop metin2-server 2>/dev/null || true
docker rm metin2-server 2>/dev/null || true
echo -e "${GREEN}✅ Contenedor detenido${NC}"
echo ""

# Paso 3: Reconstruir imagen Docker
echo -e "${GREEN}🔨 Paso 3: Reconstruyendo imagen Docker...${NC}"
echo -e "${YELLOW}   Esto puede tardar varios minutos...${NC}"
docker build -t metin2/server:latest .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al construir la imagen Docker${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Imagen Docker reconstruida${NC}"
echo ""

# Paso 4: Crear/actualizar tablas en la base de datos
echo -e "${GREEN}📊 Paso 4: Creando/actualizando tablas en la base de datos...${NC}"

# Obtener credenciales de MySQL desde .env si existe
if [ -f ".env" ]; then
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
    MYSQL_PORT=$(grep "^MYSQL_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "3306")
    MYSQL_USER=$(grep "^MYSQL_USER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "metin2")
    MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "changeme")
    
    # Convertir localhost a 127.0.0.1
    if [ "$MYSQL_HOST" = "localhost" ]; then
        MYSQL_HOST="127.0.0.1"
    fi
    
    echo -e "${YELLOW}   Usando credenciales de .env${NC}"
    echo -e "${YELLOW}   Host: ${MYSQL_HOST}:${MYSQL_PORT}${NC}"
    echo -e "${YELLOW}   Usuario: ${MYSQL_USER}${NC}"
    echo ""
    
    # Ejecutar script SQL
    if [ -f "docker/create-all-tables.sql" ]; then
        export MYSQL_PWD="$MYSQL_PASSWORD"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" < docker/create-all-tables.sql
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Tablas creadas/actualizadas correctamente${NC}"
        else
            echo -e "${YELLOW}⚠️  Advertencia: Algunas tablas pueden no haberse creado${NC}"
            echo -e "${YELLOW}   Esto es normal si ya existían${NC}"
        fi
        unset MYSQL_PWD
    else
        echo -e "${RED}❌ No se encontró docker/create-all-tables.sql${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No se encontró archivo .env${NC}"
    echo -e "${YELLOW}   Ejecutando script SQL manualmente...${NC}"
    echo -e "${YELLOW}   Por favor ejecuta: mysql -u root -p < docker/create-all-tables.sql${NC}"
fi

echo ""

# Paso 5: Iniciar contenedor
echo -e "${GREEN}🚀 Paso 5: Iniciando contenedor...${NC}"

# Verificar si MySQL está en localhost (host)
MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
USE_HOST_NETWORK=false

if [ "$MYSQL_HOST" = "localhost" ] || [ "$MYSQL_HOST" = "127.0.0.1" ]; then
    echo -e "${YELLOW}⚠️  MySQL está configurado como localhost${NC}"
    echo -e "${YELLOW}   Usando --network host para acceder al MySQL del host${NC}"
    USE_HOST_NETWORK=true
fi

if [ "$USE_HOST_NETWORK" = true ]; then
    # Usar --network host para acceder directamente al MySQL del host
    docker run -d \
      --name metin2-server \
      --restart unless-stopped \
      --network host \
      --env-file .env \
      metin2/server:latest
else
    # Usar mapeo de puertos normal
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
    echo -e "${GREEN}📋 Comandos útiles:${NC}"
    echo "   Ver logs: docker logs -f metin2-server"
    echo "   Detener: docker stop metin2-server"
    echo "   Reiniciar: docker restart metin2-server"
    echo ""
    echo -e "${GREEN}✅ Actualización completada!${NC}"
else
    echo -e "${RED}❌ Error al iniciar el contenedor${NC}"
    exit 1
fi

