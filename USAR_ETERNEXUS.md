# 🎯 Cómo Usar EterNexus para Compilar Archivos

## ✅ EterNexus ya está abierto

Ahora necesitas empaquetar los archivos de `root/` para que el cliente use la configuración actualizada.

## 📋 Pasos para Empaquetar root/

### Opción 1: Usar el Script de Configuración

1. **En EterNexus, busca la opción para cargar un script:**
   - Menú: `File` → `Open Script` o `Load Script`
   - O busca un botón que diga "Script" o "Pack"

2. **Carga el script de configuración:**
   - Navega a: `Eternexus\root\makepackscript_onlyrootnopython.txt`
   - O busca archivos `.txt` en la carpeta `root/` que contengan "pack" o "script"

3. **Ejecuta el empaquetado:**
   - Busca un botón "Pack", "Build", "Make Pack", o "Execute"
   - El resultado debería crear/actualizar `pack/root.epk`

### Opción 2: Empaquetado Manual

1. **Selecciona la carpeta root:**
   - En EterNexus, busca una opción para seleccionar carpeta origen
   - Selecciona: `Eternexus\root\`

2. **Selecciona carpeta destino:**
   - Debe ser: `pack\` (en la carpeta principal del cliente)
   - O deja la configuración por defecto

3. **Inicia el empaquetado:**
   - Busca botones como "Pack", "Build", "Make", "Compile"
   - Espera a que termine el proceso

### Opción 3: Interfaz de EterNexus

EterNexus puede tener diferentes interfaces. Busca:

- **Pestaña "Pack" o "Build"**
- **Menú "Tools" → "Pack"**
- **Botón "Make Pack" o "Build Pack"**
- **Lista de archivos con checkbox** - marca los que quieres empaquetar

## 🔍 Verificar que Funcionó

Después de empaquetar, verifica:

1. **Busca el archivo `root.epk`:**
   ```
   Client-20251206T130044Z-3-001\Client\Client\Client\pack\root.epk
   ```

2. **Verifica la fecha de modificación:**
   - El archivo `root.epk` debería tener una fecha reciente
   - Esto confirma que se actualizó con los cambios

3. **Tamaño del archivo:**
   - `root.epk` debería tener un tamaño razonable (varios KB o MB)
   - Si es muy pequeño (menos de 1 KB), puede que no se haya empaquetado correctamente

## ⚠️ Si No Encuentras la Opción

Si EterNexus tiene una interfaz diferente:

1. **Explora los menús:**
   - `File` → Busca opciones relacionadas con "Pack", "Build", "Compile"
   - `Tools` → Busca herramientas de empaquetado
   - `Options` → Puede haber configuraciones de empaquetado

2. **Busca archivos de ayuda:**
   - `Readme.txt` en la carpeta Eternexus
   - Archivos `.txt` en `root/` que puedan tener instrucciones

3. **Verifica si hay un modo de línea de comandos:**
   - Abre CMD o PowerShell en la carpeta Eternexus
   - Prueba: `EterNexus.exe --help` o `EterNexus.exe /?`

## 📝 Nota Importante

**Antes de empaquetar, verifica que `serverinfo.py` tenga la configuración correcta:**

```python
SERVER_IP = "72.61.12.2"
PORT_1 = 12345
```

Si no está correcto, edítalo antes de empaquetar.

## 🎯 Resumen

1. ✅ EterNexus está abierto
2. ⏳ Carga el script o selecciona la carpeta `root/`
3. ⏳ Ejecuta el empaquetado
4. ✅ Verifica que `pack/root.epk` se haya actualizado
5. ✅ Prueba el cliente

## 🚀 Después de Empaquetar

Una vez que `root.epk` esté actualizado:

1. **Ejecuta el cliente:**
   ```
   Metin2Distribute.exe
   ```

2. **Intenta conectarte:**
   - Usuario: `test`
   - Contraseña: `test123`

3. **Si no se conecta:**
   - Verifica que el servidor esté corriendo en el VPS
   - Verifica que el puerto 12345 esté abierto
   - Revisa los logs del servidor

