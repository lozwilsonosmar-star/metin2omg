#!/bin/bash
# Script para iniciar el servidor (asumiendo que la BD ya está configurada)
# Uso: bash iniciar-servidor.sh

set -e

echo "=========================================="
echo "Iniciando Metin2 Server"
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

# Verificar archivo .env
echo -e "${GREEN}⚙️ Verificando archivo .env...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Archivo .env no encontrado${NC}"
    echo ""
    echo "Necesito la contraseña del usuario 'metin2' de MySQL:"
    read -sp "Contraseña del usuario metin2: " METIN2_DB_PASSWORD
    echo ""
    
    # Obtener IP pública
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "72.61.12.2")
    
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
else
    echo -e "${GREEN}✅ Archivo .env encontrado${NC}"
    echo -e "${YELLOW}⚠️  Verifica que MYSQL_PASSWORD en .env sea correcta${NC}"
    echo ""
    read -p "¿Deseas editar el archivo .env ahora? (s/N): " EDIT_ENV
    if [[ "$EDIT_ENV" =~ ^[Ss]$ ]]; then
        ${EDITOR:-nano} .env
    fi
fi

# Verificar imagen Docker
echo ""
echo -e "${GREEN}🐳 Verificando imagen Docker...${NC}"
if ! docker images | grep -q "metin2/server"; then
    echo -e "${YELLOW}⚠️  Imagen Docker no encontrada. Construyendo...${NC}"
    docker build -t metin2/server:latest .
else
    echo -e "${GREEN}✅ Imagen Docker encontrada${NC}"
fi

# Detener contenedor existente si existe
echo ""
echo -e "${GREEN}🛑 Limpiando contenedores antiguos...${NC}"
docker stop metin2-server 2>/dev/null || true
docker rm metin2-server 2>/dev/null || true

# Iniciar servidor
echo ""
echo -e "${GREEN}🚀 Iniciando servidor...${NC}"
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
echo -e "${GREEN}✅ Proceso completado!${NC}"

