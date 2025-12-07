#!/bin/bash
# Script para diagnosticar problemas de conexión desde Workbench
# Uso: bash diagnosticar-conexion-workbench.sh

echo "=========================================="
echo "Diagnóstico de Conexión Workbench"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Verificar que MySQL está corriendo
echo -e "${GREEN}1. Verificando que MySQL está corriendo...${NC}"
if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
    echo -e "${GREEN}   ✅ MySQL está corriendo${NC}"
else
    echo -e "${RED}   ❌ MySQL NO está corriendo${NC}"
    echo "   Inicia MySQL: sudo systemctl start mysql"
    exit 1
fi
echo ""

# 2. Verificar que MySQL escucha en el puerto 3306
echo -e "${GREEN}2. Verificando puerto 3306...${NC}"
if ss -tuln | grep -q ":3306"; then
    echo -e "${GREEN}   ✅ Puerto 3306 está escuchando${NC}"
    ss -tuln | grep ":3306"
else
    echo -e "${RED}   ❌ Puerto 3306 NO está escuchando${NC}"
fi
echo ""

# 3. Verificar configuración de bind-address
echo -e "${GREEN}3. Verificando configuración bind-address...${NC}"
BIND_ADDRESS=$(mysql -u root -pproyectalean -e "SHOW VARIABLES LIKE 'bind_address';" 2>/dev/null | grep bind_address | awk '{print $2}' || echo "no encontrado")

if [ "$BIND_ADDRESS" = "0.0.0.0" ] || [ "$BIND_ADDRESS" = "*" ]; then
    echo -e "${GREEN}   ✅ bind_address permite conexiones remotas: $BIND_ADDRESS${NC}"
elif [ "$BIND_ADDRESS" = "127.0.0.1" ] || [ "$BIND_ADDRESS" = "localhost" ]; then
    echo -e "${YELLOW}   ⚠️  bind_address está en localhost: $BIND_ADDRESS${NC}"
    echo "   Esto está bien para SSH Tunnel, pero no para conexión directa"
else
    echo -e "${YELLOW}   ⚠️  bind_address: $BIND_ADDRESS${NC}"
fi
echo ""

# 4. Verificar usuarios y hosts permitidos
echo -e "${GREEN}4. Verificando usuarios MySQL...${NC}"
mysql -u root -pproyectalean -e "SELECT user, host FROM mysql.user WHERE user IN ('root', 'metin2');" 2>/dev/null || echo "   Error al consultar usuarios"
echo ""

# 5. Obtener IP pública
echo -e "${GREEN}5. Información de conexión:${NC}"
PUBLIC_IP=$(curl -s -4 ifconfig.me 2>/dev/null || echo "72.61.12.2")
echo "   IP Pública (IPv4): $PUBLIC_IP"
echo "   Puerto MySQL: 3306"
echo ""

# 6. Verificar firewall
echo -e "${GREEN}6. Verificando firewall...${NC}"
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(ufw status | head -1)
    echo "   Estado UFW: $UFW_STATUS"
    if echo "$UFW_STATUS" | grep -qi "active"; then
        if ufw status | grep -q "3306"; then
            echo -e "${GREEN}   ✅ Puerto 3306 está permitido en firewall${NC}"
        else
            echo -e "${YELLOW}   ⚠️  Puerto 3306 NO está permitido en firewall${NC}"
            echo "   Para SSH Tunnel NO necesitas abrir el puerto"
            echo "   Para conexión directa, ejecuta: sudo ufw allow 3306/tcp"
        fi
    else
        echo -e "${GREEN}   ✅ Firewall no está activo${NC}"
    fi
else
    echo "   UFW no está instalado"
fi
echo ""

# 7. Resumen y recomendaciones
echo "=========================================="
echo "RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""
echo -e "${BLUE}Para MySQL Workbench:${NC}"
echo ""
echo "Opción 1: SSH Tunnel (Recomendado - más seguro)"
echo "   SSH Hostname: $PUBLIC_IP"
echo "   SSH Username: root"
echo "   SSH Password: [tu contraseña SSH]"
echo "   MySQL Hostname: localhost"
echo "   MySQL Port: 3306"
echo "   MySQL Username: root"
echo "   MySQL Password: proyectalean"
echo ""
echo "Opción 2: Conexión Directa"
echo "   Hostname: $PUBLIC_IP"
echo "   Port: 3306"
echo "   Username: root"
echo "   Password: proyectalean"
echo "   (Requiere que MySQL permita conexiones remotas)"
echo ""
echo -e "${YELLOW}Si SSH Tunnel no funciona:${NC}"
echo "   1. Verifica que puedas conectarte por SSH al VPS"
echo "   2. Verifica que la contraseña SSH sea correcta"
echo "   3. Verifica que el puerto 22 (SSH) esté abierto"
echo ""
echo -e "${YELLOW}Si conexión directa no funciona:${NC}"
echo "   1. Verifica que bind_address permita conexiones remotas"
echo "   2. Verifica que el firewall permita el puerto 3306"
echo "   3. Verifica que el usuario root tenga permisos desde '%'"
echo ""

