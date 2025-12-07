#!/bin/bash
# Script para mostrar las credenciales de MySQL de forma segura
# Uso: bash mostrar-credenciales-mysql.sh

echo "=========================================="
echo "Credenciales de MySQL"
echo "=========================================="
echo ""

cd /opt/metin2omg

if [ ! -f ".env" ]; then
    echo "❌ No se encontró el archivo .env"
    exit 1
fi

# Obtener credenciales
MYSQL_HOST=$(grep "^MYSQL_HOST=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "localhost")
MYSQL_PORT=$(grep "^MYSQL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "3306")
MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "metin2")
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

if [ "$MYSQL_HOST" = "localhost" ]; then
    MYSQL_HOST="127.0.0.1"
fi

# Obtener IP pública
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "72.61.12.2")

echo "📋 Información de Conexión MySQL:"
echo ""
echo "   Host (desde VPS): $MYSQL_HOST"
echo "   Host (desde fuera): $PUBLIC_IP"
echo "   Puerto: $MYSQL_PORT"
echo "   Usuario: $MYSQL_USER"
echo "   Contraseña: $MYSQL_PASSWORD"
echo ""
echo "=========================================="
echo "Configuración para MySQL Workbench"
echo "=========================================="
echo ""
echo "Opción 1: SSH Tunnel (Recomendado)"
echo "   SSH Hostname: $PUBLIC_IP"
echo "   SSH Username: root"
echo "   SSH Password: [tu contraseña SSH del VPS]"
echo "   MySQL Hostname: localhost"
echo "   MySQL Port: $MYSQL_PORT"
echo "   MySQL Username: $MYSQL_USER"
echo "   MySQL Password: $MYSQL_PASSWORD"
echo ""
echo "Opción 2: Conexión Directa"
echo "   Hostname: $PUBLIC_IP"
echo "   Port: $MYSQL_PORT"
echo "   Username: $MYSQL_USER"
echo "   Password: $MYSQL_PASSWORD"
echo ""
echo "Bases de datos:"
echo "   - metin2_account"
echo "   - metin2_common"
echo "   - metin2_player"
echo "   - metin2_log"
echo ""

