#!/bin/bash
# Script para verificar que el proceso de Docker build está activo
# Uso: bash verificar-proceso-activo.sh

echo "=========================================="
echo "Verificación de Proceso Docker Build"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Verificar procesos de Docker
echo -e "${GREEN}1. Procesos de Docker corriendo:${NC}"
if pgrep -f "docker build" > /dev/null; then
    echo -e "${GREEN}   ✅ Proceso 'docker build' está ACTIVO${NC}"
    ps aux | grep "docker build" | grep -v grep | head -1
else
    echo -e "${YELLOW}   ⚠️  No se encontró proceso 'docker build'${NC}"
    echo -e "${YELLOW}   (Puede estar en otra etapa o haber terminado)${NC}"
fi
echo ""

# 2. Verificar contenedores de build
echo -e "${GREEN}2. Contenedores de build activos:${NC}"
BUILD_CONTAINERS=$(docker ps --filter "ancestor=docker:build" --format "{{.ID}}" 2>/dev/null | wc -l)
if [ "$BUILD_CONTAINERS" -gt 0 ]; then
    echo -e "${GREEN}   ✅ Hay $BUILD_CONTAINERS contenedor(es) de build activo(s)${NC}"
    docker ps --filter "ancestor=docker:build" --format "table {{.ID}}\t{{.Status}}\t{{.Names}}"
else
    echo -e "${YELLOW}   ⚠️  No hay contenedores de build visibles${NC}"
    echo -e "${YELLOW}   (Esto es normal, Docker puede usar procesos internos)${NC}"
fi
echo ""

# 3. Verificar uso de CPU (si hay proceso activo)
echo -e "${GREEN}3. Uso de CPU del sistema:${NC}"
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo -e "${BLUE}   CPU en uso: ${CPU_USAGE}%${NC}"
if (( $(echo "$CPU_USAGE > 10" | bc -l) )); then
    echo -e "${GREEN}   ✅ CPU está siendo usada (proceso activo)${NC}"
else
    echo -e "${YELLOW}   ⚠️  CPU en bajo uso (puede estar esperando I/O)${NC}"
fi
echo ""

# 4. Verificar uso de memoria
echo -e "${GREEN}4. Uso de memoria:${NC}"
MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
echo -e "${BLUE}   Memoria en uso: ${MEM_USAGE}%${NC}"
echo ""

# 5. Verificar actividad de disco (I/O)
echo -e "${GREEN}5. Actividad de disco (últimos 5 segundos):${NC}"
echo -e "${YELLOW}   Ejecutando iostat (si está disponible)...${NC}"
if command -v iostat &> /dev/null; then
    iostat -x 1 2 2>/dev/null | tail -5 || echo "   (iostat no disponible o requiere permisos)"
else
    echo "   (iostat no está instalado - esto es normal)"
fi
echo ""

# 6. Verificar logs de Docker (si hay)
echo -e "${GREEN}6. Últimas líneas de actividad Docker:${NC}"
if [ -f "/var/log/docker.log" ]; then
    tail -5 /var/log/docker.log 2>/dev/null || echo "   (No hay logs de Docker visibles)"
else
    echo "   (Logs de Docker no accesibles directamente)"
fi
echo ""

# 7. Verificar tiempo transcurrido
echo -e "${GREEN}7. Procesos relacionados con Docker:${NC}"
ps aux | grep -E "docker|vcpkg|cmake|make|gcc|g\+\+" | grep -v grep | wc -l | xargs -I {} echo -e "${BLUE}   Procesos activos: {}${NC}"
if [ "$(ps aux | grep -E "docker|vcpkg|cmake|make|gcc|g\+\+" | grep -v grep | wc -l)" -gt 0 ]; then
    echo -e "${GREEN}   ✅ Hay procesos de compilación activos${NC}"
    echo ""
    echo -e "${BLUE}   Procesos principales:${NC}"
    ps aux | grep -E "docker|vcpkg|cmake|make" | grep -v grep | head -3 | awk '{print "   " $11 " " $12 " " $13}'
else
    echo -e "${YELLOW}   ⚠️  No se encontraron procesos de compilación${NC}"
fi
echo ""

# Resumen
echo "=========================================="
echo "RESUMEN"
echo "=========================================="

ACTIVE=false
if pgrep -f "docker build" > /dev/null; then
    ACTIVE=true
elif [ "$(ps aux | grep -E "docker|vcpkg|cmake|make|gcc|g\+\+" | grep -v grep | wc -l)" -gt 0 ]; then
    ACTIVE=true
fi

if [ "$ACTIVE" = true ]; then
    echo -e "${GREEN}✅ El proceso está ACTIVO${NC}"
    echo ""
    echo -e "${BLUE}💡 El build está en progreso${NC}"
    echo -e "${BLUE}   Es normal que tarde 10-20 minutos${NC}"
    echo ""
    echo -e "${YELLOW}⏳ Sigue esperando...${NC}"
    echo ""
    echo "Para ver el progreso en tiempo real (en otra terminal):"
    echo "   docker ps -a"
    echo "   docker logs <container-id>"
else
    echo -e "${YELLOW}⚠️  No se detectó actividad obvia${NC}"
    echo ""
    echo "Esto puede significar:"
    echo "   1. El proceso terminó (éxito o error)"
    echo "   2. Está en una fase de espera/I/O"
    echo "   3. El proceso está en background"
    echo ""
    echo "Verifica manualmente:"
    echo "   docker images | grep metin2/server"
    echo "   docker ps -a"
fi

echo ""

