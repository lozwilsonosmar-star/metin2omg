#!/bin/bash
# Script para verificar qué formato de contraseña usa el servidor

echo "=========================================="
echo "Verificación: Formato de Contraseña del Servidor"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}El servidor está COMPILADO para usar:${NC}"
echo ""
echo "  Formato: Argon2id (hardcodeado en el código)"
echo "  Ubicación: src/game/src/db.cpp línea 365"
echo "  Función: argon2id_verify()"
echo ""
echo -e "${YELLOW}Esto significa:${NC}"
echo "  ❌ NO puede usar hashes MySQL (*CC67043C...)"
echo "  ❌ NO puede usar bcrypt (\$2a\$...)"
echo "  ✅ SOLO puede usar Argon2id (\$argon2id\$...)"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}OPCIONES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo "1. ${GREEN}OPCIÓN RECOMENDADA:${NC} Convertir contraseñas a Argon2id"
echo "   - Es lo que el servidor espera"
echo "   - No requiere modificar código"
echo "   - Funciona inmediatamente"
echo ""
echo "2. ${YELLOW}OPCIÓN ALTERNATIVA:${NC} Modificar código del servidor"
echo "   - Cambiar db.cpp para aceptar hashes MySQL"
echo "   - Requiere recompilar el servidor"
echo "   - Más complejo y propenso a errores"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}¿QUÉ HACER?${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo "Para usar los hashes MySQL existentes, necesitarías:"
echo "  1. Modificar src/game/src/db.cpp"
echo "  2. Agregar función para verificar hashes MySQL"
echo "  3. Recompilar el servidor"
echo "  4. Reconstruir la imagen Docker"
echo ""
echo -e "${YELLOW}Esto es MÁS COMPLEJO que simplemente convertir las contraseñas${NC}"
echo ""
echo "Recomendación: Usar Argon2id (opción 1)"
echo ""

