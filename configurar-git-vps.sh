#!/bin/bash
# Script para configurar git en el VPS y evitar conflictos

echo "=========================================="
echo "Configurar Git en el VPS"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Configurando git para evitar conflictos de line endings..."
git config core.autocrlf false
git config core.eol lf

echo "2. Configurando estrategia de merge por defecto..."
git config pull.rebase false

echo "3. Configurando para ignorar cambios de permisos en scripts..."
git config core.fileMode false

echo ""
echo "✅ Configuración completada:"
echo "   - core.autocrlf: false"
echo "   - core.eol: lf"
echo "   - pull.rebase: false"
echo "   - core.fileMode: false"
echo ""
echo "Esto evitará la mayoría de conflictos futuros."
echo ""
echo "Si quieres aplicar esto globalmente (para todos los repos):"
echo "   git config --global core.autocrlf false"
echo "   git config --global core.eol lf"
echo "   git config --global pull.rebase false"
echo "   git config --global core.fileMode false"

