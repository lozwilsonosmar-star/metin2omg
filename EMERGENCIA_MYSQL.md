# 🚨 INSTRUCCIONES DE EMERGENCIA - MySQL Reemplazado

## ⚠️ SITUACIÓN ACTUAL

Si ejecutaste `deploy-vps.sh` por error, es posible que MySQL 8.0 haya sido reemplazado por MariaDB. **NO TE PREOCUPES**, podemos restaurarlo.

---

## 🔍 PASO 1: Verificar el Estado Actual

Conéctate a tu VPS y ejecuta:

```bash
ssh root@72.61.12.2
```

Luego verifica qué versión de MySQL/MariaDB está instalada:

```bash
mysql --version
systemctl status mysql
# o
systemctl status mariadb
```

---

## 🔄 PASO 2: Restaurar MySQL 8.0 (Si es Necesario)

### Opción A: Si MySQL 8.0 aún está disponible

Si ves que MySQL 8.0 sigue instalado pero MariaDB también está instalado:

```bash
# Detener MariaDB
systemctl stop mariadb
systemctl disable mariadb

# Asegurar que MySQL 8.0 esté corriendo
systemctl start mysql
systemctl enable mysql

# Verificar que tu app web sigue funcionando
```

### Opción B: Si MySQL 8.0 fue completamente reemplazado

Si MySQL 8.0 fue removido y solo MariaDB está instalado:

```bash
# 1. Hacer backup de tus datos actuales (por si acaso)
mysqldump -u root -p --all-databases > /root/mysql_backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Detener MariaDB
systemctl stop mariadb
systemctl disable mariadb

# 3. Remover MariaDB
apt-get remove --purge mariadb-server mariadb-client mariadb-common -y
apt-get autoremove -y
apt-get autoclean

# 4. Reinstalar MySQL 8.0
apt-get update
apt-get install -y mysql-server mysql-client

# 5. Restaurar tus datos (si es necesario)
# mysql -u root -p < /root/mysql_backup_*.sql

# 6. Iniciar MySQL 8.0
systemctl start mysql
systemctl enable mysql
```

**⚠️ IMPORTANTE:** Si tienes datos importantes en MariaDB que no estaban en MySQL 8.0, primero haz un backup completo antes de remover MariaDB.

---

## ✅ PASO 3: Usar el Script Correcto

Una vez que MySQL 8.0 esté restaurado y funcionando:

```bash
cd /opt/metin2omg

# Detener el script incorrecto si aún está corriendo (Ctrl+C)

# Usar el script correcto
chmod +x deploy-vps-existing-mysql.sh
sudo bash deploy-vps-existing-mysql.sh
```

Este script:
- ✅ **NO reinstala MySQL** (usa el existente)
- ✅ Solo crea las 4 bases de datos nuevas: `metin2_*`
- ✅ Crea un usuario nuevo `metin2` (no toca usuarios existentes)
- ✅ No modifica tu app web
- ✅ No toca tus bases de datos existentes

---

## 🔍 PASO 4: Verificar que Todo Funciona

### Verificar MySQL 8.0:

```bash
mysql --version
# Debe mostrar: mysql Ver 8.0.x

systemctl status mysql
# Debe estar "active (running)"
```

### Verificar tus bases de datos existentes:

```bash
mysql -u root -p -e "SHOW DATABASES;"
```

Deberías ver:
- Tus bases de datos existentes (intactas)
- Las 4 nuevas: `metin2_account`, `metin2_common`, `metin2_player`, `metin2_log`

### Verificar que tu app web sigue funcionando:

Accede a tu aplicación web normalmente. Debe funcionar igual que antes.

---

## 🆘 Si Algo Sale Mal

### Si MySQL no inicia:

```bash
# Ver logs de error
journalctl -u mysql -n 50

# Verificar permisos
ls -la /var/lib/mysql/

# Si hay problemas, restaurar desde backup
mysql -u root -p < /root/mysql_backup_*.sql
```

### Si necesitas ayuda adicional:

1. Verifica los logs: `tail -f /var/log/mysql/error.log`
2. Verifica el estado: `systemctl status mysql`
3. Verifica la configuración: `cat /etc/mysql/mysql.conf.d/mysqld.cnf`

---

## 📝 RESUMEN

1. **Verificar estado actual** de MySQL/MariaDB
2. **Restaurar MySQL 8.0** si fue reemplazado
3. **Usar `deploy-vps-existing-mysql.sh`** (NO `deploy-vps.sh`)
4. **Verificar** que todo funciona correctamente

---

## ✅ Checklist Final

- [ ] MySQL 8.0 está instalado y corriendo
- [ ] Tu app web funciona correctamente
- [ ] Las bases de datos existentes están intactas
- [ ] Las 4 nuevas bases `metin2_*` fueron creadas
- [ ] El servidor Metin2 está corriendo en Docker

