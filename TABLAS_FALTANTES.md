# Análisis Exhaustivo de Tablas Faltantes en Metin2 Server

## Resumen Ejecutivo

Este documento identifica todas las tablas que faltan en el script `create-all-tables.sql` basándose en el análisis exhaustivo del código fuente del servidor Metin2.

## Tablas Faltantes por Base de Datos

### BASE DE DATOS: metin2_common

#### 1. **refine_proto** ⚠️ CRÍTICA
- **Ubicación en código**: `src/db/src/ClientManagerBoot.cpp:109`
- **Query**: `SELECT id, cost, prob, vnum0, count0, vnum1, count1, vnum2, count2, vnum3, count3, vnum4, count4 FROM refine_proto%s`
- **Quién la crea**: El servidor DB la lee al iniciar, pero debe existir previamente
- **Columnas necesarias**:
  - `id` INT UNSIGNED
  - `cost` INT UNSIGNED
  - `prob` INT UNSIGNED
  - `vnum0` INT UNSIGNED
  - `count0` INT UNSIGNED
  - `vnum1` INT UNSIGNED
  - `count1` INT UNSIGNED
  - `vnum2` INT UNSIGNED
  - `count2` INT UNSIGNED
  - `vnum3` INT UNSIGNED
  - `count3` INT UNSIGNED
  - `vnum4` INT UNSIGNED
  - `count4` INT UNSIGNED

#### 2. **skill_proto** ⚠️ CRÍTICA
- **Ubicación en código**: `src/db/src/ClientManagerBoot.cpp:860`
- **Query**: `SELECT dwVnum, szName, bType, bMaxLevel, dwSplashRange, szPointOn, szPointPoly, szSPCostPoly, szDurationPoly, szDurationSPCostPoly, szCooldownPoly, szMasterBonusPoly, setFlag+0, setAffectFlag+0, szPointOn2, szPointPoly2, szDurationPoly2, setAffectFlag2+0, szPointOn3, szPointPoly3, szDurationPoly3, szGrandMasterAddSPCostPoly, bLevelStep, bLevelLimit, prerequisiteSkillVnum, prerequisiteSkillLevel, iMaxHit, szSplashAroundDamageAdjustPoly, eSkillType+0, dwTargetRange FROM skill_proto%s`
- **Quién la crea**: El servidor DB la lee al iniciar, pero debe existir previamente
- **Columnas necesarias**: (Ver estructura completa en código)

#### 3. **quest_item_proto** ⚠️ CRÍTICA
- **Ubicación en código**: `src/db/src/ClientManagerBoot.cpp:522`
- **Query**: `SELECT vnum, name, %s FROM quest_item_proto ORDER BY vnum`
- **Quién la crea**: El servidor DB la lee al iniciar, pero debe existir previamente
- **Columnas necesarias**:
  - `vnum` INT UNSIGNED PRIMARY KEY
  - `name` VARCHAR(64)
  - `locale_name` VARCHAR(64) (o columna según locale)

#### 4. **item_attr** ⚠️ CRÍTICA
- **Ubicación en código**: `src/db/src/ClientManagerBoot.cpp:972`
- **Query**: `SELECT apply, apply+0, prob, lv1, lv2, lv3, lv4, lv5, weapon, body, wrist, foots, neck, head, shield, ear FROM item_attr%s`
- **Quién la crea**: El servidor DB la lee al iniciar, pero debe existir previamente
- **Columnas necesarias**:
  - `apply` VARCHAR(32) PRIMARY KEY
  - `prob` INT UNSIGNED
  - `lv1` INT
  - `lv2` INT
  - `lv3` INT
  - `lv4` INT
  - `lv5` INT
  - `weapon` TINYINT UNSIGNED
  - `body` TINYINT UNSIGNED
  - `wrist` TINYINT UNSIGNED
  - `foots` TINYINT UNSIGNED
  - `neck` TINYINT UNSIGNED
  - `head` TINYINT UNSIGNED
  - `shield` TINYINT UNSIGNED
  - `ear` TINYINT UNSIGNED

#### 5. **item_attr_rare** ⚠️ CRÍTICA
- **Ubicación en código**: `src/db/src/ClientManagerBoot.cpp:1046`
- **Query**: Similar a `item_attr`
- **Quién la crea**: El servidor DB la lee al iniciar, pero debe existir previamente
- **Columnas necesarias**: (Misma estructura que `item_attr`)

#### 6. **banword** ⚠️ CRÍTICA
- **Ubicación en código**: `src/db/src/ClientManagerBoot.cpp:944`
- **Query**: `SELECT word FROM banword`
- **Quién la crea**: El servidor DB la lee al iniciar, pero debe existir previamente
- **Columnas necesarias**:
  - `word` VARCHAR(64) PRIMARY KEY

#### 7. **object_proto** ⚠️ CRÍTICA
- **Ubicación en código**: `src/db/src/ClientManagerBoot.cpp:1227`
- **Query**: `SELECT vnum, price, materials, upgrade_vnum, upgrade_limit_time, life, reg_1, reg_2, reg_3, reg_4, npc, group_vnum, dependent_group FROM object_proto%s`
- **Quién la crea**: El servidor DB la lee al iniciar, pero debe existir previamente
- **Columnas necesarias**:
  - `vnum` INT UNSIGNED PRIMARY KEY
  - `price` INT UNSIGNED
  - `materials` VARCHAR(255) (formato: "vnum1,count1/vnum2,count2/...")
  - `upgrade_vnum` INT UNSIGNED
  - `upgrade_limit_time` INT UNSIGNED
  - `life` INT
  - `reg_1` INT
  - `reg_2` INT
  - `reg_3` INT
  - `reg_4` INT
  - `npc` INT UNSIGNED
  - `group_vnum` INT UNSIGNED
  - `dependent_group` INT UNSIGNED

### BASE DE DATOS: metin2_player

#### 8. **guild_comment** ⚠️ IMPORTANTE
- **Ubicación en código**: `src/game/src/guild.cpp:1015, 1024, 1048`
- **Queries**: 
  - `INSERT INTO guild_comment%s(guild_id, name, notice, content, time)`
  - `DELETE FROM guild_comment%s WHERE id = %u AND guild_id = %u`
  - `SELECT id, name, content FROM guild_comment%s WHERE guild_id = %u`
- **Quién la crea**: Se crea dinámicamente cuando se necesita, pero debe existir previamente
- **Columnas necesarias**:
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `guild_id` INT UNSIGNED NOT NULL
  - `name` VARCHAR(24) NOT NULL
  - `notice` TINYINT UNSIGNED NOT NULL DEFAULT 0
  - `content` VARCHAR(50) NOT NULL
  - `time` DATETIME NOT NULL
  - INDEX idx_guild_id (guild_id)

#### 9. **lotto_list** ⚠️ OPCIONAL
- **Ubicación en código**: `src/game/src/questlua_pc.cpp:1604`, `src/game/src/item_manager.cpp:1020`
- **Query**: `INSERT INTO lotto_list VALUES(0, 'server%s', %u, NOW())`
- **Quién la crea**: Se usa para lotería, puede estar vacía inicialmente
- **Columnas necesarias**:
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `server` VARCHAR(32) NOT NULL
  - `pid` INT UNSIGNED NOT NULL
  - `time` DATETIME NOT NULL

### BASE DE DATOS: metin2_log

#### 10. **hack_log** ⚠️ IMPORTANTE
- **Ubicación en código**: `src/game/src/log.cpp:112`
- **Query**: `INSERT INTO hack_log (time, login, name, ip, server, why)`
- **Quién la crea**: Se crea automáticamente cuando se necesita
- **Columnas necesarias**:
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `time` DATETIME NOT NULL
  - `login` VARCHAR(24) NOT NULL
  - `name` VARCHAR(24) NOT NULL
  - `ip` VARCHAR(16) NOT NULL
  - `server` VARCHAR(64) NOT NULL
  - `why` VARCHAR(255) NOT NULL
  - INDEX idx_time (time)
  - INDEX idx_login (login)

#### 11. **hack_crc_log** ⚠️ IMPORTANTE
- **Ubicación en código**: `src/game/src/log.cpp:128`
- **Query**: `INSERT INTO hack_crc_log (time, login, name, ip, server, why, crc)`
- **Quién la crea**: Se crea automáticamente cuando se necesita
- **Columnas necesarias**:
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `time` DATETIME NOT NULL
  - `login` VARCHAR(24) NOT NULL
  - `name` VARCHAR(24) NOT NULL
  - `ip` VARCHAR(16) NOT NULL
  - `server` VARCHAR(64) NOT NULL
  - `why` VARCHAR(255) NOT NULL
  - `crc` INT UNSIGNED NOT NULL
  - INDEX idx_time (time)

#### 12. **goldlog** ⚠️ OPCIONAL
- **Ubicación en código**: `src/game/src/log.cpp:170`
- **Query**: `INSERT INTO goldlog%s (date, time, pid, what, how, hint)`
- **Quién la crea**: Se crea automáticamente cuando se necesita
- **Columnas necesarias**:
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `date` DATE NOT NULL
  - `time` TIME NOT NULL
  - `pid` INT UNSIGNED NOT NULL
  - `what` INT UNSIGNED NOT NULL
  - `how` VARCHAR(32) NOT NULL
  - `hint` VARCHAR(255) NOT NULL
  - INDEX idx_pid (pid)
  - INDEX idx_date (date)

#### 13. **cube** ⚠️ OPCIONAL
- **Ubicación en código**: `src/game/src/log.cpp:176`
- **Query**: `INSERT INTO cube%s (pid, time, x, y, item_vnum, item_uid, item_count, success)`
- **Quién la crea**: Se crea automáticamente cuando se necesita
- **Columnas necesarias**:
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `pid` INT UNSIGNED NOT NULL
  - `time` DATETIME NOT NULL
  - `x` INT NOT NULL
  - `y` INT NOT NULL
  - `item_vnum` INT UNSIGNED NOT NULL
  - `item_uid` INT UNSIGNED NOT NULL
  - `item_count` INT NOT NULL
  - `success` TINYINT UNSIGNED NOT NULL
  - INDEX idx_pid (pid)
  - INDEX idx_time (time)

#### 14. **speed_hack** ⚠️ OPCIONAL
- **Ubicación en código**: `src/game/src/log.cpp:183`
- **Query**: `INSERT INTO speed_hack%s (pid, time, x, y, hack_count)`
- **Quién la crea**: Se crea automáticamente cuando se necesita
- **Columnas necesarias**:
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `pid` INT UNSIGNED NOT NULL
  - `time` DATETIME NOT NULL
  - `x` INT NOT NULL
  - `y` INT NOT NULL
  - `hack_count` INT NOT NULL
  - INDEX idx_pid (pid)
  - INDEX idx_time (time)

#### 15. **change_name** ⚠️ OPCIONAL
- **Ubicación en código**: `src/game/src/log.cpp:190`
- **Query**: `INSERT INTO change_name%s (pid, old_name, new_name, time, ip)`
- **Quién la crea**: Se crea automáticamente cuando se necesita
- **Columnas necesarias**:
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `pid` INT UNSIGNED NOT NULL
  - `old_name` VARCHAR(24) NOT NULL
  - `new_name` VARCHAR(24) NOT NULL
  - `time` DATETIME NOT NULL
  - `ip` VARCHAR(16) NOT NULL
  - INDEX idx_pid (pid)
  - INDEX idx_time (time)

#### 16. **hackshield_log** ⚠️ OPCIONAL
- **Ubicación en código**: `src/game/src/log.cpp:311`
- **Query**: `INSERT INTO hackshield_log(time, account_id, login, pid, name, reason, ip)`
- **Quién la crea**: Se crea automáticamente cuando se necesita
- **Columnas necesarias**:
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `time` DATETIME NOT NULL
  - `account_id` INT UNSIGNED NOT NULL
  - `login` VARCHAR(24) NOT NULL
  - `pid` INT UNSIGNED NOT NULL
  - `name` VARCHAR(24) NOT NULL
  - `reason` INT UNSIGNED NOT NULL
  - `ip` INT UNSIGNED NOT NULL
  - INDEX idx_time (time)
  - INDEX idx_account_id (account_id)

## Nota sobre GetTablePostfix()

Muchas tablas usan `GetTablePostfix()` que agrega un sufijo como `_1`, `_2`, etc. para canales múltiples. Sin embargo, las tablas base deben existir sin sufijo o con sufijo `_1` por defecto.

## Quién Debe Crear Estas Tablas

Según el código fuente:

1. **Tablas CRÍTICAS** (refine_proto, skill_proto, quest_item_proto, item_attr, item_attr_rare, banword, object_proto):
   - **Deben existir ANTES de iniciar el servidor DB**
   - El servidor DB las lee al iniciar en `InitializeTables()`
   - Si no existen, el servidor falla al iniciar
   - **Responsabilidad**: Script de inicialización de base de datos (create-all-tables.sql)

2. **Tablas IMPORTANTES** (guild_comment, hack_log, hack_crc_log):
   - Se usan durante el juego
   - Pueden crearse automáticamente o previamente
   - **Responsabilidad**: Script de inicialización de base de datos

3. **Tablas OPCIONALES** (lotto_list, goldlog, cube, speed_hack, change_name, hackshield_log):
   - Se crean cuando se necesitan
   - Pueden estar vacías inicialmente
   - **Responsabilidad**: Script de inicialización de base de datos (para evitar errores)

## Prioridad de Implementación

1. **ALTA PRIORIDAD** (Servidor no inicia sin ellas):
   - refine_proto
   - skill_proto
   - quest_item_proto
   - item_attr
   - item_attr_rare
   - banword
   - object_proto

2. **MEDIA PRIORIDAD** (Funcionalidad importante):
   - guild_comment
   - hack_log
   - hack_crc_log

3. **BAJA PRIORIDAD** (Funcionalidad opcional):
   - lotto_list
   - goldlog
   - cube
   - speed_hack
   - change_name
   - hackshield_log

