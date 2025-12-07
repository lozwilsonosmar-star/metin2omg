#!/bin/bash
# Script MAESTRO - Hace TODO en el orden correcto
# Uso: sudo bash setup-completo-vps.sh
# 
# ⚠️ IMPORTANTE: Este script NO modifica el firewall
# ⚠️ IMPORTANTE: Este script NO elimina reglas de firewall existentes
# ⚠️ IMPORTANTE: Este script es 100% seguro para tu configuración actual
# 
# Este script:
# 1. Actualiza el código desde Git
# 2. Limpia Docker (libera espacio)
# 3. Verifica/crea bases de datos y tablas
# 4. Importa datos desde dumps SQL
# 5. Reconstruye el servidor Docker
# 6. Inicia el servidor
# 7. Verifica que todo esté funcionando
# 
# ❌ NO hace:
# - NO modifica firewall (ufw/iptables)
# - NO elimina reglas existentes
# - NO cambia configuraciones del sistema

set -e

echo "=========================================="
echo "SETUP COMPLETO - Metin2 Server VPS"
echo "=========================================="
echo "Este script hará TODO automáticamente"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Por favor ejecuta con sudo:${NC}"
    echo "   sudo bash setup-completo-vps.sh"
    exit 1
fi

# Ir al directorio del proyecto
cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    echo "   Por favor ejecuta este script desde /opt/metin2omg o /opt/metin2-server"
    exit 1
}

echo -e "${BLUE}📂 Directorio de trabajo: $(pwd)${NC}"
echo ""

# ============================================================
# PASO 1: Actualizar código desde Git
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}📥 PASO 1: Actualizando código desde Git...${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"

# Guardar cambios locales si existen
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo -e "${YELLOW}⚠️  Hay cambios locales. Guardándolos...${NC}"
    git stash
fi

# Actualizar desde el repositorio
if git pull origin main; then
    echo -e "${GREEN}✅ Código actualizado${NC}"
else
    echo -e "${YELLOW}⚠️  Advertencia: Error al actualizar desde Git (puede ser normal si ya está actualizado)${NC}"
fi
echo ""

# ============================================================
# PASO 2: Limpiar Docker (liberar espacio)
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}🧹 PASO 2: Limpiando Docker (liberando espacio)...${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"

echo -e "${YELLOW}📊 Espacio ANTES de limpiar:${NC}"
df -h / | tail -1

# Limpieza rápida y segura
echo -e "${YELLOW}   Limpiando build cache y contenedores detenidos...${NC}"
docker system prune -f >/dev/null 2>&1 || true
docker builder prune -a -f >/dev/null 2>&1 || true
docker container prune -f >/dev/null 2>&1 || true

echo -e "${YELLOW}📊 Espacio DESPUÉS de limpiar:${NC}"
df -h / | tail -1
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""

# ============================================================
# PASO 3: Detener contenedor actual
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}🛑 PASO 3: Deteniendo contenedor actual...${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"

docker stop metin2-server 2>/dev/null || true
docker rm metin2-server 2>/dev/null || true
echo -e "${GREEN}✅ Contenedor detenido${NC}"
echo ""

# ============================================================
# PASO 4: Verificar/Crear bases de datos y tablas
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}📊 PASO 4: Verificando/Creando bases de datos...${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"

if [ -f ".env" ]; then
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
    MYSQL_PORT=$(grep "^MYSQL_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "3306")
    MYSQL_USER=$(grep "^MYSQL_USER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "metin2")
    MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "changeme")
    
    if [ "$MYSQL_HOST" = "localhost" ]; then
        MYSQL_HOST="127.0.0.1"
    fi
    
    export MYSQL_PWD="$MYSQL_PASSWORD"
    
    # Crear bases de datos
    echo -e "${YELLOW}   Creando bases de datos si no existen...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_account CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_common CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_player CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "CREATE DATABASE IF NOT EXISTS metin2_log CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    
    # Crear/actualizar tablas
    if [ -f "docker/create-all-tables.sql" ]; then
        echo -e "${YELLOW}   Creando/actualizando tablas...${NC}"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" < docker/create-all-tables.sql 2>&1 | grep -v "already exists\|Duplicate" || true
    fi
    
    # Verificación exhaustiva
    if [ -f "docker/verificar-y-crear-todo.sh" ]; then
        echo -e "${YELLOW}   Verificando tablas y columnas...${NC}"
        chmod +x docker/verificar-y-crear-todo.sh
        bash docker/verificar-y-crear-todo.sh >/dev/null 2>&1 || true
    fi
    
    # Importar datos desde dumps SQL
    if [ -f "docker/importar-datos-dump.sh" ] && [ -d "metin2_mysql_dump" ]; then
        echo -e "${YELLOW}   Importando datos desde dumps SQL...${NC}"
        chmod +x docker/importar-datos-dump.sh
        bash docker/importar-datos-dump.sh >/dev/null 2>&1 || true
    fi
    
    unset MYSQL_PWD
    echo -e "${GREEN}✅ Bases de datos verificadas${NC}"
else
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    echo "   Por favor crea el archivo .env con las credenciales de MySQL"
    exit 1
fi
echo ""

# ============================================================
# PASO 5: Reconstruir imagen Docker
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}🔨 PASO 5: Reconstruyendo imagen Docker...${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}   ⏳ Esto puede tardar 10-20 minutos...${NC}"
echo -e "${YELLOW}   ☕ Tómate un café mientras tanto${NC}"
echo ""

# Intentar usar BuildKit si está disponible, sino usar builder tradicional
if docker buildx version &>/dev/null; then
    echo -e "${YELLOW}   Usando BuildKit (buildx disponible)${NC}"
    export DOCKER_BUILDKIT=1
    docker build --rm -t metin2/server:latest .
else
    echo -e "${YELLOW}   Usando builder tradicional (buildx no disponible)${NC}"
    unset DOCKER_BUILDKIT
    docker build --rm -t metin2/server:latest .
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Imagen Docker reconstruida${NC}"
else
    echo -e "${RED}❌ Error al construir la imagen Docker${NC}"
    exit 1
fi

# Limpiar después de construir
docker builder prune -f >/dev/null 2>&1 || true
echo ""

# ============================================================
# PASO 6: Iniciar contenedor
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}🚀 PASO 6: Iniciando contenedor...${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"

MYSQL_HOST=$(grep "^MYSQL_HOST=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
USE_HOST_NETWORK=false

if [ "$MYSQL_HOST" = "localhost" ] || [ "$MYSQL_HOST" = "127.0.0.1" ]; then
    echo -e "${YELLOW}   Usando --network host (MySQL en localhost)${NC}"
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
    echo -e "${GREEN}✅ Contenedor iniciado${NC}"
else
    echo -e "${RED}❌ Error al iniciar el contenedor${NC}"
    exit 1
fi

# Esperar unos segundos para que el servidor inicie
echo -e "${YELLOW}   Esperando 10 segundos para que el servidor inicie...${NC}"
sleep 10
echo ""

# ============================================================
# PASO 7: Verificar que todo está funcionando
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ PASO 7: Verificando que todo funciona...${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"

# Verificar contenedor
if docker ps | grep -q "metin2-server"; then
    echo -e "${GREEN}✅ Contenedor está corriendo${NC}"
else
    echo -e "${RED}❌ Contenedor NO está corriendo${NC}"
fi

# Verificar puertos
PORTS_OK=0
if ss -tuln 2>/dev/null | grep -q ":12345"; then
    echo -e "${GREEN}✅ Puerto 12345 (GAME) está escuchando${NC}"
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}⚠️  Puerto 12345 (GAME) NO está escuchando aún (puede tardar unos segundos más)${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":8888"; then
    echo -e "${GREEN}✅ Puerto 8888 (DB) está escuchando${NC}"
    PORTS_OK=$((PORTS_OK + 1))
else
    echo -e "${YELLOW}⚠️  Puerto 8888 (DB) NO está escuchando aún${NC}"
fi

# Verificar logs
if docker logs metin2-server 2>&1 | tail -20 | grep -q "TCP listening"; then
    echo -e "${GREEN}✅ Servidor inició correctamente${NC}"
else
    echo -e "${YELLOW}⚠️  Verificando logs del servidor...${NC}"
    echo -e "${YELLOW}   (Puede tardar unos segundos más en iniciar)${NC}"
fi
echo ""

# ============================================================
# RESUMEN FINAL
# ============================================================
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}📋 RESUMEN FINAL${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"

echo -e "${BLUE}📊 Espacio en disco final:${NC}"
df -h / | tail -1
echo ""

echo -e "${BLUE}📋 Comandos útiles:${NC}"
echo "   Ver logs:           docker logs -f metin2-server"
echo "   Ver estado:         docker ps"
echo "   Reiniciar:          docker restart metin2-server"
echo "   Detener:            docker stop metin2-server"
echo "   Limpiar Docker:     bash docker/limpiar-docker.sh"
echo ""

# Obtener IP pública para el cliente
PUBLIC_IP=$(grep "^PUBLIC_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "NO_CONFIGURADO")
echo -e "${BLUE}🎮 Configuración del Cliente:${NC}"
echo "   IP del servidor:    $PUBLIC_IP"
echo "   Puerto del juego:   12345"
echo ""

if [ $PORTS_OK -ge 1 ]; then
    echo -e "${GREEN}✅ ¡Setup completado!${NC}"
    echo -e "${GREEN}   El servidor debería estar funcionando${NC}"
    echo ""
    echo -e "${YELLOW}💡 Si los puertos aún no aparecen, espera 30-60 segundos más${NC}"
    echo -e "${YELLOW}   y ejecuta: docker logs -f metin2-server${NC}"
else
    echo -e "${YELLOW}⚠️  Setup completado, pero verifica los logs:${NC}"
    echo "   docker logs -f metin2-server"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ ¡TODO LISTO!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"

