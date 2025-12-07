#!/bin/bash
# Script para verificar la configuración de bases de datos
# Uso: bash verificar-configuracion-db.sh

echo "=========================================="
echo "Verificación de Configuración de Bases de Datos"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Verificando variables en .env..."
echo ""

if [ -f ".env" ]; then
    echo "   MYSQL_DB_ACCOUNT: $(grep "^MYSQL_DB_ACCOUNT=" .env | cut -d'=' -f2)"
    echo "   MYSQL_DB_PLAYER: $(grep "^MYSQL_DB_PLAYER=" .env | cut -d'=' -f2)"
    echo "   MYSQL_DB_COMMON: $(grep "^MYSQL_DB_COMMON=" .env | cut -d'=' -f2)"
    echo ""
else
    echo "   ⚠️  Archivo .env no encontrado"
    echo ""
fi

echo "2. Verificando tablas account en cada base de datos..."
echo ""

echo "   metin2_account.account:"
mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT COUNT(*) as total FROM account;" 2>/dev/null | tail -1

echo ""
echo "   metin2_player.account:"
mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT COUNT(*) as total FROM account;" 2>/dev/null 2>&1 | tail -1

echo ""
echo "3. Verificando configuración en game.conf del contenedor..."
echo ""

if docker ps | grep -q "metin2-server"; then
    echo "   Buscando configuración de bases de datos..."
    docker exec metin2-server grep -E "SQL_|DB_|account|player" /opt/metin2/game.conf 2>/dev/null | head -20
    echo ""
else
    echo "   ⚠️  Contenedor no está corriendo"
    echo ""
fi

echo "4. Solución:"
echo ""
echo "   El servidor está buscando 'account' en 'metin2_player' pero está en 'metin2_account'"
echo ""
echo "   Opción 1: Crear tabla account en metin2_player (no recomendado)"
echo "   Opción 2: Verificar que el servidor use la conexión correcta (recomendado)"
echo ""
echo "   Para verificar, revisa los logs del servidor al iniciar para ver qué"
echo "   base de datos se está usando para las consultas de autenticación."
echo ""

