@echo off
REM Script para compilar archivos del cliente Metin2 en Windows
REM Uso: Ejecutar desde la carpeta del cliente

echo ==========================================
echo Compilacion de Archivos del Cliente
echo ==========================================
echo.

REM Cambiar a la carpeta del cliente
cd /d "%~dp0Client-20251206T130044Z-3-001\Client\Client\Client"

if not exist "Eternexus\EterNexus.exe" (
    echo ERROR: No se encontro EterNexus.exe
    echo Ruta esperada: Eternexus\EterNexus.exe
    pause
    exit /b 1
)

echo 1. Verificando serverinfo.py...
if exist "Eternexus\root\serverinfo.py" (
    echo    Archivo encontrado: Eternexus\root\serverinfo.py
    echo.
    echo    Configuracion actual:
    findstr /C:"SERVER_IP" /C:"PORT_1" "Eternexus\root\serverinfo.py"
    echo.
) else (
    echo    ERROR: No se encontro serverinfo.py
    pause
    exit /b 1
)

echo 2. Verificando Python 2.7...
where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    python --version
    echo    Python encontrado
) else (
    echo    ADVERTENCIA: Python no encontrado en PATH
    echo    El cliente puede usar python27.dll incluido
)

echo.
echo 3. Opciones de compilacion:
echo.
echo    A) Compilar con Python (si esta instalado)
echo    B) Usar EterNexus.exe manualmente
echo    C) Solo verificar configuracion
echo.
set /p opcion="Selecciona una opcion (A/B/C): "

if /i "%opcion%"=="A" (
    echo.
    echo Compilando archivos Python...
    cd Eternexus\root
    python -m compileall . 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo    Archivos compilados exitosamente
    ) else (
        echo    ERROR: No se pudo compilar. Verifica que Python 2.7 este instalado
    )
    cd ..\..
) else if /i "%opcion%"=="B" (
    echo.
    echo Abriendo EterNexus.exe...
    echo Por favor, compila los archivos manualmente desde EterNexus
    start "" "Eternexus\EterNexus.exe"
) else if /i "%opcion%"=="C" (
    echo.
    echo Verificando configuracion...
    findstr /C:"72.61.12.2" /C:"12345" "Eternexus\root\serverinfo.py" >nul
    if %ERRORLEVEL% EQU 0 (
        echo    Configuracion correcta encontrada
    ) else (
        echo    ADVERTENCIA: La configuracion puede no estar correcta
        echo    Verifica que serverinfo.py tenga:
        echo      SERVER_IP = "72.61.12.2"
        echo      PORT_1 = 12345
    )
) else (
    echo Opcion invalida
)

echo.
echo ==========================================
echo Proceso completado
echo ==========================================
echo.
echo NOTA: Si el cliente no se conecta, verifica:
echo   1. Que el servidor este corriendo en el VPS
echo   2. Que el puerto 12345 este abierto
echo   3. Que serverinfo.py tenga la IP correcta
echo.
pause

