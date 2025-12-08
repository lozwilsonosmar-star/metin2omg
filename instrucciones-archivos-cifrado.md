# Instrucciones para Obtener Archivos cshybridcrypt

## Problema

El servidor necesita archivos `cshybridcrypt*` para cargar las claves de cifrado híbrido. Sin estos archivos, el cliente y el servidor no pueden sincronizar el cifrado, causando errores de SEQUENCE.

## Dónde Buscar en el Cliente

### 1. Directorio package/ del Cliente

Los archivos `cshybridcrypt*` generalmente están en:
- `Cliente/package/cshybridcrypt*`
- O en el directorio raíz del cliente

### 2. Buscar en Windows

Abre PowerShell o CMD en el directorio del cliente y ejecuta:

```cmd
dir /s cshybridcrypt*
```

O en PowerShell:
```powershell
Get-ChildItem -Path . -Filter "cshybridcrypt*" -Recurse
```

### 3. Variaciones del Nombre

Los archivos pueden tener nombres como:
- `cshybridcrypt.dat`
- `cshybridcrypt.bin`
- `cshybridcrypt_*.dat`
- `cshybridcrypt_*.bin`
- O cualquier variación que contenga "cshybridcrypt"

## Cómo Copiar al VPS

### Opción 1: Usando SCP (desde Windows con WSL o Git Bash)

```bash
scp cshybridcrypt* root@TU_VPS_IP:/tmp/
```

### Opción 2: Usando FileZilla

1. Conecta a tu VPS con FileZilla
2. Navega a `/tmp/` en el servidor
3. Arrastra los archivos `cshybridcrypt*` desde tu cliente

### Opción 3: Subir a un servicio de almacenamiento

1. Sube los archivos a Google Drive, Dropbox, etc.
2. Descárgalos en el VPS con `wget` o `curl`
3. Muévelos a `/tmp/`

## Copiar al Contenedor

Una vez que los archivos estén en el VPS:

```bash
# Copiar al contenedor
docker cp /tmp/cshybridcrypt* metin2-server:/app/package/

# Verificar que se copiaron
docker exec metin2-server ls -lh /app/package/cshybridcrypt*

# Reiniciar el servidor
docker restart metin2-server

# Esperar 15 segundos
sleep 15

# Verificar que se cargaron
docker logs metin2-server | grep -i "PackageCryptInfo\|crypt"
```

## Si No Encuentras los Archivos

### Posibilidad 1: Están dentro de los archivos .eix/.epk

Algunos servidores extraen estos archivos de los `.eix/.epk`. Busca herramientas de extracción de Metin2.

### Posibilidad 2: Se generan al ejecutar el cliente

Algunos clientes generan estos archivos la primera vez que se ejecutan. Intenta:
1. Ejecutar el cliente una vez
2. Buscar si se crearon archivos nuevos
3. Buscar en el directorio temporal de Windows

### Posibilidad 3: Versión diferente del cliente

Es posible que tu cliente no use cifrado híbrido. En ese caso:
- Verifica la versión del cliente
- Verifica si el servidor requiere una versión específica
- Consulta la documentación del servidor

## Verificación Final

Después de copiar los archivos, ejecuta:

```bash
bash verificar-archivos-cifrado.sh
```

Deberías ver:
- ✅ Archivos cshybridcrypt* encontrados: [número > 0]
- ✅ El servidor cargó los archivos correctamente

Si aún hay problemas, revisa los logs:
```bash
docker logs metin2-server | grep -i "Failed to Load\|PackageCryptInfo"
```

