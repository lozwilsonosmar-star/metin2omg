# Solución para carpeta package/

## Problema
El servidor necesita la carpeta `package/` con archivos de cifrado del cliente, pero esta carpeta no está en el VPS.

## Soluciones

### Opción 1: Copiar manualmente desde tu máquina local

Si tienes la carpeta `pack/` en tu máquina local (en `Client-20251206T130044Z-3-001/Client/Client/Client/pack`):

1. **Comprimir la carpeta en tu máquina local:**
   ```bash
   cd Client-20251206T130044Z-3-001/Client/Client/Client
   tar -czf pack.tar.gz pack/
   ```

2. **Subir al VPS usando SCP o SFTP:**
   ```bash
   scp pack.tar.gz root@72.61.12.2:/opt/metin2omg/
   ```

3. **En el VPS, extraer y copiar al contenedor:**
   ```bash
   cd /opt/metin2omg
   tar -xzf pack.tar.gz
   docker exec metin2-server mkdir -p /app/package
   docker cp pack/. metin2-server:/app/package/
   docker restart metin2-server
   ```

### Opción 2: Crear carpeta package/ vacía (temporal)

Si no tienes la carpeta pack/, puedes crear una carpeta package/ vacía para ver si el servidor puede funcionar sin ella (aunque probablemente seguirá dando errores):

```bash
docker exec metin2-server mkdir -p /app/package
docker restart metin2-server
```

### Opción 3: Usar la carpeta package/ de basesfiles (si existe)

Si la carpeta package/ existe en basesfiles pero está vacía, necesitamos obtenerla de otra fuente o generarla.

## Nota Importante

La carpeta `package/` contiene archivos de cifrado específicos del cliente que son necesarios para:
- Descifrar los paquetes del cliente después del login
- Procesar correctamente LOGIN_BY_KEY
- Evitar errores de SEQUENCE

Sin esta carpeta, el servidor no puede comunicarse correctamente con el cliente después del login exitoso.

