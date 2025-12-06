# Resolver conflicto de Git en VPS

Si tienes cambios locales que bloquean el `git pull`, ejecuta estos comandos:

## Opción 1: Guardar cambios locales (recomendado)

```bash
cd /opt/metin2omg
git stash
git pull origin main
git stash pop  # Si quieres recuperar tus cambios después
```

## Opción 2: Descartar cambios locales

```bash
cd /opt/metin2omg
git checkout -- setup-database.sh
git pull origin main
```

## Opción 3: Hacer commit de cambios locales

```bash
cd /opt/metin2omg
git add setup-database.sh
git commit -m "Cambios locales en setup-database.sh"
git pull origin main
```

Después de resolver el conflicto, ejecuta:

```bash
chmod +x actualizar-vps.sh
sudo bash actualizar-vps.sh
```

