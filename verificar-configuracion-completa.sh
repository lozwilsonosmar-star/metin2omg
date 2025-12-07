#!/bin/bash
# Script completo para verificar configuración servidor-cliente Metin2
# Compara IPs, puertos, AUTH_SERVER, y detecta problemas de conexión

echo "=========================================="
echo "Verificación Completa Servidor-Cliente"
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

ERRORS=0
WARNINGS=0

# ============================================================
# 1. VERIFICAR ARCHIVO .env
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}1. CONFIGURACIÓN DEL SERVIDOR (.env)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ Archivo .env encontrado${NC}"
    echo ""
    
    # Cargar variables
    source .env 2>/dev/null || true
    
    ENV_PUBLIC_IP=$(grep "^PUBLIC_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    ENV_GAME_PORT=$(grep "^GAME_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    ENV_DB_PORT=$(grep "^DB_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    ENV_P2P_PORT=$(grep "^GAME_P2P_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    ENV_AUTH_SERVER=$(grep "^GAME_AUTH_SERVER=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    ENV_INTERNAL_IP=$(grep "^INTERNAL_IP=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    
    echo "   PUBLIC_IP: $ENV_PUBLIC_IP"
    echo "   GAME_PORT: $ENV_GAME_PORT"
    echo "   DB_PORT: $ENV_DB_PORT"
    echo "   P2P_PORT: $ENV_P2P_PORT"
    echo "   AUTH_SERVER: $ENV_AUTH_SERVER"
    echo "   INTERNAL_IP: $ENV_INTERNAL_IP"
    echo ""
    
    # Validar IP pública (debe ser IPv4)
    if [[ "$ENV_PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "   ${GREEN}✅ PUBLIC_IP es IPv4 válida${NC}"
    else
        echo -e "   ${RED}❌ PUBLIC_IP no es IPv4 válida: $ENV_PUBLIC_IP${NC}"
        echo -e "   ${YELLOW}   ⚠️  El cliente Metin2 requiere IPv4${NC}"
        ((ERRORS++))
    fi
    
    # Validar AUTH_SERVER
    if [ "$ENV_AUTH_SERVER" = "master" ]; then
        echo -e "   ${GREEN}✅ AUTH_SERVER está en modo 'master' (standalone)${NC}"
    else
        echo -e "   ${YELLOW}⚠️  AUTH_SERVER: $ENV_AUTH_SERVER (debería ser 'master' para standalone)${NC}"
        ((WARNINGS++))
    fi
fi

echo ""

# ============================================================
# 2. VERIFICAR game.conf DENTRO DEL CONTENEDOR
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}2. CONFIGURACIÓN DEL SERVIDOR (game.conf)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if docker ps | grep -q "metin2-server"; then
    echo -e "${GREEN}✅ Contenedor está corriendo${NC}"
    echo ""
    
    # Intentar leer game.conf desde diferentes ubicaciones
    GAME_CONF_PATHS=(
        "/app/gamefiles/conf/game.conf"
        "/opt/metin2/gamefiles/conf/game.conf"
        "/app/conf/game.conf"
        "/opt/metin2/conf/game.conf"
    )
    
    GAME_CONF_CONTENT=""
    for path in "${GAME_CONF_PATHS[@]}"; do
        if docker exec metin2-server test -f "$path" 2>/dev/null; then
            GAME_CONF_CONTENT=$(docker exec metin2-server cat "$path" 2>/dev/null)
            echo -e "   ${GREEN}✅ game.conf encontrado en: $path${NC}"
            break
        fi
    done
    
    if [ -z "$GAME_CONF_CONTENT" ]; then
        echo -e "   ${YELLOW}⚠️  No se pudo leer game.conf del contenedor${NC}"
        ((WARNINGS++))
    else
        echo ""
        
        # Extraer valores de game.conf
        CONF_PUBLIC_IP=$(echo "$GAME_CONF_CONTENT" | grep "^PUBLIC_IP:" | awk '{print $2}' | xargs || echo "")
        CONF_PORT=$(echo "$GAME_CONF_CONTENT" | grep "^PORT:" | awk '{print $2}' | xargs || echo "")
        CONF_P2P_PORT=$(echo "$GAME_CONF_CONTENT" | grep "^P2P_PORT:" | awk '{print $2}' | xargs || echo "")
        CONF_DB_PORT=$(echo "$GAME_CONF_CONTENT" | grep "^DB_PORT:" | awk '{print $2}' | xargs || echo "")
        CONF_AUTH_SERVER=$(echo "$GAME_CONF_CONTENT" | grep "^AUTH_SERVER:" | awk '{print $2}' | xargs || echo "")
        CONF_INTERNAL_IP=$(echo "$GAME_CONF_CONTENT" | grep "^INTERNAL_IP:" | awk '{print $2}' | xargs || echo "")
        
        echo "   PUBLIC_IP: $CONF_PUBLIC_IP"
        echo "   PORT: $CONF_PORT"
        echo "   P2P_PORT: $CONF_P2P_PORT"
        echo "   DB_PORT: $CONF_DB_PORT"
        echo "   AUTH_SERVER: $CONF_AUTH_SERVER"
        echo "   INTERNAL_IP: $CONF_INTERNAL_IP"
        echo ""
        
        # Comparar con .env
        if [ "$CONF_PUBLIC_IP" != "$ENV_PUBLIC_IP" ]; then
            echo -e "   ${RED}❌ PUBLIC_IP no coincide: .env=$ENV_PUBLIC_IP, game.conf=$CONF_PUBLIC_IP${NC}"
            ((ERRORS++))
        else
            echo -e "   ${GREEN}✅ PUBLIC_IP coincide${NC}"
        fi
        
        if [ "$CONF_PORT" != "$ENV_GAME_PORT" ]; then
            echo -e "   ${RED}❌ GAME_PORT no coincide: .env=$ENV_GAME_PORT, game.conf=$CONF_PORT${NC}"
            ((ERRORS++))
        else
            echo -e "   ${GREEN}✅ GAME_PORT coincide${NC}"
        fi
        
        if [ "$CONF_AUTH_SERVER" != "master" ]; then
            echo -e "   ${RED}❌ AUTH_SERVER incorrecto en game.conf: $CONF_AUTH_SERVER (debería ser 'master')${NC}"
            ((ERRORS++))
        else
            echo -e "   ${GREEN}✅ AUTH_SERVER correcto en game.conf${NC}"
        fi
    fi
else
    echo -e "${RED}❌ Contenedor no está corriendo${NC}"
    ((ERRORS++))
fi

echo ""

# ============================================================
# 3. VERIFICAR PUERTOS ESCUCHANDO
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3. PUERTOS ESCUCHANDO${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ -n "$ENV_GAME_PORT" ]; then
    if ss -tuln 2>/dev/null | grep -q ":$ENV_GAME_PORT "; then
        echo -e "   ${GREEN}✅ Puerto $ENV_GAME_PORT (GAME) está escuchando${NC}"
    else
        echo -e "   ${RED}❌ Puerto $ENV_GAME_PORT (GAME) NO está escuchando${NC}"
        ((ERRORS++))
    fi
fi

if [ -n "$ENV_DB_PORT" ]; then
    if ss -tuln 2>/dev/null | grep -q ":$ENV_DB_PORT "; then
        echo -e "   ${GREEN}✅ Puerto $ENV_DB_PORT (DB) está escuchando${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Puerto $ENV_DB_PORT (DB) NO está escuchando${NC}"
        ((WARNINGS++))
    fi
fi

if [ -n "$ENV_P2P_PORT" ]; then
    if ss -tuln 2>/dev/null | grep -q ":$ENV_P2P_PORT "; then
        echo -e "   ${GREEN}✅ Puerto $ENV_P2P_PORT (P2P) está escuchando${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Puerto $ENV_P2P_PORT (P2P) NO está escuchando${NC}"
        ((WARNINGS++))
    fi
fi

echo ""

# ============================================================
# 4. VERIFICAR LOGS DEL SERVIDOR
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}4. LOGS DEL SERVIDOR (Últimas 20 líneas)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if docker ps | grep -q "metin2-server"; then
    echo -e "${YELLOW}Buscando errores críticos...${NC}"
    echo ""
    
    # Buscar errores críticos
    CRITICAL_ERRORS=$(docker logs metin2-server --tail 100 2>&1 | grep -iE "error|fail|critical|syntax error" | tail -5)
    
    if [ -n "$CRITICAL_ERRORS" ]; then
        echo -e "${RED}❌ Errores encontrados:${NC}"
        echo "$CRITICAL_ERRORS" | while IFS= read -r line; do
            echo -e "   ${RED}$line${NC}"
        done
        ((ERRORS++))
    else
        echo -e "${GREEN}✅ No se encontraron errores críticos en los logs${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Buscando indicadores de éxito...${NC}"
    
    # Buscar indicadores de éxito
    if docker logs metin2-server --tail 50 2>&1 | grep -q "TCP listening"; then
        echo -e "   ${GREEN}✅ 'TCP listening' encontrado${NC}"
    else
        echo -e "   ${YELLOW}⚠️  'TCP listening' no encontrado (puede estar iniciando)${NC}"
        ((WARNINGS++))
    fi
    
    if docker logs metin2-server --tail 50 2>&1 | grep -q "MasterAuth\|AUTH_SERVER.*master"; then
        echo -e "   ${GREEN}✅ AUTH_SERVER configurado correctamente${NC}"
    else
        echo -e "   ${YELLOW}⚠️  No se encontró confirmación de AUTH_SERVER=master${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌ No se pueden verificar logs (contenedor no está corriendo)${NC}"
fi

echo ""

# ============================================================
# 5. VERIFICAR CONFIGURACIÓN DEL CLIENTE
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}5. CONFIGURACIÓN DEL CLIENTE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Buscar serverinfo.py
SERVERINFO_PATHS=(
    "Client-*/Client/Client/Client/Eternexus/root/serverinfo.py"
    "Client/*/Eternexus/root/serverinfo.py"
    "Client/Eternexus/root/serverinfo.py"
    "*/serverinfo.py"
)

SERVERINFO_FILE=""
for pattern in "${SERVERINFO_PATHS[@]}"; do
    found=$(find . -path "$pattern" -type f 2>/dev/null | head -1)
    if [ -n "$found" ]; then
        SERVERINFO_FILE="$found"
        break
    fi
done

if [ -z "$SERVERINFO_FILE" ] || [ ! -f "$SERVERINFO_FILE" ]; then
    echo -e "${YELLOW}⚠️  No se encontró serverinfo.py en el proyecto${NC}"
    echo -e "${YELLOW}   (Esto es normal si el cliente está en otra ubicación)${NC}"
    echo ""
    echo -e "${YELLOW}Verificación manual requerida:${NC}"
    echo "   1. Abre serverinfo.py en tu cliente"
    echo "   2. Verifica que SERVER_IP = \"$ENV_PUBLIC_IP\""
    echo "   3. Verifica que PORT_1 = $ENV_GAME_PORT"
    echo "   4. Verifica que PORT_AUTH = $ENV_GAME_PORT (no 11000)"
    ((WARNINGS++))
else
    echo -e "${GREEN}✅ serverinfo.py encontrado: $SERVERINFO_FILE${NC}"
    echo ""
    
    # Extraer valores
    CLIENT_SERVER_IP=$(grep "SERVER_IP[[:space:]]*=" "$SERVERINFO_FILE" | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "")
    CLIENT_PORT_1=$(grep "PORT_1[[:space:]]*=" "$SERVERINFO_FILE" | head -1 | sed 's/.*= *\([0-9]*\).*/\1/' || echo "")
    CLIENT_PORT_AUTH=$(grep "PORT_AUTH[[:space:]]*=" "$SERVERINFO_FILE" | head -1 | sed 's/.*= *\([0-9]*\).*/\1/' || echo "")
    
    echo "   SERVER_IP: $CLIENT_SERVER_IP"
    echo "   PORT_1: $CLIENT_PORT_1"
    echo "   PORT_AUTH: $CLIENT_PORT_AUTH"
    echo ""
    
    # Comparar con servidor
    if [ "$CLIENT_SERVER_IP" != "$ENV_PUBLIC_IP" ]; then
        echo -e "   ${RED}❌ SERVER_IP no coincide: cliente=$CLIENT_SERVER_IP, servidor=$ENV_PUBLIC_IP${NC}"
        ((ERRORS++))
    else
        echo -e "   ${GREEN}✅ SERVER_IP coincide${NC}"
    fi
    
    if [ "$CLIENT_PORT_1" != "$ENV_GAME_PORT" ]; then
        echo -e "   ${RED}❌ PORT_1 no coincide: cliente=$CLIENT_PORT_1, servidor=$ENV_GAME_PORT${NC}"
        ((ERRORS++))
    else
        echo -e "   ${GREEN}✅ PORT_1 coincide${NC}"
    fi
    
    # PORT_AUTH debe ser igual a PORT_1 para servidor standalone
    if [ "$CLIENT_PORT_AUTH" != "$ENV_GAME_PORT" ]; then
        echo -e "   ${RED}❌ PORT_AUTH incorrecto: $CLIENT_PORT_AUTH (debe ser $ENV_GAME_PORT para servidor standalone)${NC}"
        echo -e "   ${YELLOW}   ⚠️  Cambia PORT_AUTH a $ENV_GAME_PORT en serverinfo.py${NC}"
        ((ERRORS++))
    else
        echo -e "   ${GREEN}✅ PORT_AUTH correcto${NC}"
    fi
fi

echo ""

# ============================================================
# RESUMEN Y RECOMENDACIONES
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las verificaciones pasaron correctamente${NC}"
    echo ""
    echo -e "${GREEN}El servidor y cliente están correctamente configurados.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Verificaciones completadas con $WARNINGS advertencia(s)${NC}"
    echo -e "${GREEN}✅ No hay errores críticos${NC}"
    exit 0
else
    echo -e "${RED}❌ Se encontraron $ERRORS error(es) y $WARNINGS advertencia(s)${NC}"
    echo ""
    echo -e "${YELLOW}Acciones recomendadas:${NC}"
    echo ""
    
    if [ "$ENV_AUTH_SERVER" != "master" ]; then
        echo "   1. Corregir AUTH_SERVER en .env:"
        echo "      sed -i 's/^GAME_AUTH_SERVER=.*/GAME_AUTH_SERVER=master/' .env"
        echo "      docker restart metin2-server"
    fi
    
    if [ -n "$CLIENT_PORT_AUTH" ] && [ "$CLIENT_PORT_AUTH" != "$ENV_GAME_PORT" ]; then
        echo "   2. Corregir PORT_AUTH en serverinfo.py:"
        echo "      Cambiar PORT_AUTH = $CLIENT_PORT_AUTH"
        echo "      A: PORT_AUTH = $ENV_GAME_PORT"
        echo "      Luego recompilar con EterNexus"
    fi
    
    if [ "$CLIENT_SERVER_IP" != "$ENV_PUBLIC_IP" ]; then
        echo "   3. Corregir SERVER_IP en serverinfo.py:"
        echo "      Cambiar SERVER_IP = \"$CLIENT_SERVER_IP\""
        echo "      A: SERVER_IP = \"$ENV_PUBLIC_IP\""
        echo "      Luego recompilar con EterNexus"
    fi
    
    exit 1
fi

