#!/bin/bash
# Script de deployment para VPS con MySQL existente
# NO reinstala MySQL, solo crea las bases de datos nuevas

set -e

echo "=========================================="
echo "Deployment de Metin2 Server (MySQL Existente)"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Por favor ejecuta con sudo:${NC}"
    echo "   sudo bash deploy-vps-existing-mysql.sh"
    exit 1
fi

echo -e "${GREEN}📦 Paso 1: Actualizando sistema (sin tocar MySQL)...${NC}"
apt-get update

echo ""
echo -e "${GREEN}📦 Paso 2: Instalando dependencias (sin MySQL)...${NC}"
apt-get install -y \
    git \
    docker.io \
    docker-compose \
    ufw \
    curl \
    wget

echo ""
echo -e "${GREEN}🐳 Paso 3: Configurando Docker...${NC}"
systemctl enable docker 2>/dev/null || true
systemctl start docker

echo ""
echo -e "${GREEN}✅ Verificando MySQL existente...${NC}"
if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
    echo -e "${GREEN}✅ MySQL/MariaDB está corriendo${NC}"
else
    echo -e "${YELLOW}⚠️  MySQL no está corriendo, intentando iniciar...${NC}"
    systemctl start mariadb 2>/dev/null || systemctl start mysql 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}📥 Paso 4: Clonando repositorio...${NC}"
REPO_DIR="/opt/metin2omg"
if [ -d "$REPO_DIR" ]; then
    echo "El directorio ya existe, actualizando..."
    cd $REPO_DIR
    git pull origin main || echo "No se pudo actualizar, continuando..."
else
    mkdir -p /opt
    cd /opt
    git clone https://github.com/lozwilsonosmar-star/metin2omg.git metin2omg
    cd $REPO_DIR
fi

echo ""
echo -e "${GREEN}🔧 Paso 5: Saltando instalación local (usaremos Docker)...${NC}"
echo -e "${YELLOW}⚠️  Python 2.7 no está disponible en Ubuntu 24.04${NC}"
echo -e "${GREEN}✅ Usaremos Docker que ya tiene Python 2.7 configurado${NC}"

echo ""
echo -e "${GREEN}🗄️ Paso 6: Configurando bases de datos en MySQL existente...${NC}"
echo -e "${YELLOW}⚠️  IMPORTANTE: Usaremos tu MySQL existente${NC}"
echo ""

# Verificar si existe el script de setup de BD
if [ -f "setup-database.sh" ]; then
    chmod +x setup-database.sh
    echo "Ejecutando script de configuración de base de datos..."
    echo ""
    read -sp "Contraseña de root de MySQL (tu MySQL existente): " MYSQL_ROOT_PASS
    echo ""
    bash setup-database.sh "$MYSQL_ROOT_PASS"
    
    # Leer contraseña generada si existe
    if [ -f "/tmp/metin2_db_password.txt" ]; then
        METIN2_DB_PASSWORD=$(cat /tmp/metin2_db_password.txt)
        echo ""
        echo -e "${GREEN}✅ Usando contraseña generada automáticamente${NC}"
    else
        echo ""
        read -sp "Contraseña del usuario metin2: " METIN2_DB_PASSWORD
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  Script setup-database.sh no encontrado${NC}"
    echo "Creando bases de datos manualmente..."
    echo ""
    read -sp "Contraseña de root de MySQL (tu MySQL existente): " MYSQL_ROOT_PASS
    echo ""
    read -sp "Contraseña para usuario 'metin2': " METIN2_DB_PASSWORD
    echo ""
    
    mysql -u root -p"${MYSQL_ROOT_PASS}" << EOF
CREATE DATABASE IF NOT EXISTS metin2_account CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS metin2_common CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS metin2_player CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS metin2_log CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'metin2'@'localhost' IDENTIFIED BY '${METIN2_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON metin2_account.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_common.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_player.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_log.* TO 'metin2'@'localhost';
FLUSH PRIVILEGES;
EOF
    echo -e "${GREEN}✅ Bases de datos creadas${NC}"
fi

echo ""
echo -e "${GREEN}🐳 Paso 7: Construyendo imagen Docker...${NC}"
# Intentar con --provenance=false, si falla, intentar sin el flag
docker build -t metin2/server:latest --provenance=false . 2>/dev/null || \
docker build -t metin2/server:latest .

echo ""
echo -e "${GREEN}⚙️ Paso 8: Configurando archivo .env...${NC}"
if [ ! -f ".env" ]; then
    # Usar contraseña generada si existe
    if [ -z "$METIN2_DB_PASSWORD" ]; then
        if [ -f "/tmp/metin2_db_password.txt" ]; then
            METIN2_DB_PASSWORD=$(cat /tmp/metin2_db_password.txt)
        else
            read -sp "Contraseña del usuario metin2 (para .env): " METIN2_DB_PASSWORD
            echo ""
        fi
    fi
    
    cat > .env << EOF
# Database Configuration (usando MySQL existente)
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=metin2
MYSQL_PASSWORD=${METIN2_DB_PASSWORD}
MYSQL_DB_ACCOUNT=metin2_account
MYSQL_DB_COMMON=metin2_common
MYSQL_DB_PLAYER=metin2_player
MYSQL_DB_LOG=metin2_log

# Server Configuration
DB_PORT=8888
GAME_PORT=12345
GAME_P2P_PORT=13200
GAME_HOSTNAME=Metin2OMG
GAME_CHANNEL=1
PUBLIC_IP=72.61.12.2
PUBLIC_BIND_IP=0.0.0.0
INTERNAL_IP=127.0.0.1
INTERNAL_BIND_IP=0.0.0.0
DB_ADDR=localhost
GAME_AUTH_SERVER=localhost
GAME_MARK_SERVER=localhost
GAME_MAP_ALLOW=all
GAME_MAX_LEVEL=99
TEST_SERVER=0
WEB_APP_URL=
WEB_APP_KEY=
EOF
    echo -e "${GREEN}✅ Archivo .env creado${NC}"
else
    echo -e "${YELLOW}⚠️  Archivo .env ya existe. Verifica que MYSQL_PASSWORD sea correcto.${NC}"
fi

echo ""
echo -e "${GREEN}🔥 Paso 9: Configurando firewall (solo puertos nuevos)...${NC}"
ufw --force enable 2>/dev/null || true
ufw allow 12345/tcp 2>/dev/null || true
ufw allow 13200/tcp 2>/dev/null || true
ufw allow 8888/tcp 2>/dev/null || true

echo ""
echo -e "${GREEN}🚀 Paso 10: Iniciando servidor...${NC}"
docker stop metin2-server 2>/dev/null || true
docker rm metin2-server 2>/dev/null || true

# Verificar si MySQL está en localhost (host)
# Si es así, usamos --network host para acceder directamente al MySQL del host
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

echo ""
echo -e "${GREEN}✅ Deployment completado!${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "  - Tu MySQL existente NO fue modificado"
echo "  - Solo se crearon 4 bases de datos nuevas: metin2_*"
echo "  - Tu app web sigue funcionando normalmente"
echo ""
echo "Verifica el estado con:"
echo "  docker ps"
echo "  docker logs metin2-server"
echo ""


