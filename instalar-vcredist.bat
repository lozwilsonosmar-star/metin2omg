@echo off
REM Script para instalar Visual C++ Redistributables necesarios para EterNexus
REM Uso: Ejecutar como Administrador

echo ==========================================
echo Instalacion de Visual C++ Redistributables
echo ==========================================
echo.
echo Este script instalara los Visual C++ Redistributables
echo necesarios para ejecutar EterNexus.exe
echo.
echo IMPORTANTE: Ejecuta este script como Administrador
echo.

REM Verificar si se ejecuta como administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Este script debe ejecutarse como Administrador
    echo.
    echo Clic derecho en el archivo y selecciona "Ejecutar como administrador"
    pause
    exit /b 1
)

REM Cambiar a la carpeta del cliente
cd /d "%~dp0Client-20251206T130044Z-3-001\Client\Client\Client\Eternexus"

if not exist "vcredist_x86.exe" (
    echo ERROR: No se encontro vcredist_x86.exe
    echo Ruta esperada: Eternexus\vcredist_x86.exe
    pause
    exit /b 1
)

echo 1. Instalando Visual C++ Redistributable (x86)...
echo.
if exist "vcredist_x86.exe" (
    echo    Ejecutando vcredist_x86.exe...
    start /wait "" "vcredist_x86.exe" /quiet /norestart
    if %ERRORLEVEL% EQU 0 (
        echo    Instalacion x86 completada
    ) else (
        echo    ADVERTENCIA: La instalacion x86 puede haber fallado
        echo    Codigo de error: %ERRORLEVEL%
    )
) else (
    echo    ERROR: vcredist_x86.exe no encontrado
)

echo.
echo 2. Instalando Visual C++ Redistributable (x64)...
echo.
if exist "vcredist_x64.exe" (
    echo    Ejecutando vcredist_x64.exe...
    start /wait "" "vcredist_x64.exe" /quiet /norestart
    if %ERRORLEVEL% EQU 0 (
        echo    Instalacion x64 completada
    ) else (
        echo    ADVERTENCIA: La instalacion x64 puede haber fallado
        echo    Codigo de error: %ERRORLEVEL%
        echo    (Esto es normal si tienes Windows 32 bits)
    )
) else (
    echo    ERROR: vcredist_x64.exe no encontrado
)

echo.
echo ==========================================
echo Instalacion completada
echo ==========================================
echo.
echo NOTA: Si los instaladores se ejecutaron en modo silencioso,
echo       es posible que no veas ventanas. Esto es normal.
echo.
echo Siguiente paso:
echo   1. Reinicia el equipo (recomendado)
echo   2. Vuelve a intentar ejecutar EterNexus.exe
echo.
echo Si el problema persiste:
echo   - Descarga los Redistributables desde Microsoft
echo   - Ejecuta los instaladores manualmente
echo   - Verifica que msvcr100.dll este en C:\Windows\System32
echo.
pause

