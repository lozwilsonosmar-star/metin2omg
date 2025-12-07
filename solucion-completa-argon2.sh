#!/bin/bash
# Script completo para instalar dependencias y generar hash Argon2id
# Uso: bash solucion-completa-argon2.sh

echo "=========================================="
echo "Solución Completa para Hash Argon2id"
echo "=========================================="
echo ""

cd /opt/metin2omg

TEST_USER="test"
TEST_PASSWORD="metin2test123"

# Paso 1: Instalar Python3 y pip si no están
echo "1. Verificando Python3 y pip..."
if ! command -v python3 &> /dev/null; then
    echo "   Instalando Python3..."
    sudo apt-get update -qq
    sudo apt-get install -y python3
fi

if ! python3 -m pip --version &> /dev/null; then
    echo "   Instalando python3-pip..."
    sudo apt-get update -qq
    sudo apt-get install -y python3-pip
fi

if python3 -m pip --version &> /dev/null; then
    echo "   ✅ Python3 y pip están disponibles"
else
    echo "   ❌ No se pudo instalar pip"
    echo ""
    echo "   Intentando método alternativo..."
    # Intentar instalar pip usando get-pip.py
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3 2>&1 | tail -3
fi

echo ""

# Paso 2: Instalar argon2-cffi
echo "2. Instalando argon2-cffi..."
if ! python3 -c "import argon2" 2>/dev/null; then
    # Intentar con python3 -m pip
    if python3 -m pip install --user argon2-cffi 2>&1 | tail -5; then
        echo "   ✅ argon2-cffi instalado"
    else
        echo "   ⚠️  Error al instalar con --user, intentando sin --user..."
        sudo python3 -m pip install argon2-cffi 2>&1 | tail -5
    fi
    
    # Verificar si se instaló
    if python3 -c "import argon2" 2>/dev/null; then
        echo "   ✅ argon2-cffi verificado"
    else
        echo "   ❌ No se pudo instalar argon2-cffi"
        echo ""
        echo "   Intentando instalar desde repositorios..."
        # Algunas distribuciones tienen argon2 en los repositorios
        sudo apt-get update -qq
        sudo apt-get install -y libargon2-dev python3-dev build-essential 2>&1 | tail -3
        
        # Intentar instalar nuevamente
        python3 -m pip install --user argon2-cffi 2>&1 | tail -3
    fi
else
    echo "   ✅ argon2-cffi ya está instalado"
fi

echo ""

# Paso 3: Generar hash
echo "3. Generando hash Argon2id para: $TEST_PASSWORD"
echo ""

ARGON2_HASH=$(python3 <<PYTHON
try:
    from argon2 import PasswordHasher
    ph = PasswordHasher()
    hash = ph.hash('$TEST_PASSWORD')
    print(hash)
except Exception as e:
    print("")
    import sys
    sys.stderr.write(f"Error: {e}\n")
PYTHON
2>&1)

if [ -n "$ARGON2_HASH" ] && [ "${#ARGON2_HASH}" -gt 50 ]; then
    echo "   ✅ Hash generado exitosamente"
    echo "   Hash (primeros 80 caracteres): ${ARGON2_HASH:0:80}..."
    echo ""
    
    # Paso 4: Actualizar cuenta
    echo "4. Actualizando cuenta '$TEST_USER'..."
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
UPDATE account SET password='$ARGON2_HASH', status='OK', last_play=NOW() WHERE login='$TEST_USER';
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Cuenta actualizada exitosamente"
        echo ""
        echo "5. Verificando cuenta..."
        mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, LEFT(password, 60) as password_preview, status FROM account WHERE login='$TEST_USER';" 2>/dev/null
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
    echo "   ❌ Error al generar el hash"
    echo ""
    echo "   Mensaje de error:"
    echo "$ARGON2_HASH" | grep -i error || echo "   (sin detalles)"
    echo ""
    echo "SOLUCIÓN MANUAL:"
    echo ""
    echo "1. Instala las dependencias:"
    echo "   sudo apt-get update"
    echo "   sudo apt-get install -y python3 python3-pip"
    echo "   sudo apt-get install -y python3-dev build-essential libffi-dev"
    echo ""
    echo "2. Instala argon2-cffi:"
    echo "   python3 -m pip install --user argon2-cffi"
    echo ""
    echo "3. Genera el hash:"
    echo "   python3 -c \"from argon2 import PasswordHasher; ph = PasswordHasher(); print(ph.hash('$TEST_PASSWORD'))\""
    echo ""
    echo "4. Actualiza la cuenta con el hash generado"
    echo ""
fi

