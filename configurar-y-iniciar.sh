#!/bin/bash
# Script para configurar e iniciar el servidor después de la compilación
# Uso: bash configurar-y-iniciar.sh

set -e

echo "=========================================="
echo "Configuración Final - Metin2 Server"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar que estamos en el directorio correcto
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}❌ No se encontró Dockerfile. Ejecuta este script desde el directorio metin2-server${NC}"
    exit 1
fi

# Paso 1: Configurar base de datos
echo -e "${GREEN}📦 Paso 1: Configurando base de datos...${NC}"
echo ""

if [ -f "setup-database.sh" ]; then
    chmod +x setup-database.sh
    echo -e "${YELLOW}⚠️  Necesitarás la contraseña de root de MySQL${NC}"
    echo ""
    read -sp "Contraseña de root de MySQL: " MYSQL_ROOT_PASS
    echo ""
    
    bash setup-database.sh "$MYSQL_ROOT_PASS"
    
    # Leer contraseña generada si existe
    if [ -f "/tmp/metin2_db_password.txt" ]; then
        METIN2_DB_PASSWORD=$(cat /tmp/metin2_db_password.txt)
        echo ""
        echo -e "${GREEN}✅ Contraseña del usuario metin2: ${METIN2_DB_PASSWORD}${NC}"
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
CREATE USER IF NOT EXISTS 'metin2'@'%' IDENTIFIED BY '${METIN2_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON metin2_account.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_common.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_player.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_log.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_account.* TO 'metin2'@'%';
GRANT ALL PRIVILEGES ON metin2_common.* TO 'metin2'@'%';
GRANT ALL PRIVILEGES ON metin2_player.* TO 'metin2'@'%';
GRANT ALL PRIVILEGES ON metin2_log.* TO 'metin2'@'%';
FLUSH PRIVILEGES;
EOF
    echo -e "${GREEN}✅ Bases de datos creadas${NC}"
fi

# Paso 2: Crear archivo .env
echo ""
echo -e "${GREEN}⚙️ Paso 2: Configurando archivo .env...${NC}"

if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Archivo .env ya existe${NC}"
    read -p "¿Deseas sobrescribirlo? (s/N): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Ss]$ ]]; then
        echo "Manteniendo archivo .env existente"
        echo ""
        echo -e "${YELLOW}⚠️  Verifica que MYSQL_PASSWORD en .env sea: ${METIN2_DB_PASSWORD}${NC}"
    else
        OVERWRITE_ENV=true
    fi
else
    OVERWRITE_ENV=true
fi

if [ "$OVERWRITE_ENV" = true ]; then
    # Obtener IP pública si no está definida
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "72.61.12.2")
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
PUBLIC_IP=${PUBLIC_IP}
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
fi

# Paso 3: Verificar imagen Docker
echo ""
echo -e "${GREEN}🐳 Paso 3: Verificando imagen Docker...${NC}"
if ! docker images | grep -q "metin2/server"; then
    echo -e "${YELLOW}⚠️  Imagen Docker no encontrada. Construyendo...${NC}"
    docker build -t metin2/server:latest .
else
    echo -e "${GREEN}✅ Imagen Docker encontrada${NC}"
fi

# Paso 4: Detener contenedor existente si existe
echo ""
echo -e "${GREEN}🛑 Paso 4: Limpiando contenedores antiguos...${NC}"
docker stop metin2-server 2>/dev/null || true
docker rm metin2-server 2>/dev/null || true

# Paso 5: Iniciar servidor
echo ""
echo -e "${GREEN}🚀 Paso 5: Iniciando servidor...${NC}"
docker run -d \
  --name metin2-server \
  --restart unless-stopped \
  -p 12345:12345 \
  -p 13200:13200 \
  -p 8888:8888 \
  --env-file .env \
  metin2/server:latest

echo ""
echo -e "${GREEN}✅ Servidor iniciado!${NC}"
echo ""
echo "=========================================="
echo "Comandos útiles:"
echo "=========================================="
echo "  Ver logs:        docker logs -f metin2-server"
echo "  Ver estado:      docker ps"
echo "  Detener:         docker stop metin2-server"
echo "  Reiniciar:       docker restart metin2-server"
echo ""
echo "=========================================="
echo "Verificación:"
echo "=========================================="
echo "Esperando 5 segundos para verificar estado..."
sleep 5

if docker ps | grep -q "metin2-server"; then
    echo -e "${GREEN}✅ Contenedor está corriendo${NC}"
    echo ""
    echo "Verificando logs (últimas 20 líneas):"
    echo "----------------------------------------"
    docker logs --tail 20 metin2-server
else
    echo -e "${RED}❌ El contenedor no está corriendo${NC}"
    echo "Revisa los logs con: docker logs metin2-server"
fi

echo ""
echo -e "${GREEN}✅ Configuración completada!${NC}"

