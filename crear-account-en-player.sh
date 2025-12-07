#!/bin/bash
# Script para crear tabla account en metin2_player (solución temporal)
# Uso: bash crear-account-en-player.sh

echo "=========================================="
echo "Crear Tabla Account en metin2_player"
echo "=========================================="
echo ""

cd /opt/metin2omg

echo "1. Verificando si la tabla account existe en metin2_player..."
echo ""

EXISTS=$(mysql -uroot -pproyectalean -Dmetin2_player -e "SHOW TABLES LIKE 'account';" 2>/dev/null | grep -c account)

if [ "$EXISTS" -gt 0 ]; then
    echo "   ⚠️  La tabla account ya existe en metin2_player"
    echo ""
    echo "2. Verificando estructura..."
    mysql -uroot -pproyectalean -Dmetin2_player -e "DESCRIBE account;" 2>/dev/null | head -10
    echo ""
else
    echo "   ✅ La tabla no existe, creándola..."
    echo ""
    
    echo "2. Creando tabla account en metin2_player..."
    echo ""
    
    # Crear la tabla account basada en la estructura de metin2_account
    mysql -uroot -pproyectalean -Dmetin2_player <<EOF
CREATE TABLE IF NOT EXISTS account (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    login VARCHAR(24) NOT NULL,
    password VARCHAR(255) NOT NULL,
    social_id VARCHAR(13) NOT NULL DEFAULT '',
    email VARCHAR(64) NOT NULL DEFAULT '',
    create_time datetime NOT NULL,
    availDt datetime NULL,
    gold_expire INT UNSIGNED NOT NULL DEFAULT 0,
    silver_expire INT UNSIGNED NOT NULL DEFAULT 0,
    safebox_expire INT UNSIGNED NOT NULL DEFAULT 0,
    autoloot_expire INT UNSIGNED NOT NULL DEFAULT 0,
    fish_mind_expire INT UNSIGNED NOT NULL DEFAULT 0,
    marriage_fast_expire INT UNSIGNED NOT NULL DEFAULT 0,
    money_drop_rate_expire INT UNSIGNED NOT NULL DEFAULT 0,
    status VARCHAR(8) NOT NULL DEFAULT 'OK',
    is_testor TINYINT(1) NOT NULL DEFAULT 0,
    securitycode VARCHAR(6) NOT NULL DEFAULT '',
    last_play datetime NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY login (login)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
EOF
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Tabla creada exitosamente"
        echo ""
    else
        echo "   ❌ Error al crear la tabla"
        exit 1
    fi
fi

echo "3. Copiando datos de metin2_account.account a metin2_player.account..."
echo ""

# Copiar la cuenta test
mysql -uroot -pproyectalean -Dmetin2_player <<EOF
INSERT INTO account (login, password, social_id, status, last_play, create_time)
SELECT login, password, social_id, status, last_play, create_time
FROM metin2_account.account
WHERE login='test'
ON DUPLICATE KEY UPDATE 
    password=VALUES(password),
    status=VALUES(status),
    last_play=VALUES(last_play);
EOF

if [ $? -eq 0 ]; then
    echo "   ✅ Datos copiados exitosamente"
    echo ""
    echo "4. Verificando cuenta en metin2_player..."
    mysql -uroot -pproyectalean -Dmetin2_player -e "SELECT login, LEFT(password, 60) as password_preview, status FROM account WHERE login='test';" 2>/dev/null
    echo ""
    echo "=========================================="
    echo "✅ Tabla account creada en metin2_player"
    echo "=========================================="
    echo ""
    echo "Ahora el servidor debería poder autenticar usuarios."
    echo "Reinicia el contenedor si es necesario:"
    echo "   docker restart metin2-server"
    echo ""
else
    echo "   ❌ Error al copiar datos"
    echo ""
    echo "   Intenta manualmente:"
    echo "   mysql -uroot -pproyectalean -Dmetin2_player -e \"INSERT INTO account SELECT * FROM metin2_account.account WHERE login='test' ON DUPLICATE KEY UPDATE password=VALUES(password);\""
fi

echo ""

