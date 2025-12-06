# 🚀 Inicio Rápido - Metin2 Server

## Para subir al repositorio GitHub

```bash
cd metin2-server
git init
git remote add origin https://github.com/lozwilsonosmar-star/metin2omg.git
git add .
git commit -m "Initial commit: Metin2 Server Ubuntu 24.04"
git branch -M main
git push -u origin main
```

## Para desplegar en el VPS (Ubuntu 24.04)

### Opción 1: Script Automático (Recomendado)

```bash
# Conectar al VPS
ssh root@72.61.12.2

# Clonar repositorio
cd /opt
git clone https://github.com/lozwilsonosmar-star/metin2omg.git
cd metin2omg

# Ejecutar script de deployment
chmod +x deploy-vps.sh
sudo bash deploy-vps.sh
```

### Opción 2: Manual

```bash
# 1. Conectar al VPS
ssh root@72.61.12.2

# 2. Actualizar sistema
apt-get update && apt-get upgrade -y

# 3. Instalar dependencias
apt-get install -y git docker.io docker-compose mariadb-server

# 4. Iniciar servicios
systemctl enable docker mariadb
systemctl start docker mariadb

# 5. Clonar repositorio
cd /opt
git clone https://github.com/lozwilsonosmar-star/metin2omg.git
cd metin2omg

# 6. Instalar dependencias del proyecto
chmod +x instalar-en-vps.sh
sudo bash instalar-en-vps.sh

# 7. Configurar MySQL
mysql_secure_installation
mysql -u root -p < docker/init-db.sql

# 8. Configurar .env
nano .env  # Editar contraseñas y configuración

# 9. Construir e iniciar
docker-compose up -d
```

## Comandos Útiles

```bash
# Ver logs
docker logs -f metin2-server

# Reiniciar
docker restart metin2-server

# Detener
docker stop metin2-server

# Actualizar desde GitHub
cd /opt/metin2omg
git pull origin main
docker-compose build
docker-compose up -d
```

## Verificar que funciona

```bash
# Ver contenedores
docker ps

# Ver puertos
netstat -tulpn | grep -E '12345|13200|8888'

# Probar conexión
telnet localhost 12345
```

## Configuración de Base de Datos

```sql
mysql -u root -p

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

## Archivo .env de ejemplo

```env
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=metin2
MYSQL_PASSWORD=tu_password_seguro
MYSQL_DB_ACCOUNT=metin2_account
MYSQL_DB_COMMON=metin2_common
MYSQL_DB_PLAYER=metin2_player
MYSQL_DB_LOG=metin2_log

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
```

## Puertos Necesarios

- **12345** - Puerto del juego (cliente se conecta aquí)
- **13200** - Puerto P2P (comunicación servidor-servidor)
- **8888** - Puerto DB Server

## Firewall

```bash
ufw allow 22/tcp    # SSH
ufw allow 12345/tcp # Game
ufw allow 13200/tcp # P2P
ufw enable
```

