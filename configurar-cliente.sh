#!/bin/bash
# Script para configurar el cliente Metin2 con la IP del servidor
# Uso: bash configurar-cliente.sh

echo "=========================================="
echo "Configuración del Cliente Metin2"
echo "=========================================="
echo ""

# IP y puerto del servidor
SERVER_IP="72.61.12.2"
SERVER_PORT="12345"
SERVER_NAME="Metin2OMG"

# Ruta base del cliente
CLIENT_PATH="Client-20251206T130044Z-3-001/Client/Client/Client"

# Verificar que existe la carpeta del cliente
if [ ! -d "$CLIENT_PATH" ]; then
    echo "❌ Error: No se encontró la carpeta del cliente en: $CLIENT_PATH"
    echo "   Asegúrate de que la carpeta del cliente esté en el proyecto"
    exit 1
fi

echo "📋 Configurando cliente en: $CLIENT_PATH"
echo ""

# 1. Configurar channel.inf
echo "1. Configurando channel.inf..."
CHANNEL_FILE="$CLIENT_PATH/channel.inf"
if [ -f "$CHANNEL_FILE" ]; then
    echo "   ✅ channel.inf encontrado"
    echo "   Contenido actual:"
    cat "$CHANNEL_FILE"
    echo ""
    echo "   ℹ️  channel.inf contiene: canal_id servidor_id estado"
    echo "   (No necesita modificación para la IP del servidor)"
else
    echo "   ⚠️  channel.inf no encontrado, creando uno nuevo..."
    echo "1 1 0" > "$CHANNEL_FILE"
    echo "   ✅ channel.inf creado"
fi
echo ""

# 2. Crear/actualizar serverlist.txt
echo "2. Creando/actualizando serverlist.txt..."
SERVERLIST_FILE="$CLIENT_PATH/serverlist.txt"
echo "$SERVER_NAME	$SERVER_IP	$SERVER_PORT" > "$SERVERLIST_FILE"
echo "   ✅ serverlist.txt creado/actualizado"
echo "   Contenido:"
cat "$SERVERLIST_FILE"
echo ""

# 3. Configurar serverinfo.py (archivo principal de configuración)
echo "3. Configurando serverinfo.py..."
SERVERINFO_FILE="$CLIENT_PATH/Eternexus/root/serverinfo.py"
if [ -f "$SERVERINFO_FILE" ]; then
    echo "   ✅ serverinfo.py encontrado"
    echo "   Actualizando configuración..."
    
    # Crear backup
    cp "$SERVERINFO_FILE" "$SERVERINFO_FILE.backup"
    echo "   ✅ Backup creado: serverinfo.py.backup"
    
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
    
    echo "   ✅ serverinfo.py actualizado"
    echo "   Cambios realizados:"
    echo "     - SERVER_IP = \"$SERVER_IP\""
    echo "     - SERVER_NAME = \"$SERVER_NAME\""
    echo "     - PORT_1, PORT_2, PORT_3, PORT_4, PORT_MARK = $SERVER_PORT"
else
    echo "   ⚠️  serverinfo.py no encontrado en: $SERVERINFO_FILE"
fi
echo ""

# 4. Crear archivo de instrucciones
echo "4. Creando archivo de instrucciones..."
INSTRUCCIONES_FILE="$CLIENT_PATH/INSTRUCCIONES_CONEXION.txt"
cat > "$INSTRUCCIONES_FILE" << EOF
==========================================
INSTRUCCIONES PARA CONECTAR AL SERVIDOR
==========================================

IP del Servidor: $SERVER_IP
Puerto del Juego: $SERVER_PORT
Nombre del Servidor: $SERVER_NAME

==========================================
OPCIONES DE CONFIGURACIÓN:
==========================================

OPCIÓN 1: Usar serverlist.txt (Recomendado)
--------------------------------------------
El archivo serverlist.txt ya está configurado con:
$SERVER_NAME	$SERVER_IP	$SERVER_PORT

Si el cliente no lee este archivo automáticamente, puedes:
1. Copiar serverlist.txt a la carpeta raíz del cliente
2. O modificar el ejecutable del cliente (requiere herramientas)

OPCIÓN 2: Modificar el ejecutable del cliente
--------------------------------------------
1. Usar un editor hexadecimal (HxD, Hex Editor, etc.)
2. Buscar la IP antigua en el ejecutable
3. Reemplazarla por: $SERVER_IP
4. Buscar el puerto antiguo
5. Reemplazarlo por: $SERVER_PORT

OPCIÓN 3: Usar un launcher personalizado
--------------------------------------------
Crear un launcher que modifique la configuración antes de iniciar el cliente.

==========================================
VERIFICACIÓN:
==========================================

1. Asegúrate de que el servidor esté corriendo:
   - Puerto 12345 debe estar escuchando
   - Verifica con: ss -tuln | grep 12345

2. Verifica el firewall:
   - El puerto 12345 debe estar abierto
   - Verifica con: sudo ufw status

3. Prueba la conexión:
   - Inicia el cliente
   - Intenta conectarte con:
     Usuario: test
     Contraseña: test123

==========================================
EOF

echo "   ✅ Instrucciones creadas en: $INSTRUCCIONES_FILE"
echo ""

# 5. Resumen
echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Archivos configurados:"
echo "   ✅ serverinfo.py: SERVER_IP=$SERVER_IP, SERVER_NAME=$SERVER_NAME, PORT=$SERVER_PORT"
echo "   ✅ serverlist.txt: $SERVER_NAME	$SERVER_IP	$SERVER_PORT"
echo "   ✅ channel.inf: (verificado)"
echo "   ✅ INSTRUCCIONES_CONEXION.txt: (creado)"
echo ""
echo "🎮 Próximos pasos:"
echo "   1. Copia la carpeta del cliente a tu máquina Windows"
echo "   2. Si el cliente no lee serverlist.txt automáticamente,"
echo "      modifica el ejecutable con un editor hexadecimal"
echo "   3. Inicia el cliente y prueba la conexión"
echo ""
echo "📝 Nota:"
echo "   Algunos clientes tienen la IP hardcodeada en el ejecutable."
echo "   En ese caso, necesitarás usar un editor hexadecimal para cambiarla."
echo ""

