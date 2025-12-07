#!/bin/bash

echo "=========================================="
echo "Verificación del Cambio de Fase"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "1. Buscando 'AuthLogin: Changed phase to PHASE_SELECT'..."
if docker logs metin2-server 2>&1 | grep -q "AuthLogin: Changed phase to PHASE_SELECT"; then
    echo -e "${GREEN}✅ Se encontró el cambio de fase${NC}"
    docker logs metin2-server 2>&1 | grep "AuthLogin: Changed phase to PHASE_SELECT" | tail -3
else
    echo -e "${RED}❌ NO se encontró el cambio de fase${NC}"
    echo "   Esto significa que el código no se compiló correctamente o hay un problema"
fi
echo ""

echo "2. Buscando 'AuthLogin result'..."
if docker logs metin2-server 2>&1 | grep -q "AuthLogin result"; then
    echo -e "${GREEN}✅ Se encontró AuthLogin result${NC}"
    docker logs metin2-server 2>&1 | grep "AuthLogin result" | tail -3
else
    echo -e "${RED}❌ NO se encontró AuthLogin result${NC}"
fi
echo ""

echo "3. Buscando 'HEADER_GC_PHASE' o 'SetPhase'..."
if docker logs metin2-server 2>&1 | grep -qi "HEADER_GC_PHASE\|SetPhase.*SELECT"; then
    echo -e "${GREEN}✅ Se encontraron referencias a cambio de fase${NC}"
    docker logs metin2-server 2>&1 | grep -i "HEADER_GC_PHASE\|SetPhase.*SELECT" | tail -5
else
    echo -e "${YELLOW}⚠️  No se encontraron referencias explícitas a cambio de fase${NC}"
    echo "   (Esto puede ser normal si el log no está habilitado para SetPhase)"
fi
echo ""

echo "4. Verificando si el código se compiló con los cambios..."
echo "   Buscando la versión del servidor..."
VERSION=$(docker logs metin2-server 2>&1 | grep "Game Server version" | tail -1)
if [ -n "$VERSION" ]; then
    echo -e "${GREEN}✅ Versión del servidor:${NC}"
    echo "   $VERSION"
    
    # Verificar si la fecha es reciente (últimas 24 horas)
    if echo "$VERSION" | grep -q "2025-12-07"; then
        echo -e "${GREEN}✅ El servidor fue compilado hoy (debería incluir los cambios)${NC}"
    else
        echo -e "${YELLOW}⚠️  El servidor fue compilado en otra fecha${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No se pudo determinar la versión${NC}"
fi
echo ""

echo "5. Verificando logs completos de AuthLogin (últimas 5 ocurrencias)..."
docker logs metin2-server 2>&1 | grep -A 2 -B 2 "AuthLogin result" | tail -20
echo ""

echo "=========================================="
echo "ANÁLISIS"
echo "=========================================="
echo ""
echo "Si NO aparece 'AuthLogin: Changed phase to PHASE_SELECT':"
echo "  → El código no se compiló con los cambios"
echo "  → Necesitas recompilar el servidor"
echo ""
echo "Si aparece 'AuthLogin result 1' pero NO aparece 'LOGIN_BY_KEY':"
echo "  → El cliente NO está enviando la solicitud de personajes"
echo "  → Posibles causas:"
echo "     1. El cliente no recibió el cambio de fase"
echo "     2. El cliente está esperando algo más"
echo "     3. Hay un problema con la configuración del cliente"
echo ""

