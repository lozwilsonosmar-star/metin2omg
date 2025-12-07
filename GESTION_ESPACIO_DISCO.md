# Gestión de Espacio en Disco - VPS Metin2

## 🔴 Problema

Cada vez que compilas el servidor, el espacio en disco se llena. Esto es porque Docker acumula:
- Imágenes Docker (cada build crea nuevas capas)
- Build cache (archivos temporales de compilación)
- Contenedores detenidos
- Volúmenes no usados
- Logs de Docker

## 📊 Verificar Uso de Espacio

```bash
# Ver espacio total
df -h /

# Ver qué está ocupando espacio en Docker
docker system df

# Ver imágenes Docker
docker images

# Ver tamaño de cada imagen
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

## 🧹 Solución: Script de Limpieza Automática

He creado `docker/limpiar-docker.sh` que limpia todo automáticamente.

### Uso:

```bash
cd /opt/metin2omg
chmod +x docker/limpiar-docker.sh
bash docker/limpiar-docker.sh
```

### Qué limpia:

1. ✅ Contenedores detenidos
2. ✅ Imágenes no etiquetadas (dangling)
3. ✅ Imágenes no usadas
4. ✅ Volúmenes no usados
5. ✅ Redes no usadas
6. ✅ **Build cache** (muy importante - libera mucho espacio)
7. ✅ Todo el sistema Docker

## 🚀 Script de Actualización Optimizado

He creado `actualizar-vps-optimizado.sh` que:
- Limpia Docker ANTES de construir
- Limpia Docker DESPUÉS de construir
- Elimina imágenes antiguas automáticamente
- Usa `--no-cache` para evitar acumulación de cache

### Uso:

```bash
cd /opt/metin2omg
chmod +x actualizar-vps-optimizado.sh
sudo bash actualizar-vps-optimizado.sh
```

## 📋 Limpieza Manual (si prefieres hacerlo paso a paso)

### 1. Limpiar Build Cache (libera MUCHO espacio):

```bash
docker builder prune -a -f
```

### 2. Eliminar imágenes no usadas:

```bash
# Solo imágenes sin etiquetas
docker image prune -f

# Todas las imágenes no usadas (más agresivo)
docker image prune -a -f
```

### 3. Eliminar contenedores detenidos:

```bash
docker container prune -f
```

### 4. Limpieza completa:

```bash
docker system prune -a -f --volumes
```

### 5. Eliminar imagen específica antigua:

```bash
# Ver imágenes
docker images | grep metin2/server

# Eliminar imagen antigua (no latest)
docker rmi metin2/server:old-tag
```

## 🔄 Estrategia Recomendada

### Opción 1: Usar script optimizado (RECOMENDADO)

```bash
# En lugar de actualizar-vps.sh, usar:
sudo bash actualizar-vps-optimizado.sh
```

Este script limpia automáticamente antes y después de construir.

### Opción 2: Limpiar manualmente antes de actualizar

```bash
# 1. Limpiar Docker
bash docker/limpiar-docker.sh

# 2. Actualizar normalmente
sudo bash actualizar-vps.sh
```

### Opción 3: Limpiar periódicamente

```bash
# Agregar a crontab para limpiar cada semana
crontab -e

# Agregar esta línea (limpia cada domingo a las 3 AM):
0 3 * * 0 /opt/metin2omg/docker/limpiar-docker.sh
```

## 📊 Monitoreo de Espacio

### Ver qué está ocupando más espacio:

```bash
# Top 10 directorios más grandes
du -h / | sort -rh | head -10

# Espacio usado por Docker
docker system df -v

# Tamaño de imágenes
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | sort -k3 -h
```

### Verificar logs grandes:

```bash
# Ver tamaño de logs de Docker
du -sh /var/lib/docker/containers/*/

# Limpiar logs de contenedores (cuidado, elimina logs)
truncate -s 0 /var/lib/docker/containers/*/*-json.log
```

## ⚠️ Advertencias

1. **NO eliminar la imagen `metin2/server:latest`** - Es la que está en uso
2. **NO limpiar mientras el servidor está corriendo** - Puede causar problemas
3. **Hacer backup antes de limpiar agresivamente** - Si tienes datos importantes

## 🎯 Comandos Rápidos

```bash
# Limpieza rápida (solo cache y contenedores)
docker system prune -f && docker builder prune -a -f

# Ver espacio liberado
docker system df

# Ver espacio en disco
df -h /
```

## 📈 Espacio Esperado

Después de una limpieza completa:
- **Imagen Docker final**: ~2-3 GB
- **Build cache**: 0 GB (eliminado)
- **Contenedores**: ~100-200 MB
- **Total Docker**: ~3-4 GB

Si tienes 29 GB ocupados, probablemente tienes:
- Múltiples builds acumulados
- Build cache grande
- Imágenes antiguas
- Logs grandes

**Una limpieza completa debería liberar ~20-25 GB**

## 🔧 Optimización del Dockerfile (Futuro)

Para reducir aún más el espacio, podríamos:
1. Usar imágenes base más pequeñas (Alpine Linux)
2. Multi-stage builds más agresivos
3. Eliminar dependencias de build en la imagen final
4. Comprimir archivos grandes

Pero esto requiere modificar el Dockerfile y puede romper cosas.

---

## ✅ Resumen: Qué Hacer AHORA

```bash
# 1. Limpiar Docker completamente
cd /opt/metin2omg
chmod +x docker/limpiar-docker.sh
bash docker/limpiar-docker.sh

# 2. Verificar espacio liberado
df -h /

# 3. Para futuras actualizaciones, usar el script optimizado
chmod +x actualizar-vps-optimizado.sh
# (usar este en lugar de actualizar-vps.sh)
```

¡Esto debería liberar ~20-25 GB de espacio! 🎉

