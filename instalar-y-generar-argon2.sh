#!/bin/bash
# Script mejorado para instalar herramientas y generar hash Argon2id
# Uso: bash instalar-y-generar-argon2.sh

echo "=========================================="
echo "Instalación y Generación de Hash Argon2id"
echo "=========================================="
echo ""

cd /opt/metin2omg

TEST_USER="test"
TEST_PASSWORD="metin2test123"

echo "Contraseña a hashear: $TEST_PASSWORD"
echo ""

# Método 1: Intentar instalar argon2 (herramienta de línea de comandos)
echo "1. Intentando instalar argon2..."
if ! command -v argon2 &> /dev/null; then
    echo "   Instalando argon2..."
    sudo apt-get update -qq 2>/dev/null
    sudo apt-get install -y argon2 2>/dev/null
    
    if [ $? -eq 0 ] && command -v argon2 &> /dev/null; then
        echo "   ✅ argon2 instalado correctamente"
    else
        echo "   ⚠️  No se pudo instalar argon2 (puede requerir repositorios adicionales)"
    fi
else
    echo "   ✅ argon2 ya está instalado"
fi

# Método 2: Intentar instalar Python3 y argon2-cffi
echo ""
echo "2. Intentando instalar Python3 y argon2-cffi..."
if ! command -v python3 &> /dev/null; then
    echo "   Instalando Python3..."
    sudo apt-get update -qq 2>/dev/null
    sudo apt-get install -y python3 python3-pip 2>/dev/null
fi

if command -v python3 &> /dev/null; then
    echo "   ✅ Python3 disponible"
    
    # Verificar si argon2-cffi está instalado
    if ! python3 -c "import argon2" 2>/dev/null; then
        echo "   Instalando argon2-cffi..."
        
        # Intentar con pip3
        if command -v pip3 &> /dev/null; then
            pip3 install --user argon2-cffi 2>&1 | grep -v "WARNING" | tail -5
        else
            # Intentar con python3 -m pip
            python3 -m pip install --user argon2-cffi 2>&1 | grep -v "WARNING" | tail -5
        fi
        
        # Verificar si se instaló correctamente
        if python3 -c "import argon2" 2>/dev/null; then
            echo "   ✅ argon2-cffi instalado correctamente"
        else
            echo "   ⚠️  No se pudo instalar argon2-cffi"
        fi
    else
        echo "   ✅ argon2-cffi ya está instalado"
    fi
else
    echo "   ⚠️  Python3 no está disponible"
fi

echo ""
echo "3. Generando hash Argon2id..."
echo ""

ARGON2_HASH=""

# Intentar método 1: argon2 (comando)
if command -v argon2 &> /dev/null; then
    echo "   Usando argon2 (comando)..."
    SALT=$(openssl rand -hex 16 2>/dev/null || echo "salt123456789012345678901234567890")
    
    ARGON2_OUTPUT=$(echo -n "$TEST_PASSWORD" | argon2 "$SALT" -id -t 3 -m 12 -p 1 -l 32 2>&1)
    ARGON2_HASH=$(echo "$ARGON2_OUTPUT" | grep "Encoded" | awk '{print $2}')
    
    if [ -n "$ARGON2_HASH" ]; then
        echo "   ✅ Hash generado con argon2"
    fi
fi

# Intentar método 2: Python con argon2-cffi
if [ -z "$ARGON2_HASH" ] && command -v python3 &> /dev/null; then
    if python3 -c "import argon2" 2>/dev/null; then
        echo "   Usando Python3 con argon2-cffi..."
        
        ARGON2_HASH=$(python3 <<PYTHON
try:
    from argon2 import PasswordHasher
    ph = PasswordHasher()
    hash = ph.hash('$TEST_PASSWORD')
    print(hash)
except Exception as e:
    print("")
PYTHON
)
        
        if [ -n "$ARGON2_HASH" ]; then
            echo "   ✅ Hash generado con Python3"
        fi
    fi
fi

# Si aún no tenemos hash, intentar método 3: usar el contenedor Docker
if [ -z "$ARGON2_HASH" ]; then
    echo "   Intentando usar el contenedor Docker..."
    
    if docker ps | grep -q "metin2-server"; then
        echo "   El contenedor está corriendo, pero necesitamos compilar un programa..."
        echo "   ⚠️  Este método requiere más tiempo"
    fi
fi

# Si tenemos hash, actualizar la cuenta
if [ -n "$ARGON2_HASH" ]; then
    echo ""
    echo "4. Hash generado exitosamente:"
    echo "   ${ARGON2_HASH:0:80}..."
    echo ""
    
    echo "5. Actualizando cuenta '$TEST_USER'..."
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
UPDATE account SET password='$ARGON2_HASH', status='OK', last_play=NOW() WHERE login='$TEST_USER';
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Cuenta actualizada exitosamente"
        echo ""
        echo "6. Verificando cuenta..."
        mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, LEFT(password, 80) as password_preview, status FROM account WHERE login='$TEST_USER';" 2>/dev/null
        echo ""
        echo "=========================================="
        echo "✅ ¡LISTO!"
        echo "=========================================="
        echo ""
        echo "📋 Credenciales para conectarte:"
        echo "   Usuario: $TEST_USER"
        echo "   Contraseña: $TEST_PASSWORD"
        echo ""
        echo "🎮 Ahora intenta conectarte desde el cliente"
        echo ""
        exit 0
    else
        echo "   ❌ Error al actualizar la cuenta"
    fi
else
    echo ""
    echo "❌ No se pudo generar el hash Argon2id"
    echo ""
    echo "SOLUCIÓN MANUAL:"
    echo ""
    echo "Opción A - Instalar argon2 manualmente:"
    echo "   sudo apt-get update"
    echo "   sudo apt-get install -y argon2"
    echo "   echo -n '$TEST_PASSWORD' | argon2 'salt123456789012345678901234567890' -id -t 3 -m 12 -p 1 -l 32"
    echo ""
    echo "Opción B - Instalar Python y argon2-cffi:"
    echo "   sudo apt-get update"
    echo "   sudo apt-get install -y python3 python3-pip"
    echo "   pip3 install --user argon2-cffi"
    echo "   python3 -c \"from argon2 import PasswordHasher; ph = PasswordHasher(); print(ph.hash('$TEST_PASSWORD'))\""
    echo ""
    echo "Luego copia el hash y ejecuta:"
    echo "   mysql -uroot -pproyectalean -Dmetin2_account -e \"UPDATE account SET password='TU_HASH_AQUI' WHERE login='test';\""
    echo ""
fi

