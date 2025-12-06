#!/bin/bash
# Script de deployment automático para VPS Ubuntu 24.04
# Uso: bash deploy-vps.sh

set -e

echo "=========================================="
echo "Deployment de Metin2 Server en VPS"
echo "=========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Por favor ejecuta con sudo:${NC}"
    echo "   sudo bash deploy-vps.sh"
    exit 1
fi

echo -e "${GREEN}📦 Paso 1: Actualizando sistema...${NC}"
apt-get update && apt-get upgrade -y

echo ""
echo -e "${GREEN}📦 Paso 2: Instalando dependencias básicas...${NC}"
apt-get install -y \
    git \
    docker.io \
    docker-compose \
    mariadb-server \
    mariadb-client \
    ufw \
    curl \
    wget

echo ""
echo -e "${GREEN}🐳 Paso 3: Configurando Docker...${NC}"
systemctl enable docker
systemctl start docker

echo ""
echo -e "${GREEN}🗄️ Paso 4: Configurando MariaDB...${NC}"
systemctl enable mariadb
systemctl start mariadb

echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE: Necesitas configurar MySQL manualmente${NC}"
echo "Ejecuta: mysql_secure_installation"
echo ""
read -p "¿Ya configuraste MySQL? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Por favor ejecuta: mysql_secure_installation"
    echo "Luego vuelve a ejecutar este script"
    exit 1
fi

echo ""
echo -e "${GREEN}📥 Paso 5: Clonando repositorio...${NC}"
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
echo -e "${GREEN}🔧 Paso 6: Instalando dependencias del proyecto...${NC}"
if [ -f "instalar-en-vps.sh" ]; then
    chmod +x instalar-en-vps.sh
    bash instalar-en-vps.sh
else
    echo -e "${YELLOW}⚠️  Script instalar-en-vps.sh no encontrado, instalando manualmente...${NC}"
    
    # Instalar Python 2.7
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update
    apt-get install -y python2.7
    ln -sf /usr/bin/python2.7 /usr/bin/python2
    
    # Instalar otras dependencias
    apt-get install -y \
        cmake \
        build-essential \
        libdevil-dev \
        libbsd-dev \
        libncurses5-dev
fi

echo ""
echo -e "${GREEN}🐳 Paso 7: Construyendo imagen Docker...${NC}"
docker build -t metin2/server:latest --provenance=false .

echo ""
echo -e "${GREEN}🗄️ Paso 8: Configurando base de datos...${NC}"

# Verificar si existe el script de setup de BD
if [ -f "setup-database.sh" ]; then
    chmod +x setup-database.sh
    echo "Ejecutando script automático de configuración de base de datos..."
    echo ""
    read -sp "Contraseña de root de MySQL: " MYSQL_ROOT_PASS
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
    read -sp "Contraseña de root de MySQL: " MYSQL_ROOT_PASS
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
echo -e "${GREEN}⚙️ Paso 9: Configurando archivo .env...${NC}"
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
# Database Configuration
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
    echo -e "${GREEN}✅ Archivo .env creado con la contraseña configurada${NC}"
else
    echo -e "${YELLOW}⚠️  Archivo .env ya existe. Verifica que MYSQL_PASSWORD sea correcto.${NC}"
fi

echo ""
echo -e "${GREEN}🔥 Paso 10: Configurando firewall...${NC}"
ufw --force enable
ufw allow 22/tcp
ufw allow 12345/tcp
ufw allow 13200/tcp
ufw allow 8888/tcp

echo ""
echo -e "${GREEN}🚀 Paso 11: Iniciando servidor...${NC}"
docker stop metin2-server 2>/dev/null || true
docker rm metin2-server 2>/dev/null || true

docker run -d \
  --name metin2-server \
  --restart unless-stopped \
  -p 12345:12345 \
  -p 13200:13200 \
  -p 8888:8888 \
  --env-file .env \
  metin2/server:latest

echo ""
echo -e "${GREEN}✅ Deployment completado!${NC}"
echo ""
echo "Verifica el estado con:"
echo "  docker ps"
echo "  docker logs metin2-server"
echo ""
echo "Para ver los logs en tiempo real:"
echo "  docker logs -f metin2-server"
echo ""

