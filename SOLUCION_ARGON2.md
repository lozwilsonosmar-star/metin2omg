# Solución: Error "wrongcrd" - Hash Argon2id

## Problema

El servidor Metin2 usa **Argon2id** para verificar contraseñas, NO SHA1. Por eso el error "wrongcrd" persiste.

## Verificación en el Código

En `src/game/src/db.cpp` línea 365:
```cpp
bool loginStatus = argon2id_verify(szHashedPassword, pinfo->passwd, strlen(pinfo->passwd)) == ARGON2_OK;
```

## Solución

### Opción 1: Usar el contenedor del servidor (Recomendado)

El contenedor ya tiene las librerías Argon2 compiladas. Podemos crear un pequeño programa C++ o usar una herramienta.

### Opción 2: Instalar argon2 en el VPS

```bash
sudo apt-get update
sudo apt-get install -y argon2
```

Luego generar el hash:
```bash
echo -n "metin2test123" | argon2 "salt123456789012345678901234567890" -id -t 3 -m 12 -p 1 -l 32
```

### Opción 3: Usar Python con argon2-cffi

```bash
# Instalar
pip3 install argon2-cffi

# Generar hash
python3 -c "from argon2 import PasswordHasher; ph = PasswordHasher(); print(ph.hash('metin2test123'))"
```

### Opción 4: Crear un programa C++ simple

Podemos compilar un pequeño programa que use la misma librería que el servidor.

## Actualizar la cuenta

Una vez tengas el hash Argon2id:

```bash
mysql -uroot -pproyectalean -Dmetin2_account -e "UPDATE account SET password='HASH_ARGON2ID_AQUI', status='OK', last_play=NOW() WHERE login='test';"
```

## Nota Importante

El hash Argon2id incluye:
- El algoritmo usado (argon2id)
- Los parámetros (time cost, memory cost, parallelism)
- El salt
- El hash final

Todo esto en un solo string codificado. Por eso no podemos usar SHA1.

