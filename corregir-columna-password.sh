#!/bin/bash
# Script para corregir el tamaño de la columna password en la tabla account
# Uso: bash corregir-columna-password.sh

echo "=========================================="
echo "Corrección de Columna Password"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Verificando tamaño actual de la columna password..."
echo ""

CURRENT_TYPE=$(mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null | grep password | awk '{print $2}')

echo "   Tipo actual: $CURRENT_TYPE"
echo ""

if [[ "$CURRENT_TYPE" == *"varchar(41)"* ]] || [[ "$CURRENT_TYPE" == *"varchar(40)"* ]] || [[ "$CURRENT_TYPE" == *"char(40)"* ]] || [[ "$CURRENT_TYPE" == *"char(41)"* ]]; then
    echo "   ⚠️  La columna es demasiado pequeña para hash Argon2id (necesita ~100 caracteres)"
    echo ""
    echo "2. Modificando columna password a VARCHAR(255)..."
    echo ""
    
    mysql -uroot -pproyectalean -Dmetin2_account <<EOF
ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL DEFAULT '';
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Columna modificada exitosamente"
        echo ""
        echo "3. Verificando nuevo tamaño..."
        NEW_TYPE=$(mysql -uroot -pproyectalean -Dmetin2_account -e "SHOW COLUMNS FROM account WHERE Field='password';" 2>/dev/null | grep password | awk '{print $2}')
        echo "   Nuevo tipo: $NEW_TYPE"
        echo ""
        echo "=========================================="
        echo "✅ Columna corregida"
        echo "=========================================="
        echo ""
        echo "Ahora ejecuta el script para generar y actualizar el hash:"
        echo "   bash instalar-argon2-final.sh"
        echo ""
    else
        echo "   ❌ Error al modificar la columna"
        echo ""
        echo "   Intentando método alternativo..."
        mysql -uroot -pproyectalean -Dmetin2_account <<EOF
ALTER TABLE account CHANGE password password VARCHAR(255) NOT NULL DEFAULT '';
EOF
    fi
else
    if [[ "$CURRENT_TYPE" == *"varchar(255)"* ]] || [[ "$CURRENT_TYPE" == *"varchar(200)"* ]] || [[ "$CURRENT_TYPE" == *"varchar(100)"* ]]; then
        echo "   ✅ La columna ya tiene tamaño suficiente"
        echo ""
        echo "   Puedes proceder a generar y actualizar el hash:"
        echo "   bash instalar-argon2-final.sh"
    else
        echo "   ⚠️  Tipo de columna inesperado: $CURRENT_TYPE"
        echo ""
        echo "   Modificando a VARCHAR(255) de todas formas..."
        mysql -uroot -pproyectalean -Dmetin2_account <<EOF
ALTER TABLE account MODIFY COLUMN password VARCHAR(255) NOT NULL DEFAULT '';
EOF
        if [ $? -eq 0 ]; then
            echo "   ✅ Columna modificada"
        fi
    fi
fi

echo ""

