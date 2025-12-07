#!/bin/bash
# Script de diagnóstico final para el problema de LOGIN_BY_KEY

echo "=========================================="
echo "Diagnóstico Final: Problema LOGIN_BY_KEY"
echo "=========================================="
echo ""

if ! docker ps | grep -q "metin2-server"; then
    echo "❌ Contenedor no está corriendo"
    exit 1
fi

echo "═══════════════════════════════════════════"
echo "1. RESUMEN DEL PROBLEMA"
echo "═══════════════════════════════════════════"
echo ""
echo "✅ Login exitoso (AuthLogin result 1)"
echo "✅ Archivos package/ copiados (217 archivos)"
echo "❌ Cliente NO envía LOGIN_BY_KEY después del login"
echo "⚠️ Error GetRelatedMapSDBStreams Failed(none) (no crítico)"
echo ""

echo "═══════════════════════════════════════════"
echo "2. VERIFICANDO FLUJO COMPLETO"
echo "═══════════════════════════════════════════"
echo ""

echo "Último intento de login:"
docker logs --tail 20 metin2-server 2>&1 | grep -E "AuthLogin|GetRelatedMapSDBStreams" | tail -3

echo ""
echo "═══════════════════════════════════════════"
echo "3. POSIBLES CAUSAS"
echo "═══════════════════════════════════════════"
echo ""
echo "El cliente no envía LOGIN_BY_KEY porque:"
echo ""
echo "A) No está recibiendo HEADER_GC_AUTH_SUCCESS correctamente"
echo "   - Problema de cifrado/protocolo"
echo "   - Paquete se pierde en la red"
echo ""
echo "B) El cliente está esperando algo más"
echo "   - Información de mapas (GetRelatedMapSDBStreams)"
echo "   - Clave de cifrado (SendClientPackageCryptKey)"
echo ""
echo "C) Incompatibilidad de versión"
echo "   - Cliente y servidor usan protocolos diferentes"
echo ""

echo "═══════════════════════════════════════════"
echo "4. SOLUCIONES A PROBAR"
echo "═══════════════════════════════════════════"
echo ""
echo "1. Verificar que el cliente esté usando la versión correcta"
echo "2. Verificar logs del cliente (syserr.txt, syslog.txt)"
echo "3. Verificar que no haya errores de SEQUENCE durante el login"
echo "4. Intentar con otro cliente o versión diferente"
echo ""

echo "═══════════════════════════════════════════"
echo "5. MONITOREO EN TIEMPO REAL"
echo "═══════════════════════════════════════════"
echo ""
echo "Ejecuta esto mientras intentas conectarte:"
echo "   docker logs -f metin2-server 2>&1 | grep -v 'item_proto_test\|No test file\|Setting command privilege'"
echo ""
echo "Busca específicamente:"
echo "   - AuthLogin result 1 (login exitoso)"
echo "   - LOGIN_BY_KEY (cliente envía petición)"
echo "   - SEQUENCE mismatch (errores de cifrado)"
echo "   - GetRelatedMapSDBStreams (información de mapas)"
echo ""

