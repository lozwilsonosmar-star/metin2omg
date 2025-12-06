# Guía de Deployment - Metin2 Server

## 📋 Información del VPS

- **Ubuntu 24.04 LTS**
- **Host:** srv1141732.hstgr.cloud
- **IP:** 72.61.12.2
- **Usuario SSH:** root

---

## 🚀 Paso 1: Subir al Repositorio GitHub

### Opción A: Si ya tienes el repositorio clonado localmente

```bash
# 1. Agregar el repositorio remoto (si no está agregado)
git remote add origin https://github.com/lozwilsonosmar-star/metin2omg.git

# 2. Verificar el remoto
git remote -v

# 3. Agregar todos los archivos
git add .

# 4. Hacer commit
git commit -m "Initial commit: Metin2 Server con soporte Ubuntu 24.04"

# 5. Subir al repositorio
git push -u origin main
```

### Opción B: Si el repositorio está vacío o es nuevo

```bash
# 1. Inicializar git (si no está inicializado)
git init

# 2. Agregar el remoto
git remote add origin https://github.com/lozwilsonosmar-star/metin2omg.git

# 3. Agregar todos los archivos
git add .

# 4. Hacer commit
git commit -m "Initial commit: Metin2 Server con soporte Ubuntu 24.04"

# 5. Subir al repositorio
git branch -M main
git push -u origin main
```

---

## 🖥️ Paso 2: Conectar y Preparar el VPS

### 2.1 Conectar al VPS

```bash
ssh root@72.61.12.2
# O usando el hostname
ssh root@srv1141732.hstgr.cloud
```

### 2.2 Actualizar el sistema

```bash
apt-get update && apt-get upgrade -y
```

### 2.3 Instalar dependencias básicas

```bash
apt-get install -y git docker.io docker-compose
systemctl enable docker
systemctl start docker
```

---

## 📥 Paso 3: Clonar y Configurar en el VPS

### 3.1 Clonar el repositorio

```bash
cd /opt
git clone https://github.com/lozwilsonosmar-star/metin2omg.git
cd metin2omg
```

### 3.2 Ejecutar script de instalación

```bash
chmod +x instalar-en-vps.sh
sudo bash instalar-en-vps.sh
```

**O si prefieres usar Docker (recomendado):**

```bash
# Construir la imagen Docker
docker build -t metin2/server:latest --provenance=false .
```

---

## 🗄️ Paso 4: Configurar Base de Datos

### 4.1 Instalar MariaDB/MySQL

```bash
apt-get install -y mariadb-server mariadb-client
systemctl enable mariadb
systemctl start mariadb
```

### 4.2 Configurar MySQL (primera vez)

```bash
mysql_secure_installation
```

### 4.3 Crear bases de datos

```bash
mysql -u root -p
```

Dentro de MySQL, ejecutar:

```sql
CREATE DATABASE metin2_account CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE metin2_common CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE metin2_player CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE metin2_log CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'metin2'@'localhost' IDENTIFIED BY 'tu_password_seguro';
GRANT ALL PRIVILEGES ON metin2_account.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_common.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_player.* TO 'metin2'@'localhost';
GRANT ALL PRIVILEGES ON metin2_log.* TO 'metin2'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**⚠️ IMPORTANTE:** Cambia `tu_password_seguro` por una contraseña segura.

---

## ⚙️ Paso 5: Configurar el Servidor

### 5.1 Si usas Docker

Crear archivo `.env` en el directorio del proyecto:

```bash
nano .env
```

Contenido del `.env`:

```env
# Database Configuration
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=metin2
MYSQL_PASSWORD=tu_password_seguro
MYSQL_DB_ACCOUNT=metin2_account
MYSQL_DB_COMMON=metin2_common
MYSQL_DB_PLAYER=metin2_player
MYSQL_DB_LOG=metin2_log

# Server Configuration
DB_PORT=8888
GAME_PORT=12345
GAME_P2P_PORT=13200
GAME_HOSTNAME=Metin2OMG
GAME_CHANNEL=1
PUBLIC_IP=72.61.12.2
PUBLIC_BIND_IP=0.0.0.0
INTERNAL_IP=127.0.0.1
INTERNAL_BIND_IP=0.0.0.0
DB_ADDR=localhost
GAME_AUTH_SERVER=localhost
GAME_MARK_SERVER=localhost
GAME_MAP_ALLOW=all
GAME_MAX_LEVEL=99
TEST_SERVER=0
WEB_APP_URL=
WEB_APP_KEY=
```

### 5.2 Si compilas directamente

Configurar archivos `db.conf` y `game.conf` en los directorios correspondientes.

---

## 🚀 Paso 6: Iniciar el Servidor

### Opción A: Usando Docker (Recomendado)

```bash
# Construir e iniciar
docker-compose up -d

# O manualmente
docker run -d \
  --name metin2-server \
  --restart unless-stopped \
  -p 12345:12345 \
  -p 13200:13200 \
  -p 8888:8888 \
  --env-file .env \
  metin2/server:latest
```

### Opción B: Compilación directa

```bash
# Compilar
mkdir build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake ..
make -j $(nproc)

# Iniciar servicios (en orden)
# Terminal 1: DB Server
cd /opt/metin2omg/build/src/db
./db

# Terminal 2: Game Server
cd /opt/metin2omg/build/src/game
./game
```

---

## 🔍 Paso 7: Verificar que Funciona

### Verificar contenedores Docker

```bash
docker ps
docker logs metin2-server
```

### Verificar puertos

```bash
netstat -tulpn | grep -E '12345|13200|8888'
```

### Probar conexión

```bash
telnet localhost 12345
```

---

## 🛠️ Comandos Útiles

### Ver logs del servidor

```bash
# Docker
docker logs -f metin2-server

# Directo
tail -f /opt/metin2omg/logs/game.log
```

### Reiniciar servidor

```bash
# Docker
docker restart metin2-server

# Directo
pkill -f game
pkill -f db
# Luego reiniciar manualmente
```

### Detener servidor

```bash
# Docker
docker stop metin2-server

# Directo
pkill -f game
pkill -f db
```

### Actualizar desde GitHub

```bash
cd /opt/metin2omg
git pull origin main
docker build -t metin2/server:latest --provenance=false .
docker restart metin2-server
```

---

## 🔒 Seguridad

### Firewall (UFW)

```bash
# Instalar UFW
apt-get install -y ufw

# Permitir SSH
ufw allow 22/tcp

# Permitir puertos del juego
ufw allow 12345/tcp
ufw allow 13200/tcp

# Activar firewall
ufw enable
```

### Cambiar contraseñas por defecto

- Cambiar contraseña de MySQL
- Cambiar `ADMINPAGE_PASSWORD` en `game.conf`
- Usar contraseñas seguras en `.env`

---

## 📝 Notas Importantes

1. **Puertos necesarios:**
   - `12345` - Puerto del juego (cliente)
   - `13200` - Puerto P2P (servidor-servidor)
   - `8888` - Puerto DB Server

2. **Recursos recomendados:**
   - Mínimo 2GB RAM
   - 10GB espacio en disco
   - 1 CPU core

3. **Backup:**
   - Hacer backup regular de las bases de datos
   - Guardar configuración en repositorio privado

4. **Monitoreo:**
   - Revisar logs regularmente
   - Monitorear uso de recursos
   - Configurar alertas si es posible

---

## 🆘 Solución de Problemas

Ver sección [Troubleshooting](README.md#6-troubleshooting) en el README principal.

---

## 📞 Soporte

- Revisar logs: `docker logs metin2-server`
- Verificar configuración: `.env` y archivos de configuración
- Revisar estado de servicios: `systemctl status mariadb`, `docker ps`

