# 🚨 Instrucciones: VPS con MySQL Existente

## ⚠️ Situación
Tu VPS ya tiene MySQL/MariaDB corriendo con una aplicación web. **NO debemos reinstalar MySQL**.

---

## ✅ Solución: Usar MySQL Existente

### Paso 1: Detener el script actual (si está corriendo)

Presiona `Ctrl+C` para detener el script de deployment.

### Paso 2: Usar el script especializado

```bash
cd /opt/metin2omg
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

## 🔍 Qué se Creará

### Bases de Datos Nuevas (solo estas):
- `metin2_account`
- `metin2_common`
- `metin2_player`
- `metin2_log`

### Usuario Nuevo:
- Usuario: `metin2`
- Solo tiene acceso a las bases `metin2_*`
- **NO tiene acceso a tus otras bases de datos**

---

## 📋 Durante la Ejecución

El script te pedirá:
1. **Contraseña de root de MySQL** (la que ya usas para tu app web)
2. **Contraseña para el usuario `metin2`** (nuevo usuario, puede ser diferente)

---

## ✅ Verificación

### Verificar que tus bases de datos siguen intactas:

```bash
mysql -u root -p -e "SHOW DATABASES;"
```

Deberías ver:
- Tus bases de datos existentes (intactas)
- Las 4 nuevas: `metin2_account`, `metin2_common`, `metin2_player`, `metin2_log`

### Verificar que tu app web sigue funcionando:

Accede a tu aplicación web normalmente. Debe funcionar igual que antes.

---

## 🔒 Seguridad

- El usuario `metin2` **solo** tiene acceso a las bases `metin2_*`
- No puede acceder a tus otras bases de datos
- No modifica usuarios existentes
- No modifica configuraciones de MySQL

---

## 🆘 Si Algo Sale Mal

### Verificar estado de MySQL:

```bash
systemctl status mariadb
# o
systemctl status mysql
```

### Ver todas las bases de datos:

```bash
mysql -u root -p -e "SHOW DATABASES;"
```

### Si necesitas eliminar las bases de datos de Metin2:

```bash
mysql -u root -p << EOF
DROP DATABASE IF EXISTS metin2_account;
DROP DATABASE IF EXISTS metin2_common;
DROP DATABASE IF EXISTS metin2_player;
DROP DATABASE IF EXISTS metin2_log;
DROP USER IF EXISTS 'metin2'@'localhost';
FLUSH PRIVILEGES;
EOF
```

---

## 📝 Resumen

- ✅ Tu MySQL existente: **INTACTO**
- ✅ Tu app web: **SIGUE FUNCIONANDO**
- ✅ Tus bases de datos: **NO SE TOCAN**
- ✅ Solo se agregan: 4 bases nuevas + 1 usuario nuevo

**¡Es completamente seguro!** 🎉


