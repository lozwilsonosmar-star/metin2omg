#!/bin/bash
# Script para configurar MySQL para conexiones remotas (Workbench)
# Uso: bash configurar-mysql-remoto.sh

set -e

echo "=========================================="
echo "Configuración de MySQL para Workbench"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /opt/metin2omg

# Obtener credenciales
MYSQL_HOST=$(grep "^MYSQL_HOST=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "localhost")
MYSQL_PORT=$(grep "^MYSQL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "3306")
MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2")
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

echo -e "${GREEN}Información de conexión MySQL:${NC}"
echo ""
echo "   Host: $MYSQL_HOST"
echo "   Puerto: $MYSQL_PORT"
echo "   Usuario: $MYSQL_USER"
echo "   Contraseña: [la que está en .env]"
echo ""

# Obtener IP pública del VPS
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "72.61.12.2")
echo -e "${GREEN}IP Pública del VPS:${NC} $PUBLIC_IP"
echo ""

# Verificar si el usuario tiene permisos remotos
echo -e "${GREEN}Verificando permisos del usuario...${NC}"

export MYSQL_PWD="$MYSQL_PASSWORD"

# Verificar si el usuario puede conectarse desde cualquier host
REMOTE_USER=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -sN -e "SELECT COUNT(*) FROM mysql.user WHERE User='$MYSQL_USER' AND Host='%';" 2>/dev/null || echo "0")

if [ "$REMOTE_USER" = "0" ]; then
    echo -e "${YELLOW}⚠️  El usuario '$MYSQL_USER' no tiene permisos para conexiones remotas${NC}"
    echo ""
    echo -e "${YELLOW}¿Deseas crear un usuario remoto? (s/N):${NC} "
    read -r CREAR_REMOTO
    
    if [[ "$CREAR_REMOTO" =~ ^[Ss]$ ]]; then
        echo ""
        echo -e "${GREEN}Creando usuario remoto...${NC}"
        
        # Pedir contraseña root si es necesario
        echo -e "${YELLOW}Necesitas la contraseña de root de MySQL para crear el usuario remoto${NC}"
        read -sp "Contraseña de root MySQL: " ROOT_PASSWORD
        echo ""
        
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -uroot -p"$ROOT_PASSWORD" <<EOF 2>&1 || true
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON metin2_account.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON metin2_common.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON metin2_player.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON metin2_log.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
        
        echo -e "${GREEN}✅ Usuario remoto creado${NC}"
    else
        echo -e "${YELLOW}⚠️  No se creó usuario remoto. Usa conexión SSH tunnel en Workbench${NC}"
    fi
else
    echo -e "${GREEN}✅ El usuario ya tiene permisos remotos${NC}"
fi

unset MYSQL_PWD

echo ""
echo "=========================================="
echo "Configuración de Workbench"
echo "=========================================="
echo ""
echo -e "${BLUE}Opción 1: Conexión Directa (si MySQL permite conexiones remotas)${NC}"
echo ""
echo "   Connection Name: Metin2 Server"
echo "   Hostname: $PUBLIC_IP"
echo "   Port: $MYSQL_PORT"
echo "   Username: $MYSQL_USER"
echo "   Password: [la contraseña de .env]"
echo ""
echo -e "${BLUE}Opción 2: SSH Tunnel (más seguro, recomendado)${NC}"
echo ""
echo "   Connection Name: Metin2 Server (SSH)"
echo "   Connection Method: Standard (TCP/IP)"
echo "   SSH Hostname: $PUBLIC_IP"
echo "   SSH Username: root"
echo "   SSH Password: [tu contraseña SSH]"
echo "   MySQL Hostname: localhost"
echo "   MySQL Port: $MYSQL_PORT"
echo "   MySQL Username: $MYSQL_USER"
echo "   MySQL Password: [la contraseña de .env]"
echo ""
echo -e "${GREEN}Bases de datos disponibles:${NC}"
echo "   - metin2_account"
echo "   - metin2_common"
echo "   - metin2_player"
echo "   - metin2_log"
echo ""
echo -e "${YELLOW}⚠️  Nota: Si la conexión directa no funciona, usa SSH Tunnel${NC}"
echo ""

