# Pasos Finales - Configurar Cliente para Conectar al Juego

## ✅ Lo que YA está hecho:

1. ✅ Base de datos configurada
2. ✅ Tablas creadas
3. ✅ Datos importados
4. ✅ Firewall configurado (puertos abiertos)
5. ✅ Servidor compilándose (en progreso)

---

## 📋 Lo que FALTA después de que termine la compilación:

### 1. ✅ Verificar que el servidor inició correctamente

```bash
# Verificar que el contenedor está corriendo
docker ps | grep metin2-server

# Verificar que los puertos están escuchando
ss -tuln | grep -E '12345|13200|8888'

# Ver logs del servidor
docker logs -f metin2-server
```

**Buscar en los logs:**
- ✅ `TCP listening on 0.0.0.0:12345` → **¡Servidor listo!**
- ❌ `Table 'XXX' doesn't exist` → Falta tabla
- ❌ `AUTH_SERVER: syntax error` → Error de configuración
- ❌ `SKILL_PERCENT] locale table has not enough skill information` → Datos faltantes

---

### 2. 🔐 Crear cuenta de prueba

**IMPORTANTE:** Necesitas crear una cuenta antes de poder conectarte.

```bash
# Conectarse a MySQL
mysql -h127.0.0.1 -P3306 -umetin2 -p

# Dentro de MySQL:
USE metin2_account;
INSERT INTO account (login, password, social_id, status) VALUES ('test', SHA1('test123'), 'A', 'OK');
SELECT * FROM account WHERE login='test';
EXIT;
```

**Credenciales de prueba:**
- Usuario: `test`
- Contraseña: `test123`

---

### 3. 🎮 Configurar el Cliente Metin2

El cliente necesita saber la IP y puerto del servidor. Hay varias formas:

#### Opción A: Archivo `serverlist.txt` (Más fácil)

Crear o editar el archivo `serverlist.txt` en la carpeta del cliente:

```
Metin2OMG	72.61.12.2	12345
```

**Ubicación del archivo:**
- Windows: `C:\Program Files\Metin2\serverlist.txt` (o donde tengas instalado el cliente)
- O en la carpeta `system` del cliente

#### Opción B: Modificar el ejecutable (Requiere herramientas)

Usar herramientas como:
- **Hex Editor** (HxD, etc.)
- Buscar la IP antigua y reemplazarla por `72.61.12.2`
- Buscar el puerto y cambiarlo a `12345`

#### Opción C: Usar un Launcher personalizado

Crear un launcher que configure la IP automáticamente.

---

### 4. 🌐 Verificar conectividad desde fuera

Antes de intentar conectar el cliente, verifica que los puertos son accesibles:

**Desde tu máquina local (Windows PowerShell):**
```powershell
Test-NetConnection -ComputerName 72.61.12.2 -Port 12345
```

**O usar herramienta online:**
- https://www.yougetsignal.com/tools/open-ports/
- IP: `72.61.12.2`
- Puerto: `12345`

**Debe mostrar:** `Port 12345 is open`

---

### 5. 🔧 Verificar configuración del servidor

Asegúrate de que el archivo `.env` tenga la IP pública correcta:

```bash
cd /opt/metin2omg
cat .env | grep PUBLIC_IP
```

**Debe mostrar:** `PUBLIC_IP=72.61.12.2`

Si está mal, editar:
```bash
nano .env
# Cambiar PUBLIC_IP a 72.61.12.2
# Guardar (Ctrl+O, Enter, Ctrl+X)
# Reiniciar contenedor: docker restart metin2-server
```

---

### 6. ✅ Checklist final antes de conectar

Antes de intentar conectar el cliente, verifica:

- [ ] Servidor está corriendo: `docker ps | grep metin2-server`
- [ ] Puerto 12345 está escuchando: `ss -tuln | grep 12345`
- [ ] Logs muestran: `TCP listening on 0.0.0.0:12345`
- [ ] Cuenta de prueba creada: `test` / `test123`
- [ ] IP pública correcta en `.env`: `72.61.12.2`
- [ ] Firewall permite puerto 12345: `sudo ufw status | grep 12345`
- [ ] Puerto 12345 accesible desde internet (verificado con herramienta online)

---

## 🎮 Configuración del Cliente - Detalles

### Archivo serverlist.txt

Formato:
```
[Nombre del Servidor]	[IP]	[Puerto]
```

Ejemplo:
```
Metin2OMG	72.61.12.2	12345
```

**Ubicaciones comunes:**
- `serverlist.txt` en la carpeta raíz del cliente
- `system/serverlist.txt`
- `serverlist.txt` en la carpeta `system/`

### Si el cliente no tiene serverlist.txt

Algunos clientes tienen la IP hardcodeada en el ejecutable. En ese caso necesitas:

1. **Usar un launcher personalizado** (recomendado)
2. **Modificar el ejecutable con hex editor** (más complejo)
3. **Usar un cliente que soporte serverlist.txt**

---

## 🚀 Script de Verificación Final

He creado un script que verifica todo automáticamente:

```bash
cd /opt/metin2omg
git pull origin main
chmod +x docker/verificar-conexion-cliente.sh
bash docker/verificar-conexion-cliente.sh
```

Este script verifica:
- ✅ Firewall
- ✅ Configuración (.env)
- ✅ Contenedor corriendo
- ✅ Puertos escuchando
- ✅ Logs del servidor
- ✅ Archivos del juego
- ✅ Cuenta de prueba

---

## 📋 Resumen: Pasos Restantes

1. **Esperar a que termine la compilación** (10-20 min más)
2. **Verificar que el servidor inició** (`docker logs metin2-server`)
3. **Crear cuenta de prueba** (MySQL)
4. **Configurar cliente** (serverlist.txt o launcher)
5. **Verificar conectividad** (herramienta online)
6. **Intentar conectar** desde el cliente

---

## ⚠️ Problemas Comunes

### El cliente no se conecta

1. **Verificar que el servidor está escuchando:**
   ```bash
   ss -tuln | grep 12345
   ```

2. **Verificar logs del servidor:**
   ```bash
   docker logs metin2-server | tail -50
   ```

3. **Verificar firewall:**
   ```bash
   sudo ufw status | grep 12345
   ```

4. **Verificar desde fuera:**
   - Usar herramienta online para verificar puerto 12345

### Error "Cannot connect to server"

- Verifica que la IP en el cliente sea: `72.61.12.2`
- Verifica que el puerto sea: `12345`
- Verifica que el firewall permita conexiones desde tu IP

### Error "Account not found"

- Verifica que creaste la cuenta en `metin2_account.account`
- Usa el usuario y contraseña correctos: `test` / `test123`

---

## 🎯 Orden de Ejecución Recomendado

```bash
# 1. Esperar a que termine la compilación
# (El script setup-completo-vps.sh lo hará automáticamente)

# 2. Verificar que todo está bien
cd /opt/metin2omg
bash docker/verificar-conexion-cliente.sh

# 3. Si falta algo, corregirlo según las indicaciones

# 4. Crear cuenta de prueba
mysql -h127.0.0.1 -P3306 -umetin2 -p metin2_account
# INSERT INTO account (login, password, social_id, status) VALUES ('test', SHA1('test123'), 'A', 'OK');

# 5. Configurar cliente con IP: 72.61.12.2 y Puerto: 12345

# 6. Intentar conectar
```

---

¡Con estos pasos deberías poder conectarte al juego! 🎮

