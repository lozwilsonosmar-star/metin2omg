# Checklist: Preparación para Conexión del Cliente Metin2

## ✅ Lo que YA está hecho:

1. ✅ Base de datos configurada (4 bases de datos creadas)
2. ✅ Tablas creadas (todas las tablas necesarias)
3. ✅ Datos importados (skill_proto, refine_proto, shop, etc.)
4. ✅ Scripts de actualización automatizados
5. ✅ Docker configurado
6. ✅ Archivos de configuración del servidor (game.conf, db.conf)

---

## ⚠️ Lo que FALTA para conectar el cliente:

### 1. 🔥 **FIREWALL - Puertos Abiertos** ⚠️ CRÍTICO

Los puertos del juego deben estar abiertos en el firewall del VPS:

```bash
# En el VPS, ejecutar:
sudo ufw allow 22/tcp    # SSH (ya debería estar abierto)
sudo ufw allow 12345/tcp # Puerto del juego (CLIENTE SE CONECTA AQUÍ)
sudo ufw allow 13200/tcp # Puerto P2P
sudo ufw allow 8888/tcp  # Puerto DB Server
sudo ufw status          # Verificar que están abiertos
```

**⚠️ SIN ESTO, EL CLIENTE NO PODRÁ CONECTARSE**

---

### 2. 📝 **Archivo .env - Configuración Correcta** ⚠️ CRÍTICO

Verificar que el archivo `.env` en el VPS tenga la **IP PÚBLICA CORRECTA**:

```bash
# En el VPS:
cd /opt/metin2omg
cat .env | grep PUBLIC_IP
```

Debe mostrar: `PUBLIC_IP=72.61.12.2` (tu IP pública del VPS)

Si está mal, editar:
```bash
nano .env
# Cambiar PUBLIC_IP a tu IP pública real
```

---

### 3. 🎮 **Configuración del Cliente Metin2** ⚠️ CRÍTICO

El cliente Metin2 necesita saber la IP y puerto del servidor. Esto se configura en:

**Opción A: Archivo `serverlist.txt` en el cliente**
```
Metin2OMG	72.61.12.2	12345
```

**Opción B: Modificar el ejecutable del cliente** (más complejo, requiere herramientas)

**Opción C: Usar un launcher personalizado** que configure la IP automáticamente

**📋 Necesitas:**
- IP del servidor: `72.61.12.2`
- Puerto del juego: `12345`

---

### 4. 🔧 **AUTH_SERVER - Configuración Correcta** ⚠️ IMPORTANTE

En los logs anteriores viste:
```
AUTH_SERVER: syntax error: <ip|master> <port>
```

Esto indica que `AUTH_SERVER` en `game.conf` está mal configurado.

**Verificar en `.env`:**
```bash
cat .env | grep AUTH_SERVER
```

**Debe ser:**
- `GAME_AUTH_SERVER=localhost` (si el servidor de autenticación está en el mismo servidor)
- O `GAME_AUTH_SERVER=IP_DEL_AUTH_SERVER PUERTO` (si está en otro servidor)

**Si solo tienes un servidor de juego (no separado), usar:**
```env
GAME_AUTH_SERVER=localhost
```

---

### 5. 📊 **Verificar que el Servidor Inicia Correctamente** ⚠️ IMPORTANTE

Después de ejecutar `actualizar-vps.sh`, verificar los logs:

```bash
docker logs -f metin2-server
```

**Buscar errores críticos:**
- ❌ `Table 'metin2_player.XXX' doesn't exist` → Falta tabla
- ❌ `AUTH_SERVER: syntax error` → Configuración incorrecta
- ❌ `SKILL_PERCENT] locale table has not enough skill information` → Datos faltantes
- ❌ `InitializeShopTable : Table count is zero` → Tiendas vacías
- ✅ `TCP listening on 0.0.0.0:12345` → **¡Servidor escuchando correctamente!**

---

### 6. 📁 **Archivos del Juego en el Contenedor** ⚠️ IMPORTANTE

Verificar que los archivos `.txt` estén en el contenedor:

```bash
docker exec metin2-server ls -la /app/gamefiles/conf/*.txt
```

**Deben existir:**
- `item_proto.txt` ✅
- `mob_proto.txt` ✅

Si faltan, el servidor no podrá cargar items y monstruos.

---

### 7. 🔐 **Crear Cuenta de Prueba** ⚠️ IMPORTANTE

Antes de conectar el cliente, necesitas crear una cuenta:

```bash
# En el VPS, conectarse a MySQL:
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

### 8. 🌐 **Verificar Conectividad desde Fuera** ⚠️ RECOMENDADO

Desde tu máquina local, verificar que los puertos están abiertos:

```bash
# En Windows PowerShell:
Test-NetConnection -ComputerName 72.61.12.2 -Port 12345
```

O usar herramientas online como: https://www.yougetsignal.com/tools/open-ports/

---

## 📋 Checklist de Verificación Final

Antes de intentar conectar el cliente, verifica:

- [ ] Firewall: Puertos 12345, 13200, 8888 abiertos
- [ ] `.env`: `PUBLIC_IP=72.61.12.2` (tu IP real)
- [ ] `.env`: `GAME_AUTH_SERVER=localhost` (o IP correcta)
- [ ] Servidor inicia sin errores críticos: `docker logs metin2-server`
- [ ] Logs muestran: `TCP listening on 0.0.0.0:12345`
- [ ] Archivos `.txt` presentes: `docker exec metin2-server ls /app/gamefiles/conf/*.txt`
- [ ] Cuenta de prueba creada en `metin2_account.account`
- [ ] Cliente configurado con IP `72.61.12.2` y puerto `12345`
- [ ] Puerto 12345 accesible desde internet (verificado con herramienta online)

---

## 🚀 Pasos Finales en el VPS

```bash
# 1. Verificar firewall
sudo ufw status

# 2. Abrir puertos si no están abiertos
sudo ufw allow 12345/tcp
sudo ufw allow 13200/tcp
sudo ufw allow 8888/tcp

# 3. Verificar configuración
cd /opt/metin2omg
cat .env | grep -E "PUBLIC_IP|AUTH_SERVER|GAME_PORT"

# 4. Ver logs del servidor
docker logs -f metin2-server

# 5. Crear cuenta de prueba
mysql -h127.0.0.1 -P3306 -umetin2 -p metin2_account
# INSERT INTO account (login, password, social_id, status) VALUES ('test', SHA1('test123'), 'A', 'OK');
```

---

## 🎯 Resumen: Lo Más Crítico

1. **🔥 FIREWALL** - Sin puertos abiertos, nada funcionará
2. **📝 IP PÚBLICA** - Debe ser la IP real del VPS
3. **🎮 CLIENTE** - Debe estar configurado con la IP y puerto correctos
4. **✅ SERVIDOR INICIANDO** - Sin errores críticos en los logs

---

## 📞 Si el Cliente No Se Conecta

1. **Verificar logs del servidor:**
   ```bash
   docker logs metin2-server | tail -50
   ```

2. **Verificar que el servidor está escuchando:**
   ```bash
   docker exec metin2-server netstat -tlnp | grep 12345
   ```

3. **Verificar firewall:**
   ```bash
   sudo ufw status verbose
   ```

4. **Probar conectividad desde fuera:**
   - Usar herramienta online para verificar puerto 12345
   - O desde otra máquina: `telnet 72.61.12.2 12345`

5. **Verificar configuración del cliente:**
   - IP debe ser: `72.61.12.2`
   - Puerto debe ser: `12345`

---

¡Con estos pasos, el cliente debería poder conectarse! 🎮

