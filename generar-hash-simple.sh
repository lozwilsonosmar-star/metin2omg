#!/bin/bash
# Script simple para generar hash Argon2id usando Python
# Uso: bash generar-hash-simple.sh

echo "=========================================="
echo "Generación Simple de Hash Argon2id"
echo "=========================================="
echo ""

cd /opt/metin2omg

TEST_PASSWORD="metin2test123"

# Verificar Python3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 no está instalado"
    echo ""
    echo "Instalando Python3..."
    sudo apt-get update -qq
    sudo apt-get install -y python3 python3-pip
fi

# Instalar argon2-cffi si no está instalado
if ! python3 -c "import argon2" 2>/dev/null; then
    echo "Instalando argon2-cffi..."
    python3 -m pip install --user argon2-cffi 2>&1 | tail -3
fi

# Generar hash
echo "Generando hash Argon2id para: $TEST_PASSWORD"
echo ""

ARGON2_HASH=$(python3 <<PYTHON
from argon2 import PasswordHasher
ph = PasswordHasher()
hash = ph.hash('$TEST_PASSWORD')
print(hash)
PYTHON
)

if [ -n "$ARGON2_HASH" ]; then
    echo "✅ Hash generado:"
    echo "$ARGON2_HASH"
    echo ""
    echo "Actualizando cuenta 'test'..."
    
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
UPDATE account SET password='$ARGON2_HASH', status='OK', last_play=NOW() WHERE login='test';
EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ Cuenta actualizada exitosamente"
        echo ""
        echo "Verificando..."
        mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, LEFT(password, 60) as password_preview, status FROM account WHERE login='test';" 2>/dev/null
        echo ""
        echo "✅ Listo. Usuario: test, Contraseña: $TEST_PASSWORD"
    else
        echo "❌ Error al actualizar la cuenta"
    fi
else
    echo "❌ Error al generar el hash"
    echo ""
    echo "Intenta instalar manualmente:"
    echo "   pip3 install --user argon2-cffi"
fi

echo ""

