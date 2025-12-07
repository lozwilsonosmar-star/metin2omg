#!/bin/bash
# Script para corregir la configuración del cliente
# Uso: bash corregir-configuracion-cliente.sh

echo "=========================================="
echo "Corrección de Configuración del Cliente"
echo "=========================================="
echo ""

cd /opt/metin2omg

# IP y puerto del servidor
SERVER_IP="72.61.12.2"
SERVER_PORT="12345"
SERVER_NAME="Metin2OMG"

# Ruta del archivo de configuración
SERVERINFO_FILE="Client-20251206T130044Z-3-001/Client/Client/Client/Eternexus/root/serverinfo.py"

# Verificar que existe el archivo
if [ ! -f "$SERVERINFO_FILE" ]; then
    echo "❌ Error: No se encontró el archivo serverinfo.py"
    echo "   Ruta esperada: $SERVERINFO_FILE"
    echo ""
    echo "   Si el cliente está en tu máquina Windows, debes:"
    echo "   1. Abrir el archivo serverinfo.py en:"
    echo "      Client-20251206T130044Z-3-001/Client/Client/Client/Eternexus/root/serverinfo.py"
    echo "   2. Verificar que tenga:"
    echo "      SERVER_IP = \"$SERVER_IP\""
    echo "      PORT_1 = $SERVER_PORT"
    exit 1
fi

echo "📋 Configurando serverinfo.py..."
echo ""

# Crear backup
cp "$SERVERINFO_FILE" "$SERVERINFO_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup creado"

# Verificar configuración actual
echo ""
echo "Configuración actual:"
grep -E "SERVER_IP|SERVER_NAME|PORT_1" "$SERVERINFO_FILE" | head -3
echo ""

# Actualizar SERVER_IP
sed -i "s/SERVER_IP[[:space:]]*=[[:space:]]*\"[^\"]*\"/SERVER_IP = \"$SERVER_IP\"/" "$SERVERINFO_FILE"

# Actualizar SERVER_NAME
sed -i "s/SERVER_NAME[[:space:]]*=[[:space:]]*\"[^\"]*\"/SERVER_NAME = \"$SERVER_NAME\"/" "$SERVERINFO_FILE"

# Actualizar puertos
sed -i "s/PORT_1[[:space:]]*=[[:space:]]*[0-9]*/PORT_1 = $SERVER_PORT/" "$SERVERINFO_FILE"
sed -i "s/PORT_2[[:space:]]*=[[:space:]]*[0-9]*/PORT_2 = $SERVER_PORT/" "$SERVERINFO_FILE"
sed -i "s/PORT_3[[:space:]]*=[[:space:]]*[0-9]*/PORT_3 = $SERVER_PORT/" "$SERVERINFO_FILE"
sed -i "s/PORT_4[[:space:]]*=[[:space:]]*[0-9]*/PORT_4 = $SERVER_PORT/" "$SERVERINFO_FILE"
sed -i "s/PORT_MARK[[:space:]]*=[[:space:]]*[0-9]*/PORT_MARK = $SERVER_PORT/" "$SERVERINFO_FILE"

echo "✅ Configuración actualizada"
echo ""
echo "Nueva configuración:"
grep -E "SERVER_IP|SERVER_NAME|PORT_1" "$SERVERINFO_FILE" | head -3
echo ""

# Verificar que los cambios se aplicaron
CURRENT_IP=$(grep "SERVER_IP[[:space:]]*=" "$SERVERINFO_FILE" | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/')
CURRENT_PORT=$(grep "PORT_1[[:space:]]*=" "$SERVERINFO_FILE" | head -1 | sed 's/.*= *\([0-9]*\).*/\1/')

if [ "$CURRENT_IP" = "$SERVER_IP" ] && [ "$CURRENT_PORT" = "$SERVER_PORT" ]; then
    echo "✅ Configuración verificada correctamente"
    echo "   SERVER_IP = $CURRENT_IP"
    echo "   PORT_1 = $CURRENT_PORT"
else
    echo "⚠️  Advertencia: La configuración podría no haberse aplicado correctamente"
    echo "   IP actual: $CURRENT_IP (esperada: $SERVER_IP)"
    echo "   Puerto actual: $CURRENT_PORT (esperado: $SERVER_PORT)"
fi

echo ""
echo "=========================================="
echo "✅ Corrección completada"
echo "=========================================="
echo ""
echo "📝 Nota importante:"
echo "   Si el cliente está en tu máquina Windows, debes copiar"
echo "   el archivo serverinfo.py actualizado a tu cliente."
echo ""
echo "   Ruta en Windows:"
echo "   Client-20251206T130044Z-3-001\\Client\\Client\\Client\\Eternexus\\root\\serverinfo.py"
echo ""

