#!/bin/bash
# Script para diagnosticar problemas de conexión MySQL
# Uso: bash diagnosticar-mysql.sh

echo "=========================================="
echo "Diagnóstico de Conexión MySQL"
echo "=========================================="
echo ""

cd /opt/metin2omg

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "1. Verificando archivo .env..."
if [ -f ".env" ]; then
    echo -e "   ${GREEN}✅ Archivo .env encontrado${NC}"
    
    MYSQL_USER=$(grep "^MYSQL_USER=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    MYSQL_HOST=$(grep "^MYSQL_HOST=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    MYSQL_PORT=$(grep "^MYSQL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")
    
    echo "   MYSQL_HOST: $MYSQL_HOST"
    echo "   MYSQL_PORT: $MYSQL_PORT"
    echo "   MYSQL_USER: $MYSQL_USER"
    echo "   MYSQL_PASSWORD: ${MYSQL_PASSWORD:0:3}*** (oculto)"
else
    echo -e "   ${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi
echo ""

echo "2. Verificando si MySQL está corriendo..."
if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
    echo -e "   ${GREEN}✅ MySQL/MariaDB está corriendo${NC}"
elif pgrep -x mysqld > /dev/null || pgrep -x mariadbd > /dev/null; then
    echo -e "   ${GREEN}✅ MySQL/MariaDB está corriendo (proceso encontrado)${NC}"
else
    echo -e "   ${YELLOW}⚠️  No se pudo verificar si MySQL está corriendo${NC}"
fi
echo ""

echo "3. Verificando puerto MySQL..."
if ss -tuln | grep -q ":$MYSQL_PORT"; then
    echo -e "   ${GREEN}✅ Puerto $MYSQL_PORT está escuchando${NC}"
    ss -tuln | grep ":$MYSQL_PORT"
else
    echo -e "   ${RED}❌ Puerto $MYSQL_PORT NO está escuchando${NC}"
fi
echo ""

echo "4. Probando conexión con diferentes métodos..."
echo ""

# Método 1: Conexión estándar
echo "   Método 1: mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER"
export MYSQL_PWD="$MYSQL_PASSWORD"
if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SELECT 1;" 2>&1; then
    echo -e "   ${GREEN}✅ Método 1: Conexión exitosa${NC}"
    CONNECTION_METHOD=1
else
    ERROR1=$?
    echo -e "   ${RED}❌ Método 1 falló (código: $ERROR1)${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "SELECT 1;" 2>&1 | head -3
fi
unset MYSQL_PWD
echo ""

# Método 2: Conexión localhost sin host
echo "   Método 2: mysql -u$MYSQL_USER (localhost)"
export MYSQL_PWD="$MYSQL_PASSWORD"
if mysql -u"$MYSQL_USER" -e "SELECT 1;" 2>&1; then
    echo -e "   ${GREEN}✅ Método 2: Conexión exitosa${NC}"
    CONNECTION_METHOD=2
else
    ERROR2=$?
    echo -e "   ${YELLOW}⚠️  Método 2 falló (código: $ERROR2)${NC}"
fi
unset MYSQL_PWD
echo ""

# Método 3: Conexión con socket
echo "   Método 3: mysql -u$MYSQL_USER --socket=/var/run/mysqld/mysqld.sock"
export MYSQL_PWD="$MYSQL_PASSWORD"
if mysql -u"$MYSQL_USER" --socket=/var/run/mysqld/mysqld.sock -e "SELECT 1;" 2>&1; then
    echo -e "   ${GREEN}✅ Método 3: Conexión exitosa${NC}"
    CONNECTION_METHOD=3
else
    ERROR3=$?
    echo -e "   ${YELLOW}⚠️  Método 3 falló (código: $ERROR3)${NC}"
    
    # Intentar con socket alternativo
    if mysql -u"$MYSQL_USER" --socket=/tmp/mysql.sock -e "SELECT 1;" 2>&1; then
        echo -e "   ${GREEN}✅ Método 3 (socket alternativo): Conexión exitosa${NC}"
        CONNECTION_METHOD=3
    fi
fi
unset MYSQL_PWD
echo ""

# Método 4: Conexión como root
echo "   Método 4: mysql -uroot (si tiene contraseña: proyectalean)"
if mysql -uroot -pproyectalean -e "SELECT 1;" 2>&1; then
    echo -e "   ${GREEN}✅ Método 4: Conexión como root exitosa${NC}"
    CONNECTION_METHOD=4
    ROOT_PASSWORD="proyectalean"
else
    echo -e "   ${YELLOW}⚠️  Método 4 falló${NC}"
    
    # Intentar sin contraseña
    if mysql -uroot -e "SELECT 1;" 2>&1; then
        echo -e "   ${GREEN}✅ Método 4 (sin contraseña): Conexión como root exitosa${NC}"
        CONNECTION_METHOD=4
        ROOT_PASSWORD=""
    fi
fi
echo ""

echo "5. Verificando base de datos metin2_account..."
if [ -n "$CONNECTION_METHOD" ]; then
    case $CONNECTION_METHOD in
        1)
            export MYSQL_PWD="$MYSQL_PASSWORD"
            mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -e "USE metin2_account; SELECT 1;" 2>&1
            ;;
        2)
            export MYSQL_PWD="$MYSQL_PASSWORD"
            mysql -u"$MYSQL_USER" -e "USE metin2_account; SELECT 1;" 2>&1
            ;;
        3)
            export MYSQL_PWD="$MYSQL_PASSWORD"
            mysql -u"$MYSQL_USER" --socket=/var/run/mysqld/mysqld.sock -e "USE metin2_account; SELECT 1;" 2>&1 || mysql -u"$MYSQL_USER" --socket=/tmp/mysql.sock -e "USE metin2_account; SELECT 1;" 2>&1
            ;;
        4)
            if [ -n "$ROOT_PASSWORD" ]; then
                mysql -uroot -p"$ROOT_PASSWORD" -e "USE metin2_account; SELECT 1;" 2>&1
            else
                mysql -uroot -e "USE metin2_account; SELECT 1;" 2>&1
            fi
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Base de datos metin2_account accesible${NC}"
    else
        echo -e "   ${RED}❌ No se puede acceder a metin2_account${NC}"
    fi
    unset MYSQL_PWD
else
    echo -e "   ${RED}❌ No hay método de conexión disponible${NC}"
fi
echo ""

echo "=========================================="
echo "RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""

if [ -n "$CONNECTION_METHOD" ]; then
    echo -e "${GREEN}✅ Se encontró un método de conexión funcional: Método $CONNECTION_METHOD${NC}"
    echo ""
    echo "Para usar este método en los scripts, puedes:"
    echo ""
    case $CONNECTION_METHOD in
        1)
            echo "   export MYSQL_PWD=\"$MYSQL_PASSWORD\""
            echo "   mysql -h\"$MYSQL_HOST\" -P\"$MYSQL_PORT\" -u\"$MYSQL_USER\" ..."
            ;;
        2)
            echo "   export MYSQL_PWD=\"$MYSQL_PASSWORD\""
            echo "   mysql -u\"$MYSQL_USER\" ..."
            ;;
        3)
            echo "   export MYSQL_PWD=\"$MYSQL_PASSWORD\""
            echo "   mysql -u\"$MYSQL_USER\" --socket=/var/run/mysqld/mysqld.sock ..."
            ;;
        4)
            if [ -n "$ROOT_PASSWORD" ]; then
                echo "   mysql -uroot -p\"$ROOT_PASSWORD\" ..."
            else
                echo "   mysql -uroot ..."
            fi
            ;;
    esac
else
    echo -e "${RED}❌ No se encontró ningún método de conexión funcional${NC}"
    echo ""
    echo "Posibles soluciones:"
    echo "   1. Verifica que MySQL esté corriendo: systemctl status mysql"
    echo "   2. Verifica las credenciales en .env"
    echo "   3. Verifica que el usuario tenga permisos"
    echo "   4. Intenta conectarte manualmente: mysql -u$MYSQL_USER -p"
fi
echo ""

