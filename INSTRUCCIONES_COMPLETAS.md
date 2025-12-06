# 📋 Instrucciones Completas - Metin2 Server

## 🎯 Objetivo
Subir el proyecto a GitHub y desplegarlo en el VPS Ubuntu 24.04

---

## 📤 PARTE 1: Subir a GitHub

### Paso 1: Preparar el repositorio local

Abre PowerShell o Git Bash en la carpeta `metin2-server`:

```bash
cd C:\Users\USUARIO\Desktop\metingit\metin2-server
```

### Paso 2: Inicializar Git (si no está inicializado)

```bash
git init
git remote add origin https://github.com/lozwilsonosmar-star/metin2omg.git
```

### Paso 3: Agregar y subir archivos

```bash
git add .
git commit -m "Initial commit: Metin2 Server con soporte Ubuntu 24.04"
git branch -M main
git push -u origin main
```

**Nota:** Si te pide credenciales, usa tu token de GitHub o usuario/contraseña.

---

## 🖥️ PARTE 2: Desplegar en el VPS

### Paso 1: Conectar al VPS

```bash
ssh root@72.61.12.2
```

O usando el hostname:
```bash
ssh root@srv1141732.hstgr.cloud
```

### Paso 2: Ejecutar script de deployment automático

```bash
# Clonar repositorio
cd /opt
git clone https://github.com/lozwilsonosmar-star/metin2omg.git
cd metin2omg

# Dar permisos de ejecución
chmod +x deploy-vps.sh
chmod +x instalar-en-vps.sh
chmod +x start-server.sh

# Ejecutar deployment
sudo bash deploy-vps.sh
```

El script hará:
- ✅ Actualizar el sistema
- ✅ Instalar Docker, MariaDB y dependencias
- ✅ Clonar el repositorio
- ✅ Instalar Python 2.7 y dependencias
- ✅ Construir la imagen Docker
- ✅ Configurar firewall
- ⚠️ Te pedirá configurar MySQL y crear las bases de datos

---

## 🗄️ PARTE 3: Configurar Base de Datos

### Paso 1: Configurar MySQL (primera vez)

```bash
mysql_secure_installation
```

Sigue las instrucciones:
- Establece contraseña para root
- Elimina usuarios anónimos: **Y**
- Deshabilita login remoto root: **Y**
- Elimina base de datos test: **Y**
- Recarga privilegios: **Y**

### Paso 2: Crear bases de datos

```bash
mysql -u root -p
```

Dentro de MySQL, ejecuta:

```sql
CREATE DATABASE metin2_account CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE metin2_common CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE metin2_player CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE metin2_log CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'metin2'@'localhost' IDENTIFIED BY 'TU_PASSWORD_SEGURO_AQUI';
GRANT ALL PRIVILEGES ON metin2_account.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_common.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_player.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_log.* TO 'metin2'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**⚠️ IMPORTANTE:** Cambia `TU_PASSWORD_SEGURO_AQUI` por una contraseña segura y guárdala.

---

## ⚙️ PARTE 4: Configurar el Servidor

### Paso 1: Editar archivo .env

```bash
cd /opt/metin2omg
nano .env
```

Edita las siguientes líneas (especialmente las contraseñas):

```env
MYSQL_PASSWORD=TU_PASSWORD_SEGURO_AQUI  # La misma que usaste en MySQL
PUBLIC_IP=72.61.12.2                     # IP de tu VPS
GAME_HOSTNAME=Metin2OMG                  # Nombre de tu servidor
```

Guarda con `Ctrl+O`, Enter, `Ctrl+X`

---

## 🚀 PARTE 5: Iniciar el Servidor

### Opción A: Usando Docker Compose (Recomendado)

```bash
cd /opt/metin2omg
docker-compose up -d
```

### Opción B: Usando script de inicio

```bash
cd /opt/metin2omg
./start-server.sh
```

### Opción C: Manualmente

```bash
cd /opt/metin2omg
docker build -t metin2/server:latest --provenance=false .
docker run -d \
  --name metin2-server \
  --restart unless-stopped \
  -p 12345:12345 \
  -p 13200:13200 \
  -p 8888:8888 \
  --env-file .env \
  metin2/server:latest
```

---

## ✅ PARTE 6: Verificar que Funciona

### Verificar contenedores

```bash
docker ps
```

Deberías ver `metin2-server` corriendo.

### Ver logs

```bash
docker logs metin2-server
```

O en tiempo real:
```bash
docker logs -f metin2-server
```

### Verificar puertos

```bash
netstat -tulpn | grep -E '12345|13200|8888'
```

### Probar conexión

```bash
telnet localhost 12345
```

Si se conecta, el servidor está funcionando.

---

## 🔧 Comandos Útiles

### Ver estado del servidor
```bash
docker ps
docker logs metin2-server
```

### Reiniciar servidor
```bash
docker restart metin2-server
```

### Detener servidor
```bash
docker stop metin2-server
```

### Iniciar servidor
```bash
docker start metin2-server
```

### Actualizar desde GitHub
```bash
cd /opt/metin2omg
git pull origin main
docker-compose build
docker-compose up -d
```

### Ver uso de recursos
```bash
docker stats metin2-server
```

---

## 🔒 Seguridad

### Configurar Firewall

```bash
ufw allow 22/tcp    # SSH
ufw allow 12345/tcp # Puerto del juego
ufw allow 13200/tcp # Puerto P2P
ufw enable
ufw status
```

### Cambiar contraseñas por defecto

1. **MySQL root:** Ya configurado con `mysql_secure_installation`
2. **Usuario metin2:** Cambiar en `.env` y en MySQL
3. **Admin password:** Editar en `game.conf` (dentro del contenedor)

---

## 🆘 Solución de Problemas

### El servidor no inicia

```bash
# Ver logs detallados
docker logs metin2-server

# Verificar configuración
cat .env

# Verificar que MySQL está corriendo
systemctl status mariadb
```

### Error de conexión a base de datos

```bash
# Verificar que las bases de datos existen
mysql -u root -p -e "SHOW DATABASES;"

# Verificar usuario
mysql -u root -p -e "SELECT User, Host FROM mysql.user;"

# Probar conexión
mysql -u metin2 -p -h localhost
```

### Puerto ya en uso

```bash
# Ver qué está usando el puerto
netstat -tulpn | grep 12345

# Detener proceso
kill -9 <PID>
```

### Docker no inicia

```bash
# Verificar estado de Docker
systemctl status docker

# Reiniciar Docker
systemctl restart docker
```

---

## 📝 Checklist Final

Antes de considerar el deployment completo, verifica:

- [ ] Repositorio subido a GitHub
- [ ] VPS actualizado y dependencias instaladas
- [ ] Bases de datos creadas
- [ ] Usuario MySQL creado con permisos
- [ ] Archivo `.env` configurado correctamente
- [ ] Contenedor Docker corriendo
- [ ] Puertos abiertos en firewall
- [ ] Logs sin errores críticos
- [ ] Conexión al puerto 12345 funciona

---

## 📞 Información del VPS

- **IP:** 72.61.12.2
- **Hostname:** srv1141732.hstgr.cloud
- **Ubuntu:** 24.04 LTS
- **Usuario SSH:** root

---

## 🎮 Puertos del Juego

- **12345** - Puerto principal del juego (cliente se conecta aquí)
- **13200** - Puerto P2P (comunicación entre servidores)
- **8888** - Puerto DB Server (comunicación interna)

Asegúrate de que estos puertos estén abiertos en tu firewall y en el panel de control de tu proveedor de VPS.

---

## 📚 Documentación Adicional

- `README.md` - Documentación principal del proyecto
- `DEPLOYMENT.md` - Guía detallada de deployment
- `QUICK_START.md` - Inicio rápido
- `ANALISIS_UBUNTU24.md` - Análisis de compatibilidad

---

¡Listo! Tu servidor Metin2 debería estar funcionando. 🎉


