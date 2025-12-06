#!/bin/bash
# Script para instalar Metin2 Server directamente en VPS Ubuntu 24.04
# Ejecutar en el VPS: sudo bash instalar-en-vps.sh

set -e

echo "=========================================="
echo "Instalación de Metin2 Server en VPS Ubuntu 24.04"
echo "=========================================="
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Por favor ejecuta con sudo:"
    echo "   sudo bash instalar-en-vps.sh"
    exit 1
fi

echo "📦 Instalando Python 2.7 (requerido para compilar quests)..."
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python2.7

# Crear symlink para python2
if [ ! -f /usr/bin/python2 ]; then
    ln -s /usr/bin/python2.7 /usr/bin/python2
    echo "✅ Python 2.7 instalado y configurado"
fi

echo ""
echo "📦 Instalando dependencias del sistema..."
apt-get install -y \
    git \
    cmake \
    ninja-build \
    build-essential \
    tar \
    curl \
    zip \
    unzip \
    pkg-config \
    autoconf \
    python3 \
    libncurses5-dev \
    libdevil-dev \
    libbsd-dev \
    gettext

echo ""
echo "📚 Instalando vcpkg..."
if [ ! -d "vcpkg" ]; then
    git clone https://github.com/Microsoft/vcpkg.git
    cd vcpkg
    ./bootstrap-vcpkg.sh
    cd ..
    echo "✅ vcpkg instalado"
else
    echo "✅ vcpkg ya existe"
fi

echo ""
echo "📦 Instalando librerías con vcpkg (esto puede tardar varios minutos)..."
cd vcpkg
./vcpkg install \
    cryptopp \
    effolkronium-random \
    libmariadb \
    libevent \
    lzo \
    fmt \
    spdlog \
    argon2
cd ..

echo ""
echo "✅ ¡Todas las dependencias están instaladas!"
echo ""
echo "📝 Ahora puedes compilar el servidor:"
echo "   mkdir build"
echo "   cd build"
echo "   cmake -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake .."
echo "   make -j \$(nproc)"
echo ""
echo "=========================================="

