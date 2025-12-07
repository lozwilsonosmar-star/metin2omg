#!/bin/bash
# Script para verificar el progreso de la compilación/setup
# Uso: bash verificar-progreso-compilacion.sh

echo "=========================================="
echo "Verificación del Progreso de Compilación"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /opt/metin2omg 2>/dev/null || cd /opt/metin2-server 2>/dev/null || exit 1

# 1. Verificar si hay un proceso de build activo
echo -e "${BLUE}1. Proceso de Build de Docker:${NC}"
if docker ps -a | grep -q "metin2-server"; then
    echo -e "${GREEN}   ✅ Contenedor existe${NC}"
    docker ps -a | grep metin2-server | awk '{print "   Estado: " $7 " | Desde: " $5}'
else
    echo -e "${YELLOW}   ⚠️  Contenedor no existe aún${NC}"
fi

# Verificar si hay un build en progreso
if pgrep -f "docker build" > /dev/null; then
    echo -e "${YELLOW}   ⚠️  Hay un proceso de build en ejecución${NC}"
    echo "   Esto es normal durante la compilación"
else
    echo -e "${GREEN}   ✅ No hay build en progreso${NC}"
fi
echo ""

# 2. Verificar si la imagen existe
echo -e "${BLUE}2. Imagen Docker:${NC}"
if docker images | grep -q "metin2/server"; then
    echo -e "${GREEN}   ✅ Imagen existe${NC}"
    docker images | grep "metin2/server" | awk '{print "   Tag: " $2 " | Tamaño: " $7 " " $8 " | Creada: " $4 " " $5}'
else
    echo -e "${YELLOW}   ⚠️  Imagen no existe aún (se creará durante el build)${NC}"
fi
echo ""

# 3. Verificar espacio en disco
echo -e "${BLUE}3. Espacio en Disco:${NC}"
df -h / | tail -1 | awk '{print "   Usado: " $3 " / " $2 " (" $5 ")"}'
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo -e "${RED}   ⚠️  Disco casi lleno (${DISK_USAGE}%)${NC}"
    echo "   Considera limpiar Docker: bash docker/limpiar-docker.sh"
elif [ "$DISK_USAGE" -gt 80 ]; then
    echo -e "${YELLOW}   ⚠️  Disco con poco espacio (${DISK_USAGE}%)${NC}"
else
    echo -e "${GREEN}   ✅ Espacio suficiente (${DISK_USAGE}%)${NC}"
fi
echo ""

# 4. Verificar logs del contenedor (si existe)
if docker ps -a | grep -q "metin2-server"; then
    echo -e "${BLUE}4. Últimas líneas de logs del contenedor:${NC}"
    echo -e "${YELLOW}--- INICIO DE LOGS ---${NC}"
    docker logs --tail 20 metin2-server 2>&1 | tail -20
    echo -e "${YELLOW}--- FIN DE LOGS ---${NC}"
    echo ""
    
    # 5. Verificar si el servidor está iniciando
    echo -e "${BLUE}5. Estado del Servidor:${NC}"
    if docker logs metin2-server 2>&1 | grep -qi "TCP listening"; then
        echo -e "${GREEN}   ✅ Servidor inició correctamente${NC}"
        docker logs metin2-server 2>&1 | grep -i "TCP listening" | tail -1
    elif docker logs metin2-server 2>&1 | grep -qi "DB Server iniciado\|Game Server"; then
        echo -e "${YELLOW}   ⚠️  Servidor está iniciando...${NC}"
        docker logs metin2-server 2>&1 | grep -i "DB Server iniciado\|Game Server" | tail -2
    else
        echo -e "${YELLOW}   ⚠️  Servidor aún no ha iniciado${NC}"
    fi
    echo ""
fi

# 6. Verificar puertos
echo -e "${BLUE}6. Puertos Escuchando:${NC}"
PORTS_ACTIVE=0
if ss -tuln 2>/dev/null | grep -q ":12345"; then
    echo -e "${GREEN}   ✅ Puerto 12345 (GAME)${NC}"
    PORTS_ACTIVE=$((PORTS_ACTIVE + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 12345 (GAME) no está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":8888"; then
    echo -e "${GREEN}   ✅ Puerto 8888 (DB)${NC}"
    PORTS_ACTIVE=$((PORTS_ACTIVE + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 8888 (DB) no está escuchando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":13200"; then
    echo -e "${GREEN}   ✅ Puerto 13200 (P2P)${NC}"
    PORTS_ACTIVE=$((PORTS_ACTIVE + 1))
else
    echo -e "${YELLOW}   ⚠️  Puerto 13200 (P2P) no está escuchando${NC}"
fi
echo ""

# 7. Resumen
echo "=========================================="
echo "RESUMEN"
echo "=========================================="

if [ $PORTS_ACTIVE -eq 3 ]; then
    echo -e "${GREEN}✅ El servidor está completamente operativo!${NC}"
    echo ""
    echo "Puedes conectarte con el cliente ahora."
elif [ $PORTS_ACTIVE -gt 0 ]; then
    echo -e "${YELLOW}⚠️  El servidor está iniciando...${NC}"
    echo "   Puertos activos: $PORTS_ACTIVE/3"
    echo ""
    echo "Espera unos segundos más y ejecuta:"
    echo "   bash verificar-estado-servidor.sh"
elif docker ps -a | grep -q "metin2-server"; then
    echo -e "${YELLOW}⚠️  El servidor está iniciando o hay un problema${NC}"
    echo ""
    echo "Revisa los logs:"
    echo "   docker logs -f metin2-server"
else
    echo -e "${YELLOW}⚠️  El contenedor aún no existe${NC}"
    echo ""
    echo "El proceso de setup/compilación puede estar en progreso."
    echo "Si ejecutaste setup-completo-vps.sh, espera a que termine."
fi

echo ""
echo -e "${BLUE}📋 Comandos útiles:${NC}"
echo "   Ver logs en tiempo real:    docker logs -f metin2-server"
echo "   Verificar estado completo:  bash verificar-estado-servidor.sh"
echo "   Verificar flujo de login:   bash diagnosticar-flujo-login-completo.sh"
echo ""

