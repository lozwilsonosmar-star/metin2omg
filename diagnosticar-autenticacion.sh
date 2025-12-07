#!/bin/bash
# Script para diagnosticar problemas de autenticación
# Uso: bash diagnosticar-autenticacion.sh

echo "=========================================="
echo "Diagnóstico de Autenticación"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TEST_USER="test"
TEST_PASSWORD="metin2test123"

echo "1. Verificando cuenta en la base de datos..."
echo ""

mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, password, status, social_id FROM account WHERE login='$TEST_USER';" 2>/dev/null

echo ""
echo "2. Generando hash SHA1 de la contraseña '$TEST_PASSWORD'..."
PASSWORD_HASH=$(echo -n "$TEST_PASSWORD" | sha1sum | awk '{print toupper($1)}')
echo "   Hash generado: $PASSWORD_HASH"
echo ""

echo "3. Verificando logs del servidor para errores de autenticación..."
echo ""

if docker ps | grep -q "metin2-server"; then
    echo "   Últimos errores relacionados con login/autenticación:"
    docker logs --tail 200 metin2-server 2>&1 | grep -iE "login|auth|wrong|cred|password|test" | tail -20
    
    echo ""
    echo "   Errores críticos recientes:"
    docker logs --tail 100 metin2-server 2>&1 | grep -E "ERROR|CRITICAL|FAILED" | tail -10
else
    echo -e "   ${RED}❌ Contenedor no está corriendo${NC}"
fi

echo ""
echo "4. Verificando que el servidor esté escuchando..."
if ss -tuln | grep -q ":12345"; then
    echo -e "   ${GREEN}✅ Puerto 12345 está escuchando${NC}"
else
    echo -e "   ${RED}❌ Puerto 12345 NO está escuchando${NC}"
fi

echo ""
echo "5. Verificando configuración AUTH_SERVER..."
if [ -f ".env" ]; then
    AUTH_SERVER=$(grep "^GAME_AUTH_SERVER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    echo "   AUTH_SERVER: $AUTH_SERVER"
    
    if [ "$AUTH_SERVER" = "master" ]; then
        echo -e "   ${GREEN}✅ Configuración correcta (modo standalone)${NC}"
    else
        echo -e "   ${YELLOW}⚠️  AUTH_SERVER no está en 'master'${NC}"
    fi
fi

echo ""
echo "=========================================="
echo "RECOMENDACIONES"
echo "=========================================="
echo ""
echo "Si el error 'wrongcrd' persiste, puede ser porque:"
echo ""
echo "1. El servidor usa un método diferente de hash"
echo "   Solución: Verifica en el código fuente cómo se hashea la contraseña"
echo ""
echo "2. El servidor no está completamente iniciado"
echo "   Solución: Espera 60 segundos y reinicia: docker restart metin2-server"
echo ""
echo "3. Hay un problema con la conexión entre cliente y servidor"
echo "   Solución: Verifica que el puerto 12345 esté abierto y accesible"
echo ""
echo "4. El formato del hash es diferente"
echo "   Solución: Prueba con hash en minúsculas o sin UPPER()"
echo ""
echo "5. La cuenta necesita campos adicionales"
echo "   Solución: Verifica la estructura completa de la tabla account"
echo ""

