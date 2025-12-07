# 🎮 Cómo Ejecutar el Cliente Metin2

## 📍 Ubicación del Cliente

El cliente está en la siguiente ruta:

```
metin2-server/Client-20251206T130044Z-3-001/Client/Client/Client/
```

## 🚀 Ejecutables Disponibles

En la carpeta del cliente encontrarás estos ejecutables:

### 1. **Metin2Distribute.exe** (Cliente Principal)
   - **Ubicación:** `Client-20251206T130044Z-3-001/Client/Client/Client/Metin2Distribute.exe`
   - **Descripción:** Este es el ejecutable principal del cliente Metin2
   - **Cómo ejecutar:** Doble clic en `Metin2Distribute.exe`

### 2. **EterNexus.exe** (Launcher Alternativo)
   - **Ubicación:** `Client-20251206T130044Z-3-001/Client/Client/Client/Eternexus/EterNexus.exe`
   - **Descripción:** Launcher alternativo del cliente
   - **Cómo ejecutar:** Doble clic en `EterNexus.exe`

### 3. **config.exe** (Configurador)
   - **Ubicación:** `Client-20251206T130044Z-3-001/Client/Client/Client/config.exe`
   - **Descripción:** Herramienta para configurar opciones del cliente
   - **Cómo ejecutar:** Doble clic en `config.exe`

## 📋 Pasos para Ejecutar el Cliente

### Opción 1: Ejecutar desde Windows (Recomendado)

1. **Navega a la carpeta del cliente:**
   ```
   C:\Users\USUARIO\Desktop\metingit\metin2-server\Client-20251206T130044Z-3-001\Client\Client\Client\
   ```

2. **Ejecuta el cliente:**
   - Haz doble clic en `Metin2Distribute.exe`
   - O haz doble clic en `EterNexus.exe`

3. **Inicia sesión:**
   - Usuario: `test`
   - Contraseña: `test123`

### Opción 2: Crear un acceso directo

1. **Crea un acceso directo:**
   - Haz clic derecho en `Metin2Distribute.exe`
   - Selecciona "Crear acceso directo"
   - Mueve el acceso directo a tu escritorio

2. **Ejecuta desde el acceso directo:**
   - Doble clic en el acceso directo del escritorio

## ⚙️ Configuración del Cliente

### ✅ Ya está configurado

El cliente ya está configurado con:
- **IP del servidor:** `72.61.12.2`
- **Puerto del juego:** `12345`
- **Nombre del servidor:** `Metin2OMG`

### 📝 Archivos de configuración

Los archivos de configuración están en:
- `Eternexus/root/serverinfo.py` - Configuración principal del servidor
- `channel.inf` - Información del canal
- `metin2.cfg` - Configuración gráfica del cliente

## 🔧 Requisitos Previos

### Visual C++ Redistributables

Si el cliente no inicia, instala los Visual C++ Redistributables:
- `Eternexus/vcredist_x86.exe` (para sistemas de 32 bits)
- `Eternexus/vcredist_x64.exe` (para sistemas de 64 bits)

### Dependencias

El cliente necesita estas DLLs (ya están incluidas):
- `python27.dll`
- `granny2.dll`
- `SpeedTreeRT.dll`
- `MSS32.DLL`
- Y otras DLLs en la carpeta `Eternexus/`

## 🐛 Solución de Problemas

### El cliente no inicia

1. **Verifica que tengas los Visual C++ Redistributables instalados**
2. **Ejecuta como administrador:**
   - Clic derecho en `Metin2Distribute.exe`
   - Selecciona "Ejecutar como administrador"

### Error de conexión

1. **Verifica que el servidor esté corriendo:**
   ```bash
   # En el VPS:
   docker ps | grep metin2-server
   ss -tuln | grep 12345
   ```

2. **Verifica el firewall:**
   - El puerto 12345 debe estar abierto en el VPS

3. **Verifica la configuración:**
   - Abre `Eternexus/root/serverinfo.py`
   - Verifica que `SERVER_IP = "72.61.12.2"`

### El cliente no encuentra el servidor

1. **Verifica serverinfo.py:**
   - Debe tener `SERVER_IP = "72.61.12.2"`
   - Debe tener `PORT_1 = 12345`

2. **Verifica que el servidor esté escuchando:**
   ```bash
   # En el VPS:
   docker logs metin2-server | grep "TCP listening"
   ```

## 📂 Estructura de Carpetas Importantes

```
Client/
├── Metin2Distribute.exe      ← Ejecutable principal
├── config.exe                 ← Configurador
├── channel.inf                ← Info del canal
├── metin2.cfg                 ← Configuración gráfica
├── Eternexus/
│   ├── EterNexus.exe         ← Launcher alternativo
│   ├── root/
│   │   └── serverinfo.py     ← ⚠️ Configuración del servidor (YA CONFIGURADO)
│   └── uiscript/             ← Scripts de interfaz
└── pack/                      ← Archivos de datos del juego
```

## ✅ Checklist Antes de Ejecutar

- [ ] El servidor está corriendo en el VPS
- [ ] El puerto 12345 está abierto en el firewall
- [ ] `serverinfo.py` tiene la IP correcta (`72.61.12.2`)
- [ ] Tienes una cuenta creada (usuario: `test`, contraseña: `test123`)
- [ ] Los Visual C++ Redistributables están instalados

## 🎯 Resumen Rápido

**Para ejecutar el cliente:**

1. Ve a: `Client-20251206T130044Z-3-001/Client/Client/Client/`
2. Haz doble clic en: `Metin2Distribute.exe`
3. Inicia sesión con: `test` / `test123`

¡Listo! 🎮

