# 🔧 Compilar Archivos del Cliente Metin2

## 📋 Información Importante

Los archivos Python en la carpeta `root/` (especialmente `serverinfo.py`) necesitan ser compilados/empaquetados para que el cliente los pueda usar correctamente.

## 🎯 Objetivo

Compilar los archivos Python de `root/` usando `EterNexus.exe` para que los cambios en `serverinfo.py` (IP y puerto del servidor) sean reconocidos por el cliente.

## 📍 Ubicación de Archivos

```
Client-20251206T130044Z-3-001/Client/Client/Client/
├── Eternexus/
│   ├── EterNexus.exe          ← Herramienta para compilar
│   └── root/
│       ├── serverinfo.py       ← ⚠️ Archivo que modificamos (IP y puerto)
│       └── [otros archivos .py]
└── pack/                       ← Archivos empaquetados (.epk)
```

## 🚀 Pasos para Compilar

### Opción 1: Usar EterNexus.exe (Recomendado)

1. **Navega a la carpeta del cliente:**
   ```
   Client-20251206T130044Z-3-001\Client\Client\Client\Eternexus\
   ```

2. **Ejecuta EterNexus.exe:**
   - Haz doble clic en `EterNexus.exe`
   - O desde la línea de comandos:
     ```
     cd Client-20251206T130044Z-3-001\Client\Client\Client\Eternexus
     EterNexus.exe
     ```

3. **Compila los archivos de root:**
   - EterNexus debería tener una opción para compilar/empaquetar los archivos
   - Busca opciones como "Pack", "Compile", "Build", o "Make Pack"
   - Selecciona la carpeta `root/` como origen
   - El resultado debería ir a la carpeta `pack/` o similar

### Opción 2: Compilar Python Manualmente

Si EterNexus no funciona o no tiene esa opción, puedes compilar los archivos Python manualmente:

1. **Abre PowerShell o CMD en la carpeta root:**
   ```
   cd Client-20251206T130044Z-3-001\Client\Client\Client\Eternexus\root
   ```

2. **Compila los archivos Python:**
   ```powershell
   # Compilar todos los archivos .py a .pyc
   python -m compileall .
   
   # O compilar solo serverinfo.py
   python -m py_compile serverinfo.py
   ```

   **Nota:** Necesitas tener Python 2.7 instalado (el cliente usa Python 2.7)

### Opción 3: Verificar si el Cliente Lee .py Directamente

Algunos clientes pueden leer archivos `.py` directamente sin necesidad de compilar. Prueba:

1. **Modifica serverinfo.py directamente:**
   - Abre: `Eternexus\root\serverinfo.py`
   - Verifica que tenga:
     ```python
     SERVER_IP = "72.61.12.2"
     PORT_1 = 12345
     ```

2. **Ejecuta el cliente:**
   - Si el cliente lee los archivos `.py` directamente, debería funcionar sin compilar

## 🔍 Verificar que Funcionó

### Método 1: Verificar Archivos Compilados

Busca archivos `.pyc` o `.pyo` en la carpeta `root/`:
```
Eternexus\root\serverinfo.pyc  ← Debería existir si se compiló
```

### Método 2: Probar el Cliente

1. **Ejecuta el cliente:**
   ```
   Metin2Distribute.exe
   ```

2. **Intenta conectarte:**
   - Usuario: `test`
   - Contraseña: `test123`

3. **Verifica la conexión:**
   - Si se conecta, la compilación funcionó
   - Si no se conecta, verifica los logs o errores

## ⚠️ Problemas Comunes

### Problema: "EterNexus.exe no inicia"

**Solución:**
1. Instala Visual C++ Redistributables:
   - `vcredist_x86.exe` (32 bits)
   - `vcredist_x64.exe` (64 bits)
2. Ejecuta como administrador

### Problema: "No encuentro la opción para compilar"

**Solución:**
- EterNexus puede tener una interfaz diferente
- Busca en el menú: "File" → "Pack" o "Build"
- O busca archivos de configuración/scripts que indiquen cómo usarlo

### Problema: "Python no está instalado"

**Solución:**
- El cliente incluye `python27.dll`, pero puede necesitar Python 2.7 instalado para compilar
- Descarga Python 2.7 desde python.org (versión antigua)

### Problema: "El cliente sigue sin conectarse después de compilar"

**Solución:**
1. Verifica que `serverinfo.py` tenga la IP correcta: `72.61.12.2`
2. Verifica que el servidor esté corriendo: `docker ps | grep metin2-server`
3. Verifica que el puerto esté abierto: `ss -tuln | grep 12345`
4. Verifica el firewall: `sudo ufw status | grep 12345`

## 📝 Notas Importantes

1. **Backup antes de compilar:**
   - Haz una copia de seguridad de la carpeta `root/` antes de compilar
   - Por si algo sale mal

2. **Orden de operaciones:**
   - Primero modifica `serverinfo.py` con la IP y puerto correctos
   - Luego compila los archivos
   - Finalmente ejecuta el cliente

3. **Archivos que deben compilarse:**
   - `serverinfo.py` (más importante - configuración del servidor)
   - Otros archivos `.py` en `root/` si los modificaste

4. **Formato de archivos compilados:**
   - `.pyc` = Python Compiled (bytecode)
   - `.pyo` = Python Optimized (bytecode optimizado)
   - `.epk` = EterPack (formato empaquetado de Metin2)

## 🎯 Resumen Rápido

1. **Modifica serverinfo.py:**
   ```python
   SERVER_IP = "72.61.12.2"
   PORT_1 = 12345
   ```

2. **Compila con EterNexus:**
   - Ejecuta `EterNexus.exe`
   - Compila/empaqueta los archivos de `root/`

3. **Prueba el cliente:**
   - Ejecuta `Metin2Distribute.exe`
   - Intenta conectarte

## 🔗 Referencias

- Carpeta del cliente: `Client-20251206T130044Z-3-001/Client/Client/Client/`
- EterNexus: `Eternexus/EterNexus.exe`
- Archivo de configuración: `Eternexus/root/serverinfo.py`
- Archivos compilados: `Eternexus/root/*.pyc` o `pack/*.epk`

