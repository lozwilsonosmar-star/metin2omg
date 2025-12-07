#!/bin/bash
# Script simple para resolver conflicto de git

cd /opt/metin2omg 2>/dev/null || {
    echo "❌ No se encontró el directorio"
    exit 1
}

echo "Resolviendo conflicto de git..."
echo ""

# Guardar cambios locales
git stash

# Actualizar desde remoto
git pull origin main

echo ""
echo "✅ Git actualizado correctamente"
echo ""
echo "Ahora puedes ejecutar:"
echo "  bash resolver-conflicto-y-verificar.sh"

