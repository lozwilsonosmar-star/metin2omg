#!/bin/bash
# Script para iniciar el servidor Metin2
# Uso: ./start-server.sh

set -e

echo "🚀 Iniciando Metin2 Server..."

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado. Por favor instálalo primero."
    exit 1
fi

# Verificar si existe el archivo .env
if [ ! -f ".env" ]; then
    echo "⚠️  Archivo .env no encontrado."
    echo "Creando archivo .env de ejemplo..."
    cat > .env << 'EOF'
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=metin2
MYSQL_PASSWORD=changeme
MYSQL_DB_ACCOUNT=metin2_account
MYSQL_DB_COMMON=metin2_common
MYSQL_DB_PLAYER=metin2_player
MYSQL_DB_LOG=metin2_log

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
EOF
    echo "✅ Archivo .env creado. Por favor edítalo con tus configuraciones:"
    echo "   nano .env"
    exit 1
fi

# Verificar si existe la imagen Docker
if ! docker images | grep -q "metin2/server"; then
    echo "📦 Construyendo imagen Docker..."
    docker build -t metin2/server:latest --provenance=false .
fi

# Detener contenedor existente si existe
if docker ps -a | grep -q "metin2-server"; then
    echo "🛑 Deteniendo contenedor existente..."
    docker stop metin2-server 2>/dev/null || true
    docker rm metin2-server 2>/dev/null || true
fi

# Iniciar contenedor
echo "🚀 Iniciando contenedor..."
docker run -d \
  --name metin2-server \
  --restart unless-stopped \
  -p 12345:12345 \
  -p 13200:13200 \
  -p 8888:8888 \
  --env-file .env \
  metin2/server:latest

echo "✅ Servidor iniciado!"
echo ""
echo "Ver logs con: docker logs -f metin2-server"
echo "Detener con: docker stop metin2-server"


