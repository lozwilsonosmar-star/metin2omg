#!/bin/bash
# Script de verificación final para conexión con cliente

echo "=========================================="
echo "Verificación Final: Listo para Cliente"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# ============================================================
# 1. ESTADO DEL CONTENEDOR
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}1. ESTADO DEL CONTENEDOR${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if docker ps | grep -q "metin2-server"; then
    CONTAINER_ID=$(docker ps | grep "metin2-server" | awk '{print $1}')
    CONTAINER_STATUS=$(docker ps | grep "metin2-server" | awk '{print $7}')
    echo -e "${GREEN}✅ Contenedor está corriendo${NC}"
    echo "   ID: $CONTAINER_ID"
    echo "   Estado: $CONTAINER_STATUS"
else
    echo -e "${RED}❌ Contenedor NO está corriendo${NC}"
    ((ERRORS++))
fi

echo ""

# ============================================================
# 2. PUERTOS ESCUCHANDO
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}2. PUERTOS ESCUCHANDO${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

PORTS=("12345:GAME" "8888:DB" "13200:P2P")

for port_info in "${PORTS[@]}"; do
    PORT=$(echo "$port_info" | cut -d':' -f1)
    NAME=$(echo "$port_info" | cut -d':' -f2)
    
    if ss -tuln 2>/dev/null | grep -q ":$PORT "; then
        echo -e "${GREEN}✅ Puerto $PORT ($NAME) está escuchando${NC}"
    else
        echo -e "${RED}❌ Puerto $PORT ($NAME) NO está escuchando${NC}"
        ((ERRORS++))
    fi
done

echo ""

# ============================================================
# 3. CONFIGURACIÓN DEL SERVIDOR (game.conf)
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3. CONFIGURACIÓN DEL SERVIDOR${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if docker ps | grep -q "metin2-server"; then
    GAME_CONF_PATH=$(docker exec metin2-server find / -name "game.conf" 2>/dev/null | head -1)
    
    if [ -n "$GAME_CONF_PATH" ]; then
        GAME_CONF_CONTENT=$(docker exec metin2-server cat "$GAME_CONF_PATH" 2>/dev/null)
        
        # Extraer IP pública
        PUBLIC_IP=$(echo "$GAME_CONF_CONTENT" | grep "^PUBLIC_IP:" | awk '{print $2}')
        GAME_PORT=$(echo "$GAME_CONF_CONTENT" | grep "^PORT:" | awk '{print $2}')
        AUTH_SERVER=$(echo "$GAME_CONF_CONTENT" | grep "^AUTH_SERVER:" | awk '{print $2}')
        
        echo "Configuración del servidor:"
        echo "   IP Pública: $PUBLIC_IP"
        echo "   Puerto del juego: $GAME_PORT"
        echo "   AUTH_SERVER: $AUTH_SERVER"
        echo ""
        
        # Verificar que es IPv4
        if [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo -e "${GREEN}✅ IP es IPv4 (correcto para cliente Metin2)${NC}"
        else
            echo -e "${RED}❌ IP NO es IPv4: $PUBLIC_IP${NC}"
            echo -e "${YELLOW}   El cliente Metin2 necesita IPv4${NC}"
            ((ERRORS++))
        fi
        
        # Verificar AUTH_SERVER
        if [ "$AUTH_SERVER" = "master" ]; then
            echo -e "${GREEN}✅ AUTH_SERVER está configurado como 'master'${NC}"
        else
            echo -e "${YELLOW}⚠️  AUTH_SERVER: $AUTH_SERVER (debería ser 'master' para standalone)${NC}"
            ((WARNINGS++))
        fi
    else
        echo -e "${RED}❌ No se pudo leer game.conf${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}❌ Contenedor no está corriendo${NC}"
    ((ERRORS++))
fi

echo ""

# ============================================================
# 4. LOGS DEL SERVIDOR
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}4. LOGS DEL SERVIDOR (últimas 50 líneas)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if docker ps | grep -q "metin2-server"; then
    LOGS=$(docker logs --tail 50 metin2-server 2>&1)
    
    # Verificar indicadores positivos
    if echo "$LOGS" | grep -q "TCP listening"; then
        TCP_LINE=$(echo "$LOGS" | grep "TCP listening" | tail -1)
        echo -e "${GREEN}✅ $TCP_LINE${NC}"
    else
        echo -e "${RED}❌ No se encontró 'TCP listening'${NC}"
        ((ERRORS++))
    fi
    
    if echo "$LOGS" | grep -q "MasterAuth"; then
        echo -e "${GREEN}✅ MasterAuth configurado${NC}"
    else
        echo -e "${YELLOW}⚠️  No se encontró 'MasterAuth'${NC}"
        ((WARNINGS++))
    fi
    
    if echo "$LOGS" | grep -q "LANGUAGE"; then
        LANGUAGE_LINE=$(echo "$LOGS" | grep "LANGUAGE" | tail -1)
        if echo "$LANGUAGE_LINE" | grep -q "critical\|ERROR"; then
            echo -e "${RED}❌ Error con LANGUAGE: $LANGUAGE_LINE${NC}"
            ((ERRORS++))
        else
            echo -e "${GREEN}✅ LANGUAGE configurado correctamente${NC}"
        fi
    fi
    
    # Verificar errores críticos
    CRITICAL_ERRORS=$(echo "$LOGS" | grep -i "critical\|ERROR" | grep -v "item_proto_test.txt\|No test file" | tail -5)
    
    if [ -n "$CRITICAL_ERRORS" ]; then
        echo ""
        echo -e "${RED}❌ Errores críticos encontrados:${NC}"
        echo "$CRITICAL_ERRORS" | while read line; do
            echo -e "${RED}   $line${NC}"
        done
        ((ERRORS++))
    else
        echo -e "${GREEN}✅ No hay errores críticos${NC}"
    fi
else
    echo -e "${RED}❌ No se pueden leer logs (contenedor no está corriendo)${NC}"
    ((ERRORS++))
fi

echo ""

# ============================================================
# 5. BASES DE DATOS Y TABLAS
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}5. BASES DE DATOS Y TABLAS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

export MYSQL_PWD="proyectalean"
MYSQL_USER="root"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"

# Verificar tablas críticas
CRITICAL_TABLES=("account" "player" "player_index" "item" "skill_proto" "locale")

for table in "${CRITICAL_TABLES[@]}"; do
    if [ "$table" = "locale" ]; then
        DB="metin2_common"
    else
        DB="metin2_player"
    fi
    
    EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$DB" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "^$table$" || echo "0")
    EXISTS=$(echo "$EXISTS" | tr -d '\n' | head -1)
    
    if [ "$EXISTS" -gt 0 ] 2>/dev/null; then
        COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -D"$DB" -sN -e "SELECT COUNT(*) FROM \`$table\`;" 2>/dev/null || echo "0")
        echo -e "${GREEN}✅ $table en $DB ($COUNT registros)${NC}"
    else
        echo -e "${RED}❌ $table NO existe en $DB${NC}"
        ((ERRORS++))
    fi
done

unset MYSQL_PWD

echo ""

# ============================================================
# 6. CONFIGURACIÓN DEL CLIENTE (instrucciones)
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}6. CONFIGURACIÓN DEL CLIENTE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ -n "$PUBLIC_IP" ] && [ -n "$GAME_PORT" ]; then
    echo "Configuración que debe tener el cliente:"
    echo ""
    echo "Archivo: serverinfo.py (o serverinfo.pyc)"
    echo ""
    echo "   IP del servidor: $PUBLIC_IP"
    echo "   Puerto del juego: $GAME_PORT"
    echo "   AUTH_SERVER: master (o la IP del servidor)"
    echo ""
    echo -e "${YELLOW}⚠️  Verifica que el cliente tenga:${NC}"
    echo "   1. La misma IP que el servidor: $PUBLIC_IP"
    echo "   2. El mismo puerto: $GAME_PORT"
    echo "   3. La misma configuración de criptografía"
    echo "   4. El mismo locale (kr/korea)"
else
    echo -e "${YELLOW}⚠️  No se pudo obtener la configuración del servidor${NC}"
fi

echo ""

# ============================================================
# RESUMEN FINAL
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN FINAL${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ TODO ESTÁ LISTO PARA CONECTARSE${NC}"
    echo ""
    echo "El servidor está configurado correctamente y listo para recibir conexiones."
    echo ""
    echo "Próximos pasos:"
    echo "   1. Verifica la configuración del cliente (serverinfo.py)"
    echo "   2. Asegúrate de que el firewall permita el puerto $GAME_PORT"
    echo "   3. Intenta conectarte desde el cliente"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Listo con $WARNINGS advertencia(s)${NC}"
    echo ""
    echo "El servidor debería funcionar, pero revisa las advertencias."
else
    echo -e "${RED}❌ Se encontraron $ERRORS error(es) y $WARNINGS advertencia(s)${NC}"
    echo ""
    echo "Corrige los errores antes de intentar conectarte."
fi

echo ""
echo "Para ver logs en tiempo real:"
echo "   docker logs -f metin2-server"
echo ""
echo "Para verificar conexiones:"
echo "   ss -tuln | grep -E '12345|8888|13200'"
echo ""

