#!/bin/bash
# Script para corregir la IP pública en .env
# Uso: bash corregir-ip-publica.sh

set -e

echo "=========================================="
echo "Corrigiendo IP Pública en .env"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio del proyecto${NC}"
    exit 1
}

# IP pública correcta (IPv4)
CORRECT_IP="72.61.12.2"

# Verificar que .env existe
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

# Verificar IP actual
CURRENT_IP=$(grep "^PUBLIC_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

echo -e "${BLUE}IP actual en .env: ${CURRENT_IP}${NC}"
echo -e "${BLUE}IP correcta (IPv4): ${CORRECT_IP}${NC}"
echo ""

# Verificar si ya está correcta
if [ "$CURRENT_IP" = "$CORRECT_IP" ]; then
    echo -e "${GREEN}✅ La IP ya está correcta: ${CORRECT_IP}${NC}"
    exit 0
fi

# Verificar si es IPv6
if [[ "$CURRENT_IP" == *":"* ]]; then
    echo -e "${YELLOW}⚠️  Detectada dirección IPv6: ${CURRENT_IP}${NC}"
    echo -e "${YELLOW}⚠️  El cliente Metin2 necesita IPv4${NC}"
    echo ""
fi

# Confirmar cambio
echo -e "${YELLOW}¿Deseas cambiar PUBLIC_IP a ${CORRECT_IP}? (S/n):${NC}"
read -r CONFIRM
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

# Hacer backup
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✅ Backup creado: .env.backup.*${NC}"

# Reemplazar IP
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|^PUBLIC_IP=.*|PUBLIC_IP=${CORRECT_IP}|" .env
else
    # Linux
    sed -i "s|^PUBLIC_IP=.*|PUBLIC_IP=${CORRECT_IP}|" .env
fi

# Verificar cambio
NEW_IP=$(grep "^PUBLIC_IP=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs)

if [ "$NEW_IP" = "$CORRECT_IP" ]; then
    echo -e "${GREEN}✅ IP actualizada correctamente${NC}"
    echo ""
    echo -e "${BLUE}Nueva configuración:${NC}"
    grep "^PUBLIC_IP=" .env
    echo ""
    
    # Verificar si el contenedor está corriendo
    if docker ps | grep -q "metin2-server"; then
        echo -e "${YELLOW}⚠️  El contenedor está corriendo. Debes reiniciarlo para aplicar los cambios:${NC}"
        echo ""
        echo "   docker restart metin2-server"
        echo ""
        read -p "¿Deseas reiniciar el contenedor ahora? (S/n): " RESTART
        if [[ ! "$RESTART" =~ ^[Nn]$ ]]; then
            echo ""
            echo -e "${GREEN}🔄 Reiniciando contenedor...${NC}"
            docker restart metin2-server
            echo -e "${GREEN}✅ Contenedor reiniciado${NC}"
            echo ""
            echo "Espera 30 segundos y verifica:"
            echo "   docker logs --tail 20 metin2-server"
        fi
    else
        echo -e "${YELLOW}ℹ️  El contenedor no está corriendo. Cuando lo inicies, usará la nueva IP.${NC}"
    fi
else
    echo -e "${RED}❌ Error al actualizar la IP${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ ¡IP Corregida!${NC}"
echo "=========================================="

