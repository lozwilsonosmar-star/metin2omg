# Solución: Problema de Autenticación GitHub

## 🔐 Problema
GitHub ya no permite autenticación con contraseña. Necesitas usar un token o hacer el repositorio público.

---

## ✅ Solución 1: Hacer el Repositorio Público (MÁS FÁCIL)

### Pasos:

1. Ve a: https://github.com/lozwilsonosmar-star/metin2omg/settings

2. Baja hasta la sección **"Danger Zone"**

3. Haz clic en **"Change visibility"** → **"Make public"**

4. Confirma escribiendo el nombre del repositorio

5. Ahora puedes clonar sin autenticación:

```bash
cd /opt
git clone https://github.com/lozwilsonosmar-star/metin2omg.git
cd metin2omg
```

---

## 🔑 Solución 2: Usar Token de Acceso Personal

### Crear Token:

1. Ve a: https://github.com/settings/tokens

2. Click en **"Generate new token"** → **"Generate new token (classic)"**

3. Configura:
   - **Note:** "Metin2 Server VPS"
   - **Expiration:** 90 days (o el que prefieras)
   - **Scopes:** Marca `repo` (acceso completo a repositorios)

4. Click en **"Generate token"**

5. **COPIA EL TOKEN** (solo se muestra una vez)

### Usar el Token:

```bash
cd /opt
git clone https://TU_TOKEN@github.com/lozwilsonosmar-star/metin2omg.git
```

O mejor, usa el token como contraseña cuando te lo pida:

```bash
cd /opt
git clone https://github.com/lozwilsonosmar-star/metin2omg.git
# Username: lozwilsonosmar-star
# Password: [PEGA TU TOKEN AQUÍ]
```

---

## 🔐 Solución 3: Usar SSH (Más Seguro)

### En tu PC (Windows):

```bash
# Generar clave SSH (si no tienes)
ssh-keygen -t ed25519 -C "lozwilsonosmar@gmail.com"

# Ver la clave pública
cat ~/.ssh/id_ed25519.pub
```

### Agregar clave a GitHub:

1. Copia el contenido de la clave pública
2. Ve a: https://github.com/settings/keys
3. Click en **"New SSH key"**
4. Pega la clave y guarda

### En el VPS:

```bash
# Copiar la clave privada al VPS (desde tu PC)
scp ~/.ssh/id_ed25519 root@72.61.12.2:~/.ssh/
scp ~/.ssh/id_ed25519.pub root@72.61.12.2:~/.ssh/

# En el VPS, configurar permisos
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Clonar usando SSH
cd /opt
git clone git@github.com:lozwilsonosmar-star/metin2omg.git
```

---

## 🚀 Recomendación

**Para este caso, la Solución 1 (repositorio público) es la más rápida y simple.**

Si el código no contiene información sensible (contraseñas, keys, etc.), hacerlo público es perfecto.

---

## ⚠️ Importante

Si haces el repositorio público, asegúrate de:
- No incluir archivos `.env` con contraseñas reales
- No incluir tokens o API keys
- El `.gitignore` ya está configurado para ignorar `.env`

---

## ✅ Después de Resolver la Autenticación

Una vez que puedas clonar, continúa con:

```bash
cd /opt/metin2omg
chmod +x deploy-vps.sh
sudo bash deploy-vps.sh
```


