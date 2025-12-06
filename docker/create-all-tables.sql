-- ============================================================
-- Script SQL para crear todas las tablas necesarias para Metin2 Server
-- Este script crea las tablas básicas en todas las bases de datos
-- ============================================================

-- ============================================================
-- BASE DE DATOS: metin2_account
-- ============================================================
USE metin2_account;

-- Tabla de cuentas
CREATE TABLE IF NOT EXISTS account (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    login VARCHAR(24) NOT NULL UNIQUE,
    passwd VARCHAR(24) NOT NULL,
    social_id VARCHAR(24) NOT NULL DEFAULT '',
    status VARCHAR(8) NOT NULL DEFAULT 'OK',
    empire TINYINT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_login (login)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de índice de jugadores por cuenta
CREATE TABLE IF NOT EXISTS player_index (
    id INT UNSIGNED NOT NULL PRIMARY KEY,
    pid1 INT UNSIGNED NOT NULL DEFAULT 0,
    pid2 INT UNSIGNED NOT NULL DEFAULT 0,
    pid3 INT UNSIGNED NOT NULL DEFAULT 0,
    pid4 INT UNSIGNED NOT NULL DEFAULT 0,
    empire TINYINT UNSIGNED NOT NULL DEFAULT 0,
    FOREIGN KEY (id) REFERENCES account(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- BASE DE DATOS: metin2_common
-- ============================================================
USE metin2_common;

-- Tabla de configuración de locale
CREATE TABLE IF NOT EXISTS locale (
    mValue VARCHAR(16) NOT NULL,
    mKey VARCHAR(32) NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar valores por defecto de locale
INSERT IGNORE INTO locale (mValue, mKey) VALUES ('kr', 'LANGUAGE');
INSERT IGNORE INTO locale (mValue, mKey) VALUES ('korea', 'LOCALE');

-- Tabla de lista de GMs
CREATE TABLE IF NOT EXISTS gmlist (
    mID INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    mAccount VARCHAR(24) NOT NULL,
    mName VARCHAR(24) NOT NULL,
    mContactIP VARCHAR(16) NOT NULL DEFAULT '',
    mServerIP VARCHAR(16) NOT NULL DEFAULT 'ALL',
    mAuthority TINYINT UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de premios de items
CREATE TABLE IF NOT EXISTS item_award (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    login VARCHAR(24) NOT NULL,
    vnum INT UNSIGNED NOT NULL DEFAULT 0,
    socket0 INT UNSIGNED NOT NULL DEFAULT 0,
    socket1 INT UNSIGNED NOT NULL DEFAULT 0,
    socket2 INT UNSIGNED NOT NULL DEFAULT 0,
    mall TINYINT UNSIGNED NOT NULL DEFAULT 0,
    count INT UNSIGNED NOT NULL DEFAULT 1,
    why VARCHAR(255) NOT NULL DEFAULT '',
    given_time DATETIME NOT NULL,
    taken_time DATETIME NULL,
    INDEX idx_login (login),
    INDEX idx_taken_time (taken_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de reservas de guerra de gremios
CREATE TABLE IF NOT EXISTS guild_war_reservation (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    guild1 INT UNSIGNED NOT NULL DEFAULT 0,
    guild2 INT UNSIGNED NOT NULL DEFAULT 0,
    time DATETIME NOT NULL,
    type TINYINT UNSIGNED NOT NULL DEFAULT 0,
    warprice INT UNSIGNED NOT NULL DEFAULT 0,
    initscore INT NOT NULL DEFAULT 0,
    bet_from INT UNSIGNED NOT NULL DEFAULT 0,
    bet_to INT UNSIGNED NOT NULL DEFAULT 0,
    power1 INT UNSIGNED NOT NULL DEFAULT 0,
    power2 INT UNSIGNED NOT NULL DEFAULT 0,
    handicap INT NOT NULL DEFAULT 0,
    started TINYINT UNSIGNED NOT NULL DEFAULT 0,
    winner INT NOT NULL DEFAULT -1,
    INDEX idx_started (started),
    INDEX idx_winner (winner)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de apuestas de guerra de gremios
CREATE TABLE IF NOT EXISTS guild_war_bet (
    war_id INT UNSIGNED NOT NULL,
    login VARCHAR(24) NOT NULL,
    gold INT UNSIGNED NOT NULL DEFAULT 0,
    guild INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (war_id, login),
    INDEX idx_war_id (war_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de monarcas
CREATE TABLE IF NOT EXISTS monarch (
    empire TINYINT UNSIGNED NOT NULL PRIMARY KEY,
    pid INT UNSIGNED NOT NULL DEFAULT 0,
    name VARCHAR(24) NOT NULL DEFAULT '',
    windate DATETIME NOT NULL,
    money BIGINT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de elecciones de monarcas
CREATE TABLE IF NOT EXISTS monarch_election (
    pid INT UNSIGNED NOT NULL,
    selectedpid INT UNSIGNED NOT NULL,
    electiondata DATETIME NOT NULL,
    PRIMARY KEY (pid, selectedpid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de candidatos a monarca
CREATE TABLE IF NOT EXISTS monarch_candidacy (
    pid INT UNSIGNED NOT NULL PRIMARY KEY,
    date DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de matrimonios
CREATE TABLE IF NOT EXISTS marriage (
    pid1 INT UNSIGNED NOT NULL,
    pid2 INT UNSIGNED NOT NULL,
    love_point INT UNSIGNED NOT NULL DEFAULT 0,
    time INT UNSIGNED NOT NULL DEFAULT 0,
    is_married TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (pid1, pid2),
    INDEX idx_is_married (is_married)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de nombres de caballos
CREATE TABLE IF NOT EXISTS horse_name (
    id INT UNSIGNED NOT NULL PRIMARY KEY,
    name VARCHAR(24) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de tierras
CREATE TABLE IF NOT EXISTS land (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    x1 INT NOT NULL DEFAULT 0,
    y1 INT NOT NULL DEFAULT 0,
    x2 INT NOT NULL DEFAULT 0,
    y2 INT NOT NULL DEFAULT 0,
    map_index INT NOT NULL DEFAULT 0,
    guild_id INT UNSIGNED NOT NULL DEFAULT 0,
    enable ENUM('YES', 'NO') NOT NULL DEFAULT 'YES',
    INDEX idx_enable (enable),
    INDEX idx_guild_id (guild_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de objetos en el mundo
CREATE TABLE IF NOT EXISTS object (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    land_id INT UNSIGNED NOT NULL DEFAULT 0,
    vnum INT UNSIGNED NOT NULL DEFAULT 0,
    map_index INT NOT NULL DEFAULT 0,
    x INT NOT NULL DEFAULT 0,
    y INT NOT NULL DEFAULT 0,
    x_rot FLOAT NOT NULL DEFAULT 0.0,
    y_rot FLOAT NOT NULL DEFAULT 0.0,
    z_rot FLOAT NOT NULL DEFAULT 0.0,
    INDEX idx_land_id (land_id),
    INDEX idx_map_index (map_index)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- BASE DE DATOS: metin2_player
-- ============================================================
USE metin2_player;

-- Tabla de jugadores
CREATE TABLE IF NOT EXISTS player (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    account_id INT UNSIGNED NOT NULL DEFAULT 0,
    name VARCHAR(24) NOT NULL UNIQUE,
    job SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    voice TINYINT UNSIGNED NOT NULL DEFAULT 0,
    dir TINYINT UNSIGNED NOT NULL DEFAULT 0,
    x INT NOT NULL DEFAULT 0,
    y INT NOT NULL DEFAULT 0,
    z INT NOT NULL DEFAULT 0,
    map_index INT NOT NULL DEFAULT 0,
    exit_x INT NOT NULL DEFAULT 0,
    exit_y INT NOT NULL DEFAULT 0,
    exit_map_index INT NOT NULL DEFAULT 0,
    hp SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    mp SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    stamina SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    random_hp SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    random_sp SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    playtime INT UNSIGNED NOT NULL DEFAULT 0,
    gold INT NOT NULL DEFAULT 0,
    level TINYINT UNSIGNED NOT NULL DEFAULT 1,
    level_step TINYINT UNSIGNED NOT NULL DEFAULT 0,
    st SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    ht SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    dx SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    iq SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    exp BIGINT UNSIGNED NOT NULL DEFAULT 0,
    stat_point SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    skill_point SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    sub_skill_point SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    stat_reset_count SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    ip VARCHAR(16) NOT NULL DEFAULT '',
    part_base TINYINT UNSIGNED NOT NULL DEFAULT 0,
    part_hair SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    last_play DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    skill_group TINYINT UNSIGNED NOT NULL DEFAULT 0,
    alignment INT NOT NULL DEFAULT 0,
    horse_level TINYINT UNSIGNED NOT NULL DEFAULT 0,
    horse_riding TINYINT UNSIGNED NOT NULL DEFAULT 0,
    horse_hp SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    horse_hp_droptime INT UNSIGNED NOT NULL DEFAULT 0,
    horse_stamina SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    horse_skill_point SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    skill_level BLOB,
    quickslot BLOB,
    change_name TINYINT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_account_id (account_id),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de jugadores eliminados (backup)
CREATE TABLE IF NOT EXISTS player_deleted LIKE player;

-- Tabla de items de jugadores
CREATE TABLE IF NOT EXISTS item (
    id INT UNSIGNED NOT NULL PRIMARY KEY,
    owner_id INT UNSIGNED NOT NULL,
    `window` TINYINT UNSIGNED NOT NULL,
    pos SMALLINT UNSIGNED NOT NULL,
    count INT UNSIGNED NOT NULL DEFAULT 1,
    vnum INT UNSIGNED NOT NULL,
    socket0 INT NOT NULL DEFAULT 0,
    socket1 INT NOT NULL DEFAULT 0,
    socket2 INT NOT NULL DEFAULT 0,
    attrtype0 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    attrvalue0 SMALLINT NOT NULL DEFAULT 0,
    attrtype1 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    attrvalue1 SMALLINT NOT NULL DEFAULT 0,
    attrtype2 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    attrvalue2 SMALLINT NOT NULL DEFAULT 0,
    attrtype3 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    attrvalue3 SMALLINT NOT NULL DEFAULT 0,
    attrtype4 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    attrvalue4 SMALLINT NOT NULL DEFAULT 0,
    attrtype5 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    attrvalue5 SMALLINT NOT NULL DEFAULT 0,
    attrtype6 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    attrvalue6 SMALLINT NOT NULL DEFAULT 0,
    INDEX idx_owner_id (owner_id),
    INDEX idx_vnum (vnum)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de quests de jugadores
CREATE TABLE IF NOT EXISTS quest (
    dwPID INT UNSIGNED NOT NULL,
    szName VARCHAR(64) NOT NULL,
    szState VARCHAR(64) NOT NULL DEFAULT '',
    lValue INT NOT NULL DEFAULT 0,
    PRIMARY KEY (dwPID, szName, szState),
    INDEX idx_dwPID (dwPID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de efectos/buffs de jugadores
CREATE TABLE IF NOT EXISTS affect (
    dwPID INT UNSIGNED NOT NULL,
    bType TINYINT UNSIGNED NOT NULL,
    bApplyOn TINYINT UNSIGNED NOT NULL,
    lApplyValue INT NOT NULL DEFAULT 0,
    dwFlag INT UNSIGNED NOT NULL DEFAULT 0,
    lDuration INT NOT NULL DEFAULT 0,
    lSPCost INT NOT NULL DEFAULT 0,
    PRIMARY KEY (dwPID, bType, bApplyOn),
    INDEX idx_dwPID (dwPID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de cajas fuertes
CREATE TABLE IF NOT EXISTS safebox (
    account_id INT UNSIGNED NOT NULL PRIMARY KEY,
    size TINYINT UNSIGNED NOT NULL DEFAULT 0,
    password VARCHAR(6) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de gremios
CREATE TABLE IF NOT EXISTS guild (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(24) NOT NULL UNIQUE,
    ladder_point INT NOT NULL DEFAULT 0,
    win INT UNSIGNED NOT NULL DEFAULT 0,
    draw INT UNSIGNED NOT NULL DEFAULT 0,
    loss INT UNSIGNED NOT NULL DEFAULT 0,
    gold INT UNSIGNED NOT NULL DEFAULT 0,
    level TINYINT UNSIGNED NOT NULL DEFAULT 1,
    INDEX idx_name (name),
    INDEX idx_ladder_point (ladder_point)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de miembros de gremios
CREATE TABLE IF NOT EXISTS guild_member (
    pid INT UNSIGNED NOT NULL PRIMARY KEY,
    guild_id INT UNSIGNED NOT NULL DEFAULT 0,
    grade TINYINT UNSIGNED NOT NULL DEFAULT 0,
    is_general TINYINT UNSIGNED NOT NULL DEFAULT 0,
    offer INT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_guild_id (guild_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de listas de precios de tiendas personales
CREATE TABLE IF NOT EXISTS myshop_pricelist (
    owner_id INT UNSIGNED NOT NULL,
    item_vnum INT UNSIGNED NOT NULL,
    price INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (owner_id, item_vnum),
    INDEX idx_owner_id (owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de lista de mensajeros
CREATE TABLE IF NOT EXISTS messenger_list (
    account VARCHAR(24) NOT NULL,
    companion VARCHAR(24) NOT NULL,
    PRIMARY KEY (account, companion),
    INDEX idx_account (account),
    INDEX idx_companion (companion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de prototipos de items (item_proto)
-- Esta tabla almacena los datos de item_proto.txt
CREATE TABLE IF NOT EXISTS item_proto (
    vnum INT UNSIGNED NOT NULL PRIMARY KEY,
    type TINYINT UNSIGNED NOT NULL DEFAULT 0,
    subtype TINYINT UNSIGNED NOT NULL DEFAULT 0,
    name VARCHAR(64) NOT NULL DEFAULT '',
    locale_name VARCHAR(64) NOT NULL DEFAULT '',
    gold INT UNSIGNED NOT NULL DEFAULT 0,
    shop_buy_price INT UNSIGNED NOT NULL DEFAULT 0,
    weight TINYINT UNSIGNED NOT NULL DEFAULT 0,
    size TINYINT UNSIGNED NOT NULL DEFAULT 0,
    flag INT UNSIGNED NOT NULL DEFAULT 0,
    wearflag INT UNSIGNED NOT NULL DEFAULT 0,
    antiflag INT UNSIGNED NOT NULL DEFAULT 0,
    immuneflag INT UNSIGNED NOT NULL DEFAULT 0,
    refined_vnum INT UNSIGNED NOT NULL DEFAULT 0,
    refine_set SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    magic_pct TINYINT UNSIGNED NOT NULL DEFAULT 0,
    socket_pct TINYINT UNSIGNED NOT NULL DEFAULT 0,
    addon_type SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    limittype0 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    limitvalue0 INT NOT NULL DEFAULT 0,
    limittype1 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    limitvalue1 INT NOT NULL DEFAULT 0,
    applytype0 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    applyvalue0 SMALLINT NOT NULL DEFAULT 0,
    applytype1 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    applyvalue1 SMALLINT NOT NULL DEFAULT 0,
    applytype2 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    applyvalue2 SMALLINT NOT NULL DEFAULT 0,
    value0 INT NOT NULL DEFAULT 0,
    value1 INT NOT NULL DEFAULT 0,
    value2 INT NOT NULL DEFAULT 0,
    value3 INT NOT NULL DEFAULT 0,
    value4 INT NOT NULL DEFAULT 0,
    value5 INT NOT NULL DEFAULT 0,
    INDEX idx_type (type),
    INDEX idx_subtype (subtype)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de prototipos de monstruos (mob_proto)
-- Esta tabla almacena los datos de mob_proto.txt
CREATE TABLE IF NOT EXISTS mob_proto (
    vnum INT UNSIGNED NOT NULL PRIMARY KEY,
    name VARCHAR(64) NOT NULL DEFAULT '',
    locale_name VARCHAR(64) NOT NULL DEFAULT '',
    type TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `rank` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    battle_type TINYINT UNSIGNED NOT NULL DEFAULT 0,
    level TINYINT UNSIGNED NOT NULL DEFAULT 0,
    size TINYINT UNSIGNED NOT NULL DEFAULT 0,
    ai_flag INT UNSIGNED NOT NULL DEFAULT 0,
    setRaceFlag INT UNSIGNED NOT NULL DEFAULT 0,
    setImmuneFlag INT UNSIGNED NOT NULL DEFAULT 0,
    on_click TINYINT UNSIGNED NOT NULL DEFAULT 0,
    empire TINYINT UNSIGNED NOT NULL DEFAULT 0,
    drop_item INT UNSIGNED NOT NULL DEFAULT 0,
    resurrection_vnum INT UNSIGNED NOT NULL DEFAULT 0,
    folder VARCHAR(64) NOT NULL DEFAULT '',
    st TINYINT UNSIGNED NOT NULL DEFAULT 0,
    dx TINYINT UNSIGNED NOT NULL DEFAULT 0,
    ht TINYINT UNSIGNED NOT NULL DEFAULT 0,
    iq TINYINT UNSIGNED NOT NULL DEFAULT 0,
    damage_min INT UNSIGNED NOT NULL DEFAULT 0,
    damage_max INT UNSIGNED NOT NULL DEFAULT 0,
    max_hp INT UNSIGNED NOT NULL DEFAULT 0,
    regen_cycle TINYINT UNSIGNED NOT NULL DEFAULT 0,
    regen_percent TINYINT UNSIGNED NOT NULL DEFAULT 0,
    exp INT UNSIGNED NOT NULL DEFAULT 0,
    gold_min INT UNSIGNED NOT NULL DEFAULT 0,
    gold_max INT UNSIGNED NOT NULL DEFAULT 0,
    def SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    attack_speed SMALLINT NOT NULL DEFAULT 0,
    move_speed SMALLINT NOT NULL DEFAULT 0,
    aggressive_hp_pct TINYINT UNSIGNED NOT NULL DEFAULT 0,
    aggressive_sight SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    attack_range SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    polymorph_item INT UNSIGNED NOT NULL DEFAULT 0,
    enchant_curse TINYINT NOT NULL DEFAULT 0,
    enchant_slow TINYINT NOT NULL DEFAULT 0,
    enchant_poison TINYINT NOT NULL DEFAULT 0,
    enchant_stun TINYINT NOT NULL DEFAULT 0,
    enchant_critical TINYINT NOT NULL DEFAULT 0,
    enchant_penetrate TINYINT NOT NULL DEFAULT 0,
    resist_sword TINYINT NOT NULL DEFAULT 0,
    resist_twohand TINYINT NOT NULL DEFAULT 0,
    resist_dagger TINYINT NOT NULL DEFAULT 0,
    resist_bell TINYINT NOT NULL DEFAULT 0,
    resist_fan TINYINT NOT NULL DEFAULT 0,
    resist_bow TINYINT NOT NULL DEFAULT 0,
    resist_fire TINYINT NOT NULL DEFAULT 0,
    resist_elect TINYINT NOT NULL DEFAULT 0,
    resist_magic TINYINT NOT NULL DEFAULT 0,
    resist_wind TINYINT NOT NULL DEFAULT 0,
    resist_poison TINYINT NOT NULL DEFAULT 0,
    dam_multiply FLOAT NOT NULL DEFAULT 1.0,
    summon INT UNSIGNED NOT NULL DEFAULT 0,
    drain_sp INT UNSIGNED NOT NULL DEFAULT 0,
    skill_vnum0 INT UNSIGNED NOT NULL DEFAULT 0,
    skill_level0 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    skill_vnum1 INT UNSIGNED NOT NULL DEFAULT 0,
    skill_level1 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    skill_vnum2 INT UNSIGNED NOT NULL DEFAULT 0,
    skill_level2 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    skill_vnum3 INT UNSIGNED NOT NULL DEFAULT 0,
    skill_level3 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    skill_vnum4 INT UNSIGNED NOT NULL DEFAULT 0,
    skill_level4 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    sp_berserk TINYINT UNSIGNED NOT NULL DEFAULT 0,
    sp_stoneskin TINYINT UNSIGNED NOT NULL DEFAULT 0,
    sp_godspeed TINYINT UNSIGNED NOT NULL DEFAULT 0,
    sp_deathblow TINYINT UNSIGNED NOT NULL DEFAULT 0,
    sp_revive TINYINT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_type (type),
    INDEX idx_level (level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- BASE DE DATOS: metin2_log
-- ============================================================
USE metin2_log;

-- Tabla de logs generales
CREATE TABLE IF NOT EXISTS log (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(16) NOT NULL,
    time DATETIME NOT NULL,
    who INT UNSIGNED NOT NULL DEFAULT 0,
    x INT NOT NULL DEFAULT 0,
    y INT NOT NULL DEFAULT 0,
    what INT UNSIGNED NOT NULL DEFAULT 0,
    how VARCHAR(255) NOT NULL DEFAULT '',
    hint TEXT,
    ip VARCHAR(16) NOT NULL DEFAULT '',
    vnum INT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_type (type),
    INDEX idx_time (time),
    INDEX idx_who (who)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de login
CREATE TABLE IF NOT EXISTS loginlog (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(8) NOT NULL,
    time DATETIME NOT NULL,
    channel TINYINT UNSIGNED NOT NULL DEFAULT 0,
    account_id INT UNSIGNED NOT NULL DEFAULT 0,
    pid INT UNSIGNED NOT NULL DEFAULT 0,
    level TINYINT UNSIGNED NOT NULL DEFAULT 0,
    job SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    playtime INT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_time (time),
    INDEX idx_account_id (account_id),
    INDEX idx_pid (pid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de login detallados
CREATE TABLE IF NOT EXISTS loginlog2 (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(16) NOT NULL DEFAULT 'INVALID',
    is_gm ENUM('Y', 'N') NOT NULL DEFAULT 'N',
    login_time DATETIME NOT NULL,
    logout_time DATETIME NULL,
    playtime TIME NULL,
    channel TINYINT UNSIGNED NOT NULL DEFAULT 0,
    account_id INT UNSIGNED NOT NULL DEFAULT 0,
    pid INT UNSIGNED NOT NULL DEFAULT 0,
    ip INT UNSIGNED NOT NULL DEFAULT 0,
    client_version VARCHAR(32) NOT NULL DEFAULT '',
    INDEX idx_account_id (account_id),
    INDEX idx_pid (pid),
    INDEX idx_login_time (login_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de dinero
CREATE TABLE IF NOT EXISTS money_log (
    time DATETIME NOT NULL,
    type TINYINT UNSIGNED NOT NULL,
    vnum INT UNSIGNED NOT NULL DEFAULT 0,
    gold INT NOT NULL DEFAULT 0,
    INDEX idx_time (time),
    INDEX idx_type (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de comandos GM
CREATE TABLE IF NOT EXISTS command_log (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    userid INT UNSIGNED NOT NULL DEFAULT 0,
    server INT UNSIGNED NOT NULL DEFAULT 0,
    ip VARCHAR(16) NOT NULL DEFAULT '',
    port INT UNSIGNED NOT NULL DEFAULT 0,
    username VARCHAR(24) NOT NULL DEFAULT '',
    command TEXT NOT NULL,
    date DATETIME NOT NULL,
    INDEX idx_userid (userid),
    INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de refinamiento
CREATE TABLE IF NOT EXISTS refinelog (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    pid INT UNSIGNED NOT NULL DEFAULT 0,
    item_name VARCHAR(64) NOT NULL DEFAULT '',
    item_id INT UNSIGNED NOT NULL DEFAULT 0,
    step TINYINT UNSIGNED NOT NULL DEFAULT 0,
    time DATETIME NOT NULL,
    is_success TINYINT UNSIGNED NOT NULL DEFAULT 0,
    setType VARCHAR(32) NOT NULL DEFAULT '',
    INDEX idx_pid (pid),
    INDEX idx_time (time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de gritos
CREATE TABLE IF NOT EXISTS shout_log (
    time DATETIME NOT NULL,
    channel TINYINT UNSIGNED NOT NULL DEFAULT 0,
    empire TINYINT UNSIGNED NOT NULL DEFAULT 0,
    message TEXT NOT NULL,
    INDEX idx_time (time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de nivel
CREATE TABLE IF NOT EXISTS levellog (
    name VARCHAR(24) NOT NULL,
    level TINYINT UNSIGNED NOT NULL,
    time DATETIME NOT NULL,
    account_id INT UNSIGNED NOT NULL DEFAULT 0,
    pid INT UNSIGNED NOT NULL DEFAULT 0,
    playtime INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (name, level, time),
    INDEX idx_pid (pid),
    INDEX idx_time (time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de arranque
CREATE TABLE IF NOT EXISTS bootlog (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    time DATETIME NOT NULL,
    hostname VARCHAR(64) NOT NULL DEFAULT '',
    channel TINYINT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_time (time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de pesca
CREATE TABLE IF NOT EXISTS fish_log (
    time DATETIME NOT NULL,
    pid INT UNSIGNED NOT NULL DEFAULT 0,
    prob_idx TINYINT UNSIGNED NOT NULL DEFAULT 0,
    fish_id INT UNSIGNED NOT NULL DEFAULT 0,
    fish_level TINYINT UNSIGNED NOT NULL DEFAULT 0,
    dwMiliseconds INT UNSIGNED NOT NULL DEFAULT 0,
    dwVnum INT UNSIGNED NOT NULL DEFAULT 0,
    dwValue INT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_pid (pid),
    INDEX idx_time (time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de recompensas de quests
CREATE TABLE IF NOT EXISTS quest_reward_log (
    quest_name VARCHAR(64) NOT NULL,
    pid INT UNSIGNED NOT NULL DEFAULT 0,
    level TINYINT UNSIGNED NOT NULL DEFAULT 0,
    item_count TINYINT UNSIGNED NOT NULL DEFAULT 0,
    vnum1 INT UNSIGNED NOT NULL DEFAULT 0,
    vnum2 INT UNSIGNED NOT NULL DEFAULT 0,
    time DATETIME NOT NULL,
    INDEX idx_pid (pid),
    INDEX idx_time (time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de matanza de dragones
CREATE TABLE IF NOT EXISTS dragon_slay_log (
    guild_id INT UNSIGNED NOT NULL DEFAULT 0,
    dragon_vnum INT UNSIGNED NOT NULL DEFAULT 0,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    INDEX idx_guild_id (guild_id),
    INDEX idx_start_time (start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

