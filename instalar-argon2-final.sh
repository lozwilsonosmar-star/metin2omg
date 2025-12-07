#!/bin/bash
# Script final para instalar argon2-cffi y generar hash
# Uso: bash instalar-argon2-final.sh

echo "=========================================="
echo "Instalación Final de Argon2"
echo "=========================================="
echo ""

cd /opt/metin2omg

TEST_USER="test"
TEST_PASSWORD="metin2test123"

# Instalar argon2-cffi con --break-system-packages si es necesario
echo "1. Instalando argon2-cffi..."
echo ""

# Intentar con --user primero
if python3 -m pip install --user argon2-cffi 2>&1 | grep -q "error\|Error\|ERROR"; then
    echo "   ⚠️  --user falló, intentando con --break-system-packages..."
    sudo python3 -m pip install --break-system-packages argon2-cffi 2>&1 | tail -5
else
    echo "   ✅ argon2-cffi instalado con --user"
fi

# Verificar instalación
if python3 -c "import argon2" 2>/dev/null; then
    echo "   ✅ argon2-cffi verificado"
else
    echo "   ⚠️  Verificación falló, intentando método alternativo..."
    
    # Intentar instalar con sudo y --break-system-packages
    sudo python3 -m pip install --break-system-packages argon2-cffi 2>&1 | tail -5
    
    # Verificar nuevamente
    if ! python3 -c "import argon2" 2>/dev/null; then
        echo "   ❌ No se pudo instalar argon2-cffi"
        echo ""
        echo "   Intentando instalar libffi-dev primero..."
        sudo apt-get install -y libffi-dev 2>&1 | tail -3
        sudo python3 -m pip install --break-system-packages argon2-cffi 2>&1 | tail -5
    fi
fi

echo ""

# Generar hash
echo "2. Generando hash Argon2id para: $TEST_PASSWORD"
echo ""

ARGON2_HASH=$(python3 <<PYTHON
try:
    import sys
    sys.path.insert(0, '/root/.local/lib/python3.12/site-packages')
    from argon2 import PasswordHasher
    ph = PasswordHasher()
    hash = ph.hash('$TEST_PASSWORD')
    print(hash)
except ImportError:
    try:
        from argon2 import PasswordHasher
        ph = PasswordHasher()
        hash = ph.hash('$TEST_PASSWORD')
        print(hash)
    except Exception as e:
        print("")
        import sys
        sys.stderr.write(f"Error: {e}\n")
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
    
    # Actualizar cuenta
    echo "3. Actualizando cuenta '$TEST_USER'..."
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
UPDATE account SET password='$ARGON2_HASH', status='OK', last_play=NOW() WHERE login='$TEST_USER';
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Cuenta actualizada exitosamente"
        echo ""
        echo "4. Verificando cuenta..."
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
    echo "Ejecuta estos comandos uno por uno:"
    echo ""
    echo "sudo python3 -m pip install --break-system-packages argon2-cffi"
    echo ""
    echo "python3 -c \"from argon2 import PasswordHasher; ph = PasswordHasher(); print(ph.hash('$TEST_PASSWORD'))\""
    echo ""
    echo "Luego copia el hash y ejecuta:"
    echo "mysql -uroot -pproyectalean -Dmetin2_account -e \"UPDATE account SET password='HASH_AQUI' WHERE login='test';\""
    echo ""
fi

