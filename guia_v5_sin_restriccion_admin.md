# GUÍA DEFINITIVA v5 - MIKROTIK LA LEÑA (SIN RESTRICCIÓN ADMIN)
## Configuración Completa - Ambas Redes con Internet
### RouterOS 7.19.4 - hAP ax³
### ✅ Versión: WiFi Admin CON internet, WiFi Clientes CON internet

---

## 🎯 OBJETIVO FINAL

| Conexión | Red | SSID | Internet | Uso |
|----------|-----|------|----------|-----|
| **ETHERNET (todos)** | 192.168.88.0/24 | - | ✅ SÍ | Servidor + PCs |
| **WiFi INTERNO** | 192.168.88.0/24 | LaLena-Admin | ✅ SÍ | Tablets |
| **WiFi CLIENTES** | 192.168.20.0/24 | LaLena-WiFi | ✅ SÍ | Público |

---

## ⚠️ IMPORTANTE ANTES DE EMPEZAR
- Conecta por **CABLE ETHERNET** durante toda la configuración
- Router con configuración por defecto
- **NO activaremos VLAN filtering** (causa problemas con WiFi)

---

## 📋 CONFIGURACIÓN PASO A PASO

## SECCIÓN 1: CONFIGURACIÓN BÁSICA

```bash
# 1.1 Nombrar router
/system identity set name=LaLena-Router

# 1.2 Zona horaria
/system clock set time-zone-name=America/Mexico_City

# 1.3 NTP
/system ntp client set enabled=yes
/system ntp client servers add address=pool.ntp.org
```

---

## SECCIÓN 2: CONFIGURAR WiFi PRINCIPAL

```bash
# 2.1 IMPORTANTE: Asegurar datapath.bridge primero
/interface wifi set wifi1 datapath.bridge=bridge
/interface wifi set wifi2 datapath.bridge=bridge

# 2.2 Cambiar nombre y contraseña WiFi 5GHz
/interface wifi set wifi1 \
    configuration.ssid="LaLena-Admin" \
    security.authentication-types=wpa2-psk \
    security.passphrase="LaLenadmin2025"

# 2.3 Cambiar nombre y contraseña WiFi 2.4GHz
/interface wifi set wifi2 \
    configuration.ssid="LaLena-Admin" \
    security.authentication-types=wpa2-psk \
    security.passphrase="LaLenadmin2025"

# 2.4 Reiniciar WiFi para aplicar cambios
/interface wifi disable wifi1,wifi2
/delay 2
/interface wifi enable wifi1,wifi2

# 2.5 Verificar que están activos (NO deben mostrar "I")
/interface wifi print
```

---

## SECCIÓN 3: PREPARAR RED DE CLIENTES

```bash
# 3.1 Pool DHCP para clientes
/ip pool add name=pool-clientes ranges=192.168.20.100-192.168.20.250

# 3.2 Red DHCP (se usará más adelante)
/ip dhcp-server network add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=8.8.8.8,8.8.4.4
```

---

## SECCIÓN 4: CREAR BRIDGE Y WiFi PARA CLIENTES

```bash
# 4.1 Crear bridge separado para clientes
/interface bridge add name=bridge-clientes comment="Bridge para red de clientes"

# 4.2 WiFi clientes 2.4GHz en bridge-clientes
/interface wifi add \
    name=wifi-clientes-2g \
    master-interface=wifi2 \
    configuration.ssid="LaLena-WiFi" \
    security.authentication-types=wpa2-psk \
    security.passphrase="lalena2025" \
    datapath.bridge=bridge-clientes \
    disabled=no

# 4.3 WiFi clientes 5GHz en bridge-clientes
/interface wifi add \
    name=wifi-clientes-5g \
    master-interface=wifi1 \
    configuration.ssid="LaLena-WiFi" \
    security.authentication-types=wpa2-psk \
    security.passphrase="lalena2025" \
    datapath.bridge=bridge-clientes \
    disabled=no

# 4.4 Configurar IP en bridge-clientes
/ip address add address=192.168.20.1/24 interface=bridge-clientes comment="Gateway Clientes"

# 4.5 Servidor DHCP para clientes
/ip dhcp-server add name=dhcp-clientes interface=bridge-clientes address-pool=pool-clientes lease-time=2h

# 4.6 Reiniciar todas las WiFi
/interface wifi disable [find]
/delay 2
/interface wifi enable [find]

# 4.7 Verificar (deben ser 4 WiFi activas)
/interface wifi print
```

---

## SECCIÓN 5: CONFIGURAR NAT

```bash
# 5.1 Agregar bridge-clientes a lista LAN
/interface list member add list=LAN interface=bridge-clientes

# 5.2 NAT para clientes
/ip firewall nat add \
    chain=srcnat \
    src-address=192.168.20.0/24 \
    out-interface-list=WAN \
    action=masquerade \
    place-before=0 \
    comment="NAT Clientes"

# 5.3 Verificar orden (NAT Clientes debe estar antes que el NAT general)
/ip firewall nat print
```

---

## SECCIÓN 6: VERIFICAR CONFIGURACIÓN

```bash
# 6.1 Verificar que bridge-clientes existe
/interface bridge print

# 6.2 Verificar que las WiFi están en el bridge correcto
/interface wifi print detail

# 6.3 Verificar IPs configuradas
/ip address print

# 6.4 Verificar DHCP activo
/ip dhcp-server print

# 6.5 Verificar que bridge-clientes está en lista LAN
/interface list member print where list=LAN

# 6.6 Probar conectividad desde router
/ping 8.8.8.8 count=3 interface=bridge-clientes
```

---

## SECCIÓN 7: AISLAR REDES (OPCIONAL - SOLO SEPARACIÓN)

```bash
# 7.1 Clientes no acceden a red interna
/ip firewall filter add \
    chain=forward \
    in-interface=bridge-clientes \
    out-interface=bridge \
    action=drop \
    comment="Aislar clientes de interna"

# 7.2 Red interna no accede a clientes
/ip firewall filter add \
    chain=forward \
    in-interface=bridge \
    out-interface=bridge-clientes \
    action=drop \
    comment="Aislar interna de clientes"
```

---

## SECCIÓN 8: CONFIGURACIONES ADICIONALES

```bash
# 8.1 Ajustar pool DHCP interno
/ip pool set [find name=default-dhcp] ranges=192.168.88.20-192.168.88.254

# 8.2 DNS
/ip dns set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes

# 8.3 IMPORTANTE: Deshabilitar fasttrack para que funcione el límite
/ip firewall filter disable [find where action=fasttrack-connection]

# 8.4 QoS para clientes (límite de velocidad)
/queue simple add name=limite-clientes target=192.168.20.0/24 max-limit=100M/100M comment="100Mbps clientes"

# 8.5 Horarios WiFi clientes (2:00 PM a 11:30 PM)
/system scheduler add \
    name=wifi-on \
    start-time=14:00:00 \
    interval=1d \
    on-event="/interface wifi enable wifi-clientes-2g,wifi-clientes-5g" \
    comment="Encender WiFi clientes a las 2:00 PM"

/system scheduler add \
    name=wifi-off \
    start-time=23:30:00 \
    interval=1d \
    on-event="/interface wifi disable wifi-clientes-2g,wifi-clientes-5g" \
    comment="Apagar WiFi clientes a las 11:30 PM"
```

---

## SECCIÓN 9: ASIGNAR IPs FIJAS (OPCIONAL)

```bash
# 9.1 Ver dispositivos conectados
/ip dhcp-server lease print

# 9.2 Asignar IP fija a computadora Leo
/ip dhcp-server lease add address=192.168.88.191 mac-address=E0:51:D8:1A:43:68 server=defconf comment="Leo - IP Fija"

# 9.3 Hacer el lease estático (permanente)
/ip dhcp-server lease make-static [find mac-address=E0:51:D8:1A:43:68]

# 9.4 IMPORTANTE: Reiniciar el dispositivo
# Después de asignar la IP fija, REINICIA la computadora/dispositivo
# para que tome la nueva IP correctamente

# 9.5 Ejemplo para agregar más IPs fijas
# /ip dhcp-server lease add address=192.168.88.10 mac-address=AA:BB:CC:DD:EE:FF server=defconf comment="Servidor"
# /ip dhcp-server lease make-static [find mac-address=AA:BB:CC:DD:EE:FF]
# Reiniciar el dispositivo
```

---

## SECCIÓN 10: GUARDAR CONFIGURACIÓN

```bash
# 10.1 Backup
/system backup save name=lalena-sin-restriccion

# 10.2 Exportar
/export file=lalena-sin-restriccion
```

---

## ✅ VERIFICACIÓN FINAL

```bash
# Interfaces activas (NO deben mostrar "I" de inactive)
/interface wifi print

# Ver bridges
/interface bridge print

# Ver IPs
/ip address print

# Ver DHCP
/ip dhcp-server print

# Ver firewall
/ip firewall filter print

# Probar internet
/ping 8.8.8.8 count=3

# Ver dispositivos conectados
/interface wifi registration-table print
```

---

## 🧪 PRUEBAS DESDE DISPOSITIVOS

### 1. PC POR ETHERNET:
- ✅ IP: 192.168.88.x
- ✅ Internet: SÍ
- ✅ Ve toda la red

### 2. TABLET EN "LaLena-Admin":
- ✅ IP: 192.168.88.x
- ✅ Internet: SÍ
- ✅ Ve servidor local

### 3. CELULAR EN "LaLena-WiFi":
- ✅ IP: 192.168.20.x
- ✅ Internet: SÍ (limitado 100Mbps)
- ❌ NO ve red interna

---

## 🔴 CAMBIOS CLAVE vs VERSIÓN CON RESTRICCIÓN

1. **SIN VLAN** - Usa bridges separados para mejor compatibilidad
2. **Ambas redes tienen acceso completo a internet**
3. **Mantiene separación entre redes** (clientes no ven red interna)
4. **Conserva límite de velocidad** para red de clientes
5. **Conserva horarios** para WiFi de clientes
6. **Bridge dedicado** para red de clientes (bridge-clientes)

---

## 🆘 SI ALGO FALLA

### WiFi no aparece o está "INACTIVE":
```bash
# Forzar reinicio específico
/interface wifi disable wifi1,wifi2,wifi-clientes-2g,wifi-clientes-5g
/delay 2
/interface wifi enable wifi1,wifi2,wifi-clientes-2g,wifi-clientes-5g

# Verificar datapath
/interface wifi set wifi1 datapath.bridge=bridge
/interface wifi set wifi2 datapath.bridge=bridge
/interface wifi set wifi-clientes-2g datapath.bridge=bridge-clientes
/interface wifi set wifi-clientes-5g datapath.bridge=bridge-clientes
```

### No obtiene IP en red de clientes:
```bash
# Verificar que bridge está correcto
/interface wifi print detail where name~"clientes"

# Verificar DHCP server activo
/ip dhcp-server print

# Ver logs DHCP
/log print where topics~"dhcp"

# Verificar que el bridge tiene IP
/ip address print where interface=bridge-clientes
```

### No hay internet en red de clientes:
```bash
# Verificar NAT
/ip firewall nat print

# Verificar que bridge-clientes está en lista LAN
/interface list member print where list=LAN

# Probar ping desde el router
/ping 8.8.8.8 interface=bridge-clientes count=3
```

### Si necesitas resetear:
```bash
/system reset-configuration no-defaults=no
```

---

## 📊 RESUMEN

Esta configuración garantiza:
- ✅ WiFi SIEMPRE activo (sin VLAN filtering)
- ✅ Ethernet con internet
- ✅ WiFi Admin CON internet
- ✅ WiFi Clientes con internet
- ✅ Redes separadas por bridges
- ✅ Horarios configurables para red de clientes

**Versión:** 5.0 SIN RESTRICCIÓN ADMIN
**Fecha:** Enero 2025
**Router:** MikroTik hAP ax³
**Diferencia principal:** WiFi Admin tiene acceso completo a internet