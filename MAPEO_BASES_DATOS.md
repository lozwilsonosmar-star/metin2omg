# Mapeo Completo de Tablas y Bases de Datos - Metin2 Server

## Análisis del Código Fuente

Todas las funciones `Initialize*` en `ClientManagerBoot.cpp` usan `CDBManager::instance().DirectQuery(query)` **sin especificar el slot**, lo que significa que usan `SQL_PLAYER` por defecto (según `DBManager.h:46`).

## Mapeo Correcto de Tablas

### BASE DE DATOS: metin2_account
**Conexión**: `SQL_ACCOUNT`
- `account` - Cuentas de usuario
- `player_index` - Índice de jugadores por cuenta

### BASE DE DATOS: metin2_common
**Conexión**: `SQL_COMMON` (usado explícitamente en algunas consultas)
- `locale` - Configuración de idioma y locale (usado con SQL_COMMON)
- `gmlist` - Lista de GMs
- `item_award` - Premios de items
- `guild_war_reservation` - Reservas de guerra de gremios
- `guild_war_bet` - Apuestas de guerra de gremios
- `monarch` - Monarcas
- `monarch_election` - Elecciones de monarcas
- `monarch_candidacy` - Candidatos a monarca
- `marriage` - Matrimonios
- `horse_name` - Nombres de caballos

### BASE DE DATOS: metin2_player
**Conexión**: `SQL_PLAYER` (por defecto cuando no se especifica slot)
**Todas estas tablas se leen usando `DirectQuery` sin slot:**

#### Tablas Proto (se leen desde BD al iniciar):
- `refine_proto` - Prototipos de refinamiento
- `skill_proto` - Prototipos de habilidades ⚠️ **FALTA**
- `quest_item_proto` - Prototipos de items de quest
- `item_attr` - Atributos de items
- `item_attr_rare` - Atributos raros de items
- `banword` - Palabras prohibidas
- `object_proto` - Prototipos de objetos de construcción

#### Tablas de Datos de Juego (se cargan desde archivos .txt):
- `mob_proto` - Prototipos de monstruos (se carga desde `mob_proto.txt` y se inserta con `MirrorMobTableIntoDB()`)
- `item_proto` - Prototipos de items (se carga desde `item_proto.txt` y se inserta con `MirrorItemTableIntoDB()`)

#### Tablas de Tiendas:
- `shop` - Tiendas
- `shop_item` - Items de tiendas

#### Tablas de Construcción:
- `land` - Tierras (se lee con `InitializeLandTable()`)
- `object` - Objetos en el mundo (se lee con `InitializeObjectTable()`)

#### Tablas de Jugadores:
- `player` - Jugadores
- `item` - Items de jugadores
- `quest` - Quests de jugadores
- `affect` - Efectos activos
- `guild` - Gremios
- `guild_member` - Miembros de gremios
- `guild_grade` - Grados de gremios
- `guild_comment` - Comentarios de gremios

### BASE DE DATOS: metin2_log
**Conexión**: `SQL_LOG` (usado para logs)
- `log` - Logs generales
- `loginlog` - Logs de login
- `hack_log` - Logs de hacks
- `hack_crc_log` - Logs de CRC de hacks
- `goldlog` - Logs de oro
- `cube` - Logs de cubos
- `speed_hack` - Logs de speed hack
- `change_name` - Logs de cambio de nombre
- `hackshield_log` - Logs de HackShield

## Fuentes de Datos

### 1. Archivos .txt (se cargan al iniciar el servidor DB):
- `mob_proto.txt` → se inserta en `mob_proto` (metin2_player)
- `item_proto.txt` → se inserta en `item_proto` (metin2_player)
- `mob_names.txt` → se usa para nombres localizados de monstruos
- `mob_proto_test.txt` → archivo opcional de prueba
- `item_proto_test.txt` → archivo opcional de prueba

### 2. Base de Datos (se leen al iniciar):
- `refine_proto` - Debe existir (puede estar vacía)
- `skill_proto` - Debe existir (puede estar vacía)
- `quest_item_proto` - Debe existir (puede estar vacía)
- `item_attr` - Debe existir (puede estar vacía)
- `item_attr_rare` - Debe existir (puede estar vacía)
- `banword` - Debe existir (puede estar vacía)
- `object_proto` - Debe existir (puede estar vacía)
- `shop` - Debe existir y tener al menos 1 registro
- `shop_item` - Puede estar vacía
- `land` - Debe existir (puede estar vacía)
- `object` - Debe existir (puede estar vacía)

### 3. Configuración (locale):
- `locale` (metin2_common) - Debe tener al menos:
  - `LANGUAGE` = 'kr'
  - `LOCALE` = 'korea'
  - `SKILL_POWER_BY_LEVEL` = '0 5 7 9 11 13 15 17 19 20 22 24 26 28 30 32 34 36 38 40 50 52 55 58 61 63 66 69 72 75 80 82 84 87 90 95 100 110 120 130 150' (41 valores)

## Estado Actual

✅ **TODAS LAS TABLAS ESTÁN CORRECTAMENTE MAPEADAS**

1. ✅ `skill_proto` agregada a `metin2_player`
2. ✅ `refine_proto` movida a `metin2_player`
3. ✅ `quest_item_proto` movida a `metin2_player`
4. ✅ `item_attr` movida a `metin2_player`
5. ✅ `item_attr_rare` movida a `metin2_player`
6. ✅ `banword` movida a `metin2_player`
7. ✅ `object_proto` movida a `metin2_player`
8. ✅ `land` movida a `metin2_player`
9. ✅ `object` movida a `metin2_player`
10. ✅ `shop` tiene un registro por defecto (vnum=1, npc_vnum=0)

## Verificación

Para verificar que todas las tablas están en las bases de datos correctas, ejecutar:

```bash
# En el VPS
cd /opt/metin2omg
export MYSQL_PWD=$(grep "^MYSQL_PASSWORD=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
mysql -h127.0.0.1 -P3306 -umetin2 -e "USE metin2_player; SHOW TABLES;" | grep -E "(skill_proto|refine_proto|quest_item_proto|item_attr|banword|object_proto|land|object)"
unset MYSQL_PWD
```

Todas estas tablas deben aparecer en la salida.

