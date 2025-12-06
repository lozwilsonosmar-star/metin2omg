-- ============================================================
-- Script para corregir problemas de inicialización del servidor
-- ============================================================

USE metin2_common;

-- Primero, aumentar el tamaño de la columna mValue si es necesario
ALTER TABLE locale MODIFY COLUMN mValue VARCHAR(255) NOT NULL;

-- Corregir SKILL_POWER_BY_LEVEL: necesita 41 valores (0-40, SKILL_MAX_LEVEL + 1)
-- Actualizar el valor existente con 41 valores
UPDATE locale SET mValue = '0 5 7 9 11 13 15 17 19 20 22 24 26 28 30 32 34 36 38 40 50 52 55 58 61 63 66 69 72 75 80 82 84 87 90 95 100 110 120 130 150' WHERE mKey = 'SKILL_POWER_BY_LEVEL';

-- Si no existe, insertarlo
INSERT IGNORE INTO locale (mValue, mKey) VALUES ('0 5 7 9 11 13 15 17 19 20 22 24 26 28 30 32 34 36 38 40 50 52 55 58 61 63 66 69 72 75 80 82 84 87 90 95 100 110 120 130 150', 'SKILL_POWER_BY_LEVEL');

USE metin2_player;

-- Agregar tienda de ejemplo si no existe ninguna
-- El servidor requiere al menos una tienda para inicializar correctamente
INSERT IGNORE INTO shop (vnum, npc_vnum) VALUES (1, 0);

