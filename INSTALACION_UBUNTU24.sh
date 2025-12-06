#!/bin/bash
# Script de instalación para Metin2 Server en Ubuntu 24.04
# Este script resuelve el problema de Python 2 y configura las dependencias

set -e  # Salir si hay algún error

echo "=========================================="
echo "Instalación de Metin2 Server en Ubuntu 24.04"
echo "=========================================="
echo ""

# Verificar que estamos en Ubuntu 24.04
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$VERSION_ID" != "24.04" ]; then
        echo "⚠️  ADVERTENCIA: Este script está diseñado para Ubuntu 24.04"
        echo "   Versión detectada: $VERSION_ID"
        read -p "¿Continuar de todos modos? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            exit 1
        fi
    fi
fi

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Por favor ejecuta este script con sudo:"
    echo "   sudo bash INSTALACION_UBUNTU24.sh"
    exit 1
fi

echo "📦 Paso 1: Actualizando lista de paquetes..."
apt-get update

echo ""
echo "📦 Paso 2: Instalando dependencias del sistema..."
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
    software-properties-common

echo ""
echo "🐍 Paso 3: Instalando Python 2.7 desde deadsnakes PPA..."
# Agregar PPA de deadsnakes para Python 2.7
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python2.7

# Crear symlink para python2 si no existe
if [ ! -f /usr/bin/python2 ]; then
    ln -s /usr/bin/python2.7 /usr/bin/python2
    echo "✅ Symlink python2 creado"
fi

echo ""
echo "📚 Paso 4: Instalando vcpkg..."
if [ ! -d "vcpkg" ]; then
    git clone https://github.com/Microsoft/vcpkg.git
    cd vcpkg
    ./bootstrap-vcpkg.sh
    cd ..
    echo "✅ vcpkg instalado"
else
    echo "✅ vcpkg ya existe, omitiendo..."
fi

echo ""
echo "📦 Paso 5: Instalando librerías requeridas con vcpkg..."
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
echo "✅ Instalación de dependencias completada!"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Compilar el proyecto:"
echo "      mkdir build"
echo "      cd build"
echo "      cmake -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake .."
echo "      make -j \$(nproc)"
echo ""
echo "   2. Configurar la base de datos MySQL/MariaDB"
echo "   3. Configurar db.conf y game.conf"
echo ""
echo "=========================================="
echo "Instalación completada exitosamente!"
echo "=========================================="

