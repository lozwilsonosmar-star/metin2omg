#!/bin/bash
# Script de SOLO LECTURA - NO modifica NADA
# Verifica el estado actual sin hacer cambios
# Uso: bash verificar-sin-cambios.sh

echo "=========================================="
echo "VERIFICACIÓN (Solo Lectura - Sin Cambios)"
echo "=========================================="
echo "Este script NO modifica NADA, solo verifica"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ir al directorio
cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || {
    echo -e "${RED}❌ No se encontró el directorio${NC}"
    exit 1
}

echo -e "${BLUE}📂 Directorio: $(pwd)${NC}"
echo ""

# Verificar contenedor
echo -e "${GREEN}1. Estado del contenedor:${NC}"
if docker ps -a | grep -q "metin2-server"; then
    if docker ps | grep -q "metin2-server"; then
        echo -e "${GREEN}   ✅ Contenedor está CORRIENDO${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Contenedor existe pero está DETENIDO${NC}"
    fi
    docker ps -a | grep metin2-server
else
    echo -e "${RED}   ❌ Contenedor NO existe${NC}"
fi
echo ""

# Verificar imagen
echo -e "${GREEN}2. Imagen Docker:${NC}"
if docker images | grep -q "metin2/server"; then
    echo -e "${GREEN}   ✅ Imagen existe${NC}"
    docker images | grep "metin2/server" | head -1
else
    echo -e "${RED}   ❌ Imagen NO existe${NC}"
fi
echo ""

# Verificar .env
echo -e "${GREEN}3. Archivo .env:${NC}"
if [ -f ".env" ]; then
    echo -e "${GREEN}   ✅ Archivo .env existe${NC}"
else
    echo -e "${RED}   ❌ Archivo .env NO existe${NC}"
fi
echo ""

# Verificar puertos
echo -e "${GREEN}4. Puertos escuchando:${NC}"
if ss -tuln 2>/dev/null | grep -q ":12345"; then
    echo -e "${GREEN}   ✅ Puerto 12345 está escuchando${NC}"
else
    echo -e "${RED}   ❌ Puerto 12345 NO está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":8888"; then
    echo -e "${GREEN}   ✅ Puerto 8888 está escuchando${NC}"
else
    echo -e "${RED}   ❌ Puerto 8888 NO está escuchando${NC}"
fi
echo ""

# Verificar firewall (SOLO LECTURA)
echo -e "${GREEN}5. Estado del firewall (SOLO LECTURA):${NC}"
if command -v ufw &> /dev/null; then
    echo -e "${BLUE}   Reglas actuales del firewall:${NC}"
    ufw status numbered 2>/dev/null | head -15
    echo ""
    echo -e "${GREEN}   ✅ Este script NO modificará el firewall${NC}"
else
    echo -e "${YELLOW}   ⚠️  UFW no está instalado${NC}"
fi
echo ""

# Resumen
echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo -e "${GREEN}✅ Este script es de SOLO LECTURA${NC}"
echo -e "${GREEN}✅ NO modifica el firewall${NC}"
echo -e "${GREEN}✅ NO modifica configuraciones${NC}"
echo -e "${GREEN}✅ Solo VERIFICA el estado actual${NC}"
echo ""
echo -e "${BLUE}📋 Próximos pasos (si decides continuar):${NC}"
echo "   El script setup-completo-vps.sh también es seguro"
echo "   y NO modifica el firewall"
echo ""

