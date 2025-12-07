# Análisis del Problema: Cliente se Queda en "You have been connected to the server"

## Problema Actual

Después de una autenticación exitosa (el cliente recibe "you have been connected to the server"), el cliente se queda atascado y no muestra la lista de personajes.

## Flujo de Login Esperado

1. **Cliente → Game Server**: `HEADER_CG_LOGIN3` (credenciales)
2. **Game Server**: Ejecuta consulta SQL `QID_AUTH_LOGIN` en `metin2_player.account`
3. **Game Server**: `AnalyzeReturnQuery` procesa el resultado
4. **Game Server**: Si éxito, llama a `LoginPrepare`
5. **Game Server**: `LoginPrepare` llama a `SendAuthLogin`
6. **Game Server → DB Server**: `HEADER_GD_AUTH_LOGIN` (paquete)
7. **DB Server**: Procesa `QUERY_AUTH_LOGIN` y responde
8. **DB Server → Game Server**: `HEADER_DG_AUTH_LOGIN` (respuesta con `bResult=1`)
9. **Game Server**: `CInputDB::AuthLogin` recibe la respuesta
10. **Game Server → Cliente**: `HEADER_GC_AUTH_SUCCESS` (éxito de autenticación)
11. **Cliente → Game Server**: `HEADER_CG_LOGIN_BY_KEY` (solicita lista de personajes)
12. **Game Server → DB Server**: `HEADER_GD_LOGIN_BY_KEY`
13. **DB Server → Game Server**: `HEADER_DG_LOGIN_SUCCESS` (con `TAccountTable` que incluye personajes)
14. **Game Server → Cliente**: `HEADER_GC_LOGIN_SUCCESS` (lista de personajes)

## Código Relevante

### 1. `db.cpp:AnalyzeReturnQuery` (línea 253-424)

```cpp
case QID_AUTH_LOGIN:
    // ... validaciones ...
    if (loginStatus && !bNotAvail && ...) {
        // Línea 419: Llama a LoginPrepare
        LoginPrepare(d, pinfo->adwClientKey, aiPremiumTimes);
    }
```

### 2. `db.cpp:LoginPrepare` (línea 204-251)

```cpp
void DBManager::LoginPrepare(LPDESC d, DWORD * pdwClientKey, int * paiPremiumTimes)
{
    // ... crea CLoginData ...
    InsertLoginData(pkLD);
    
    if (*d->GetMatrixCode()) {
        // Envía matriz card
    } else {
        // Línea 249: Llama a SendAuthLogin
        SendAuthLogin(d);
    }
}
```

### 3. `db.cpp:SendAuthLogin` (línea 179-202)

```cpp
void DBManager::SendAuthLogin(LPDESC d)
{
    // ... prepara TPacketGDAuthLogin ...
    // Línea 198: Envía paquete al DB server
    db_clientdesc->DBPacket(HEADER_GD_AUTH_LOGIN, d->GetHandle(), &ptod, sizeof(TPacketGDAuthLogin));
}
```

### 4. `input_db.cpp:AuthLogin` (línea 1697-1730)

```cpp
void CInputDB::AuthLogin(LPDESC d, const char * c_pData)
{
    BYTE bResult = *(BYTE *) c_pData;
    
    if (bResult) {
        // Línea 1717-1718: Envía claves de cifrado
        DESC_MANAGER::instance().SendClientPackageCryptKey(d);
        DESC_MANAGER::instance().SendClientPackageSDBToLoadMap(d, MAPNAME_DEFAULT);
    }
    
    // Línea 1728: Envía HEADER_GC_AUTH_SUCCESS al cliente
    d->Packet(&ptoc, sizeof(TPacketGCAuthSuccess));
    SPDLOG_INFO("AuthLogin result {} key {}", bResult, d->GetLoginKey());
}
```

## Posibles Problemas

### Problema 1: Valores NULL en la Consulta SQL

La consulta SQL espera estos campos en este orden:
1. `password` (requerido, no puede ser NULL)
2. `securitycode` (puede ser NULL)
3. `social_id` (requerido, no puede ser NULL)
4. `id` (requerido, no puede ser NULL)
5. `status` (requerido, no puede ser NULL)
6. `availDt - NOW() > 0` (puede ser NULL)
7. `UNIX_TIMESTAMP(silver_expire)` (puede ser NULL)
8. `UNIX_TIMESTAMP(gold_expire)` (puede ser NULL)
9. `UNIX_TIMESTAMP(safebox_expire)` (puede ser NULL)
10. `UNIX_TIMESTAMP(autoloot_expire)` (puede ser NULL)
11. `UNIX_TIMESTAMP(fish_mind_expire)` (puede ser NULL)
12. `UNIX_TIMESTAMP(marriage_fast_expire)` (puede ser NULL)
13. `UNIX_TIMESTAMP(money_drop_rate_expire)` (puede ser NULL)
14. `UNIX_TIMESTAMP(create_time)` (requerido, no puede ser NULL)

**Solución**: Verificar que todos los campos requeridos no sean NULL y que `create_time` no sea `'0000-00-00 00:00:00'`.

### Problema 2: `db_clientdesc` No Está Conectado

Si `db_clientdesc` no está conectado al DB server, `SendAuthLogin` falla silenciosamente.

**Solución**: Verificar que el game server esté conectado al DB server en el puerto 8888.

### Problema 3: El DB Server No Responde

Si el DB server no responde a `HEADER_GD_AUTH_LOGIN`, el cliente nunca recibe `HEADER_GC_AUTH_SUCCESS`.

**Solución**: Verificar los logs del DB server para ver si está procesando `QUERY_AUTH_LOGIN`.

### Problema 4: El Cliente No Envía `HEADER_CG_LOGIN_BY_KEY`

Después de recibir `HEADER_GC_AUTH_SUCCESS`, el cliente debería enviar `HEADER_CG_LOGIN_BY_KEY` para solicitar la lista de personajes. Si no lo hace, puede ser un problema del cliente.

**Solución**: Verificar los logs del servidor para ver si se recibe `HEADER_CG_LOGIN_BY_KEY`.

### Problema 5: `LoginPrepare` No Se Está Llamando

Si `AnalyzeReturnQuery` no está llegando a la línea 419, `LoginPrepare` nunca se llama.

**Solución**: Verificar los logs para ver si aparece `QID_AUTH_LOGIN: SUCCESS`.

## Diagnóstico

Ejecutar el script `diagnosticar-flujo-login-completo.sh` en el VPS para verificar cada paso del flujo.

## Soluciones Propuestas

### Solución 1: Corregir Valores NULL en la Base de Datos

```sql
-- Asegurar que todos los campos requeridos tengan valores
UPDATE account 
SET 
    social_id = COALESCE(social_id, 'A1'),
    create_time = COALESCE(NULLIF(create_time, '0000-00-00 00:00:00'), NOW())
WHERE login = 'test';
```

### Solución 2: Agregar Logs de Depuración

Agregar más logs en `db.cpp` para rastrear el flujo:
- Después de `LoginPrepare` (línea 419)
- Después de `SendAuthLogin` (línea 199)
- En `AuthLogin` antes de enviar `HEADER_GC_AUTH_SUCCESS` (línea 1728)

### Solución 3: Verificar Conexión al DB Server

Verificar que `db_clientdesc` esté conectado antes de llamar a `SendAuthLogin`.

### Solución 4: Verificar que el Cliente Esté Configurado Correctamente

El cliente debe estar configurado para enviar `HEADER_CG_LOGIN_BY_KEY` después de recibir `HEADER_GC_AUTH_SUCCESS`.

## Próximos Pasos

1. Ejecutar `diagnosticar-flujo-login-completo.sh` en el VPS
2. Revisar los logs del servidor para identificar dónde se interrumpe el flujo
3. Corregir los valores NULL en la base de datos si es necesario
4. Verificar que el DB server esté respondiendo correctamente
5. Agregar logs adicionales si es necesario para rastrear el problema

