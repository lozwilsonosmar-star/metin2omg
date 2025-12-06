# Resolver Columnas Faltantes

## Problema
Hay cambios locales en `docker/verificar-y-crear-todo.sh` que bloquean el `git pull`.

## Solución Rápida

Ejecuta estos comandos en orden:

```bash
cd /opt/metin2omg

# Opción 1: Descartar cambios locales (recomendado)
git checkout -- docker/verificar-y-crear-todo.sh

# Opción 2: O guardar cambios locales
# git stash

# Luego actualizar
git pull origin main

# Ejecutar script para agregar columnas faltantes
export MYSQL_PWD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
mysql -h127.0.0.1 -P3306 -umetin2 < docker/agregar-columnas-faltantes.sql
unset MYSQL_PWD

# Verificar que se agregaron
bash docker/verificar-y-crear-todo.sh
```

## Verificar Logs del Servidor

```bash
docker logs -f metin2-server
```

