# 🔍 Verificación de Conexión del Cliente

## ✅ Configuración del Cliente (serverinfo.py)

El archivo `serverinfo.py` está configurado correctamente:

```python
SERVER_IP = "72.61.12.2"
SERVER_NAME = "Metin2OMG"
PORT_1 = 12345
PORT_2 = 12345
PORT_3 = 12345
PORT_4 = 12345
PORT_MARK = 12345
```

**⚠️ IMPORTANTE:** El cliente también usa `PORT_AUTH = 11000` para autenticación, pero el servidor está en modo standalone y no necesita un servidor de autenticación separado.

## 🔧 Pasos para Verificar y Corregir

### 1. En el VPS - Ejecutar Diagnóstico

```bash
cd /opt/metin2omg
git pull origin main
chmod +x diagnosticar-conexion-cliente.sh
bash diagnosticar-conexion-cliente.sh
```

Este script verificará:
- ✅ Estado del contenedor
- ✅ Puertos escuchando
- ✅ Configuración del servidor (.env)
- ✅ Logs del servidor
- ✅ Firewall
- ✅ Conectividad de red

### 2. Verificar que el Servidor Esté Escuchando

```bash
# Verificar que el contenedor está corriendo
docker ps | grep metin2-server

# Verificar que el puerto 12345 está escuchando
ss -tuln | grep 12345

# Ver logs del servidor
docker logs --tail 50 metin2-server | grep -E "TCP listening|ERROR|CRITICAL"
```

**Debe aparecer:** `TCP listening on 0.0.0.0:12345`

### 3. Verificar Firewall

```bash
# Verificar estado del firewall
sudo ufw status

# Si el puerto 12345 no está abierto, abrirlo:
sudo ufw allow 12345/tcp
sudo ufw reload
```

### 4. Verificar Configuración del Cliente (En Windows)

Abre el archivo:
```
Client-20251206T130044Z-3-001\Client\Client\Client\Eternexus\root\serverinfo.py
```

Verifica que tenga:
```python
SERVER_IP = "72.61.12.2"
PORT_1 = 12345
```

### 5. Problemas Comunes y Soluciones

#### Problema: "No se puede conectar al servidor"

**Causas posibles:**
1. El servidor no está corriendo
   - **Solución:** `docker start metin2-server` o `docker restart metin2-server`

2. El puerto no está escuchando
   - **Solución:** Espera 30-60 segundos después de iniciar el contenedor
   - Verifica: `ss -tuln | grep 12345`

3. El firewall está bloqueando
   - **Solución:** `sudo ufw allow 12345/tcp`

4. La IP está mal configurada
   - **Solución:** Verifica `.env` tiene `PUBLIC_IP=72.61.12.2`
   - Ejecuta: `bash corregir-ip-publica.sh`

5. El cliente tiene la IP incorrecta
   - **Solución:** Verifica `serverinfo.py` en tu cliente Windows
   - Debe tener: `SERVER_IP = "72.61.12.2"`

#### Problema: "Error de autenticación"

**Causa:** El cliente intenta conectarse al puerto de autenticación (11000) que no existe.

**Solución:** El servidor está en modo standalone (`AUTH_SERVER=master`), así que esto no debería ser un problema. Si persiste, verifica que `game.conf` tenga `AUTH_SERVER: master`.

#### Problema: "Timeout al conectar"

**Causas:**
1. El servidor no está completamente iniciado
   - **Solución:** Espera 60 segundos y verifica los logs

2. Problemas de red
   - **Solución:** Verifica que puedas hacer ping al servidor desde tu máquina

## 📋 Checklist de Verificación

Antes de intentar conectar el cliente, verifica:

- [ ] Contenedor está corriendo: `docker ps | grep metin2-server`
- [ ] Puerto 12345 está escuchando: `ss -tuln | grep 12345`
- [ ] Logs muestran "TCP listening": `docker logs metin2-server | grep "TCP listening"`
- [ ] Firewall permite puerto 12345: `sudo ufw status | grep 12345`
- [ ] IP en .env es correcta: `grep PUBLIC_IP .env`
- [ ] IP en serverinfo.py es correcta: `grep SERVER_IP Client-.../serverinfo.py`
- [ ] Puerto en serverinfo.py es correcto: `grep PORT_1 Client-.../serverinfo.py`

## 🚀 Comandos Rápidos

```bash
# Diagnóstico completo
bash diagnosticar-conexion-cliente.sh

# Verificar estado del servidor
bash verificar-estado-servidor.sh

# Corregir IP pública
bash corregir-ip-publica.sh

# Reiniciar servidor
docker restart metin2-server
sleep 30
docker logs --tail 30 metin2-server
```

## 📝 Notas Importantes

1. **El cliente debe estar en Windows** - El cliente Metin2 es una aplicación Windows, no se ejecuta en Linux.

2. **serverinfo.py debe estar en el cliente** - Asegúrate de que el archivo `serverinfo.py` actualizado esté en la carpeta del cliente en tu máquina Windows.

3. **Espera a que el servidor inicie** - Después de iniciar el contenedor, espera 30-60 segundos para que el servidor esté completamente listo.

4. **Verifica los logs** - Si hay problemas, siempre revisa los logs: `docker logs -f metin2-server`

