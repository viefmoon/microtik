# GUÍA DEFINITIVA v5 FINAL - MIKROTIK LA LEÑA
## Configuración Completa Con Firewall Corregido
### RouterOS 7.19.4 - hAP ax³
### ⚠️ Versión corregida: WiFi Admin sin internet, WiFi Clientes con internet

---

## 🎯 OBJETIVO FINAL

| Conexión | Red | SSID | Internet | Uso |
|----------|-----|------|----------|-----|
| **ETHERNET (todos)** | 192.168.88.0/24 | - | ✅ SÍ | Servidor + PCs |
| **WiFi INTERNO** | 192.168.88.0/24 | LaLena-Admin | ❌ NO | Tablets |
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

## SECCIÓN 3: CREAR RED DE CLIENTES

```bash
# 3.1 Crear VLAN 20
/interface vlan add interface=bridge name=vlan20-clientes vlan-id=20 comment="Red WiFi Clientes"

# 3.2 IP para VLAN
/ip address add address=192.168.20.1/24 interface=vlan20-clientes comment="Gateway Clientes"

# 3.3 Pool DHCP
/ip pool add name=pool-clientes ranges=192.168.20.100-192.168.20.250

# 3.4 Servidor DHCP
/ip dhcp-server add name=dhcp-clientes interface=vlan20-clientes address-pool=pool-clientes lease-time=2h

# 3.5 Red DHCP
/ip dhcp-server network add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=8.8.8.8,8.8.4.4
```

---

## SECCIÓN 4: CREAR WiFi PARA CLIENTES (SIMPLIFICADO)

```bash
# 4.1 WiFi clientes 2.4GHz SIN VLAN (por ahora)
/interface wifi add \
    name=wifi-clientes-2g \
    master-interface=wifi2 \
    configuration.ssid="LaLena-WiFi" \
    security.authentication-types=wpa2-psk \
    security.passphrase="lalena2025" \
    datapath.bridge=bridge \
    disabled=no

# 4.2 WiFi clientes 5GHz SIN VLAN (por ahora)
/interface wifi add \
    name=wifi-clientes-5g \
    master-interface=wifi1 \
    configuration.ssid="LaLena-WiFi" \
    security.authentication-types=wpa2-psk \
    security.passphrase="lalena2025" \
    datapath.bridge=bridge \
    disabled=no

# 4.3 Reiniciar todas las WiFi
/interface wifi disable [find]
/delay 2
/interface wifi enable [find]

# 4.4 Verificar (deben ser 4 WiFi activas)
/interface wifi print
```

---

## SECCIÓN 5: CONFIGURAR NAT

```bash
# 5.1 Agregar VLAN a lista LAN
/interface list member add list=LAN interface=vlan20-clientes

# 5.2 NAT para clientes
/ip firewall nat add \
    chain=srcnat \
    src-address=192.168.20.0/24 \
    out-interface-list=WAN \
    action=masquerade \
    place-before=0 \
    comment="NAT Clientes"

# 5.3 Verificar orden
/ip firewall nat print
```

---

## SECCIÓN 6: FIREWALL - BLOQUEAR SOLO WiFi ADMIN (NO CLIENTES)

```bash
# 6.1 IMPORTANTE: No bloqueamos por interfaz maestra porque afecta a clientes
# En su lugar, bloqueamos por subnet pero permitiendo ethernet

# 6.2 Crear lista para dispositivos ethernet
/interface list add name=ETHERNET-PORTS comment="Puertos ethernet con internet"

# 6.3 Agregar puertos ethernet a la lista
/interface list member add list=ETHERNET-PORTS interface=ether2
/interface list member add list=ETHERNET-PORTS interface=ether3
/interface list member add list=ETHERNET-PORTS interface=ether4
/interface list member add list=ETHERNET-PORTS interface=ether5

# 6.4 Permitir ethernet a internet (agregar PRIMERO)
/ip firewall filter add \
    chain=forward \
    in-interface-list=ETHERNET-PORTS \
    out-interface-list=WAN \
    action=accept \
    place-before=[find comment="defconf: drop all from WAN not DSTNATed"] \
    comment="Permitir ethernet a Internet"

# 6.5 Bloquear red .88 (WiFi Admin) pero NO ethernet
/ip firewall filter add \
    chain=forward \
    src-address=192.168.88.0/24 \
    in-interface-list=!ETHERNET-PORTS \
    out-interface-list=WAN \
    action=drop \
    place-before=[find comment="defconf: drop all from WAN not DSTNATed"] \
    comment="Bloquear WiFi Admin a Internet"

# 6.6 Verificar orden (ethernet permitido debe estar ANTES que bloqueo)
/ip firewall filter print
```

---

## SECCIÓN 7: SEPARAR REDES (MÉTODO ALTERNATIVO)

Como no usamos VLAN filtering, separamos las redes de otra forma:

```bash
# 7.1 Mover WiFi clientes a bridge separado
/interface bridge add name=bridge-clientes

# 7.2 Cambiar WiFi clientes al nuevo bridge
/interface wifi set wifi-clientes-2g datapath.bridge=bridge-clientes
/interface wifi set wifi-clientes-5g datapath.bridge=bridge-clientes

# 7.3 Mover VLAN al nuevo bridge
/interface vlan set vlan20-clientes interface=bridge-clientes

# 7.4 Configurar IP en el nuevo bridge
/ip address add address=192.168.20.1/24 interface=bridge-clientes

# 7.5 Ajustar DHCP
/ip dhcp-server set dhcp-clientes interface=bridge-clientes

# 7.6 Agregar nuevo bridge a lista LAN
/interface list member add list=LAN interface=bridge-clientes

# 7.7 Reiniciar WiFi
/interface wifi disable wifi-clientes-2g,wifi-clientes-5g
/delay 2
/interface wifi enable wifi-clientes-2g,wifi-clientes-5g
```

---

## SECCIÓN 8: AISLAR REDES

```bash
# 8.1 Clientes no acceden a red interna
/ip firewall filter add \
    chain=forward \
    in-interface=bridge-clientes \
    out-interface=bridge \
    action=drop \
    comment="Aislar clientes de interna"

# 8.2 Red interna no accede a clientes
/ip firewall filter add \
    chain=forward \
    in-interface=bridge \
    out-interface=bridge-clientes \
    action=drop \
    comment="Aislar interna de clientes"
```

---

## SECCIÓN 9: CONFIGURACIONES ADICIONALES

```bash
# 9.1 Ajustar pool DHCP interno
/ip pool set [find name=default-dhcp] ranges=192.168.88.20-192.168.88.254

# 9.2 DNS
/ip dns set servers=8.8.8.8,8.8.4.4

# 9.3 QoS para clientes
/queue simple add name=limite-clientes target=bridge-clientes max-limit=100M/100M comment="100Mbps clientes"

# 9.4 Horarios WiFi clientes
/system scheduler add \
    name=wifi-on \
    start-time=11:00:00 \
    interval=1d \
    on-event="/interface wifi enable wifi-clientes-2g,wifi-clientes-5g"

/system scheduler add \
    name=wifi-off \
    start-time=23:00:00 \
    interval=1d \
    on-event="/interface wifi disable wifi-clientes-2g,wifi-clientes-5g"
```

---

## SECCIÓN 10: GUARDAR CONFIGURACIÓN

```bash
# 10.1 Backup
/system backup save name=lalena-final

# 10.2 Exportar
/export file=lalena-final
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
- ❌ Internet: NO (bloqueado por firewall)
- ✅ Ve servidor local

### 3. CELULAR EN "LaLena-WiFi":
- ✅ IP: 192.168.20.x
- ✅ Internet: SÍ (limitado 100Mbps)
- ❌ NO ve red interna

---

## 🔴 CAMBIOS CLAVE vs VERSIONES ANTERIORES

1. **NO usamos VLAN filtering** (causaba WiFi inactive)
2. **Configuramos datapath.bridge ANTES** de cambiar SSID
3. **Reiniciamos WiFi después de cada cambio**
4. **Usamos bridge separado** para clientes (más simple)
5. **Bloqueamos por subnet + lista de ethernet** (no por interfaz WiFi maestra)
6. **Límite de velocidad 100Mbps** para red de clientes

---

## 🆘 SI ALGO FALLA

### WiFi no aparece o está "INACTIVE":
```bash
# Forzar reinicio específico
/interface wifi disable wifi1,wifi2
/delay 2
/interface wifi enable wifi1,wifi2

# Verificar datapath
/interface wifi set wifi1 datapath.bridge=bridge
/interface wifi set wifi2 datapath.bridge=bridge
```

### No obtiene IP:
```bash
# Verificar que bridge está correcto
/interface wifi print detail

# Ver logs DHCP
/log print where topics~"dhcp"
```

### Si necesitas resetear:
```bash
/system reset-configuration no-defaults=no
```

---

## 📊 RESUMEN

Esta configuración CORREGIDA garantiza:
- ✅ WiFi SIEMPRE activo (sin VLAN filtering)
- ✅ Ethernet con internet
- ✅ WiFi interno sin internet
- ✅ WiFi clientes con internet
- ✅ Redes separadas por bridges

**Versión:** 5.0 FINAL - FIREWALL CORREGIDO
**Fecha:** Enero 2025
**Router:** MikroTik hAP ax³
**Problemas resueltos:** 
- WiFi inactive por VLAN filtering
- Firewall bloqueando WiFi clientes incorrectamente
- Ahora: Ethernet con internet, WiFi Admin sin internet, WiFi Clientes con internet (100Mbps)