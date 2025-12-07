#!/bin/bash
# Script para generar hash Argon2id y actualizar cuenta
# Uso: bash generar-hash-argon2.sh

echo "=========================================="
echo "Generación de Hash Argon2id para Cuenta"
echo "=========================================="
echo ""

cd /opt/metin2omg

TEST_USER="test"
TEST_PASSWORD="metin2test123"

echo "Contraseña a hashear: $TEST_PASSWORD"
echo ""

# Intentar método 1: Usar argon2 si está instalado
if command -v argon2 &> /dev/null; then
    echo "✅ Encontrado: argon2 (comando del sistema)"
    echo "Generando hash Argon2id..."
    
    # Generar salt aleatorio
    SALT=$(openssl rand -hex 16)
    
    # Generar hash Argon2id
    # Parámetros típicos: -t 3 (time cost), -m 12 (memory cost), -p 1 (parallelism), -l 32 (hash length)
    ARGON2_HASH=$(echo -n "$TEST_PASSWORD" | argon2 "$SALT" -id -t 3 -m 12 -p 1 -l 32 2>/dev/null | grep "Encoded" | awk '{print $2}')
    
    if [ -n "$ARGON2_HASH" ]; then
        echo "✅ Hash generado: $ARGON2_HASH"
        echo ""
        
        echo "Actualizando cuenta '$TEST_USER'..."
        mysql -uroot -pproyectalean -Dmetin2_account <<EOF
UPDATE account SET password='$ARGON2_HASH', status='OK', last_play=NOW() WHERE login='$TEST_USER';
EOF
        
        if [ $? -eq 0 ]; then
            echo "✅ Cuenta actualizada exitosamente"
            echo ""
            echo "Verificando cuenta..."
            mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, LEFT(password, 80) as password_preview, status FROM account WHERE login='$TEST_USER';" 2>/dev/null
            echo ""
            echo "✅ Listo. Intenta conectarte con:"
            echo "   Usuario: $TEST_USER"
            echo "   Contraseña: $TEST_PASSWORD"
            exit 0
        fi
    fi
fi

# Intentar método 2: Usar Python con argon2-cffi
if command -v python3 &> /dev/null; then
    echo "⚠️  Intentando con Python3..."
    
    # Verificar si argon2-cffi está instalado
    if python3 -c "import argon2" 2>/dev/null; then
        echo "✅ Encontrado: python3 con argon2-cffi"
        echo "Generando hash Argon2id..."
        
        ARGON2_HASH=$(python3 <<PYTHON
from argon2 import PasswordHasher
ph = PasswordHasher()
hash = ph.hash('$TEST_PASSWORD')
print(hash)
PYTHON
)
        
        if [ -n "$ARGON2_HASH" ]; then
            echo "✅ Hash generado: $ARGON2_HASH"
            echo ""
            
            echo "Actualizando cuenta '$TEST_USER'..."
            mysql -uroot -pproyectalean -Dmetin2_account <<EOF
UPDATE account SET password='$ARGON2_HASH', status='OK', last_play=NOW() WHERE login='$TEST_USER';
EOF
            
            if [ $? -eq 0 ]; then
                echo "✅ Cuenta actualizada exitosamente"
                echo ""
                echo "Verificando cuenta..."
                mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, LEFT(password, 80) as password_preview, status FROM account WHERE login='$TEST_USER';" 2>/dev/null
                echo ""
                echo "✅ Listo. Intenta conectarte con:"
                echo "   Usuario: $TEST_USER"
                echo "   Contraseña: $TEST_PASSWORD"
                exit 0
            fi
        fi
    else
        echo "⚠️  argon2-cffi no está instalado"
        echo ""
        echo "Instalando argon2-cffi..."
        pip3 install argon2-cffi --quiet 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✅ argon2-cffi instalado"
            echo "Generando hash Argon2id..."
            
            ARGON2_HASH=$(python3 <<PYTHON
from argon2 import PasswordHasher
ph = PasswordHasher()
hash = ph.hash('$TEST_PASSWORD')
print(hash)
PYTHON
)
            
            if [ -n "$ARGON2_HASH" ]; then
                echo "✅ Hash generado: $ARGON2_HASH"
                echo ""
                
                echo "Actualizando cuenta '$TEST_USER'..."
                mysql -uroot -pproyectalean -Dmetin2_account <<EOF
UPDATE account SET password='$ARGON2_HASH', status='OK', last_play=NOW() WHERE login='$TEST_USER';
EOF
                
                if [ $? -eq 0 ]; then
                    echo "✅ Cuenta actualizada exitosamente"
                    echo ""
                    echo "Verificando cuenta..."
                    mysql -uroot -pproyectalean -Dmetin2_account -e "SELECT login, LEFT(password, 80) as password_preview, status FROM account WHERE login='$TEST_USER';" 2>/dev/null
                    echo ""
                    echo "✅ Listo. Intenta conectarte con:"
                    echo "   Usuario: $TEST_USER"
                    echo "   Contraseña: $TEST_PASSWORD"
                    exit 0
                fi
            fi
        fi
    fi
fi

# Si llegamos aquí, no se pudo generar el hash
echo "❌ No se pudo generar el hash Argon2id automáticamente"
echo ""
echo "SOLUCIÓN MANUAL:"
echo ""
echo "1. Instala argon2:"
echo "   sudo apt-get update"
echo "   sudo apt-get install -y argon2"
echo ""
echo "2. O instala Python con argon2-cffi:"
echo "   pip3 install argon2-cffi"
echo ""
echo "3. Luego ejecuta este script nuevamente:"
echo "   bash generar-hash-argon2.sh"
echo ""
echo "O genera el hash manualmente y actualiza la cuenta:"
echo "   mysql -uroot -pproyectalean -Dmetin2_account -e \"UPDATE account SET password='TU_HASH_AQUI' WHERE login='test';\""
echo ""

