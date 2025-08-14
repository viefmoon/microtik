# 🚀 CONFIGURACIÓN SIMPLIFICADA - LaLena MikroTik (2 REDES)
## Configuración con solo 2 redes: Staff y Clientes

## 📋 RESUMEN RÁPIDO
- **2 Redes**: Staff (192.168.88.x) y Clientes (192.168.20.x con horarios)
- **WiFi Dual**: LaLena-Staff (24/7) y LaLena-Clientes (horarios específicos)
- **Horarios Clientes**: Mar-Sab 5PM-12AM, Dom 1PM-12AM, Lun CERRADO
- **WAN**: IP estática 192.168.1.2 (DMZ del ISP)
- **Puertos Ethernet**: TODOS asignados a red Staff (bridge principal)

---

## 🔥 MEGA-BLOQUE 1: CONFIGURACIÓN BASE COMPLETA
### Ejecutar TODO este bloque de una vez (VLAN Clientes + WAN + DNS):
```bash
/user set admin password=LaLena2025
/interface vlan add interface=bridge name=vlan20-clientes vlan-id=20 comment="Red Clientes LaLena"
/ip address add address=192.168.20.1/24 interface=vlan20-clientes comment="Gateway Clientes"
/ip dhcp-client disable [find interface=ether1]
/ip address add address=192.168.1.2/24 interface=ether1 comment="WAN DMZ"
/ip address remove [find dynamic=yes interface=ether1]
/ip dns set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes
/ip route add gateway=192.168.1.254 distance=1 comment="Gateway ISP"
```

---

## 🔥 MEGA-BLOQUE 2: DHCP + NAT COMPLETO
### Ejecutar TODO este bloque de una vez (DHCP para ambas redes + NAT):
```bash
/ip pool add name=pool-staff ranges=192.168.88.10-192.168.88.200 comment="Pool Staff"
/ip pool add name=pool-clientes ranges=192.168.20.10-192.168.20.200 comment="Pool Clientes"
/ip dhcp-server add name=dhcp-staff interface=bridge address-pool=pool-staff lease-time=8h disabled=no
/ip dhcp-server add name=dhcp-clientes interface=vlan20-clientes address-pool=pool-clientes lease-time=2h disabled=no
/ip dhcp-server network add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=8.8.8.8,8.8.4.4 comment="Red Staff/Principal"
/ip dhcp-server network add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=8.8.8.8,8.8.4.4 comment="Red Clientes"
/ip firewall nat add chain=srcnat src-address=192.168.88.0/24 out-interface=ether1 action=masquerade comment="NAT Staff/Principal"
/ip firewall nat add chain=srcnat src-address=192.168.20.0/24 out-interface=ether1 action=masquerade comment="NAT Clientes"
```

---

## 🔥 MEGA-BLOQUE 3: CONFIGURACIÓN BRIDGE Y VLANs
### Ejecutar TODO este bloque de una vez (Solo VLAN para clientes):
```bash
/interface bridge vlan add bridge=bridge tagged=bridge vlan-ids=20 comment="VLAN Clientes"
```
**NOTA**: Todos los puertos ethernet (ether2-ether5) permanecen en el bridge principal (192.168.88.x) para uso de staff

---

## 🔥 MEGA-BLOQUE 4: WiFi DUAL + FIREWALL + LÍMITES
### Ejecutar TODO este bloque de una vez (WiFi completo + seguridad + límites):
```bash
/interface wifi set wifi1 configuration.ssid="LaLena-Staff" security.authentication-types=wpa2-psk security.passphrase="lalenastaff2025" disabled=no
/interface wifi set wifi2 configuration.ssid="LaLena-Staff" security.authentication-types=wpa2-psk security.passphrase="lalenastaff2025" disabled=no
/interface wifi configuration add name=cfg-clientes ssid="LaLena-Clientes" mode=ap comment="Config Clientes"
/interface wifi add name=wifi1-clientes configuration=cfg-clientes master=wifi1 security.authentication-types=wpa2-psk security.passphrase="pizzatoto123" disabled=no
/interface wifi add name=wifi2-clientes configuration=cfg-clientes master=wifi2 security.authentication-types=wpa2-psk security.passphrase="pizzatoto123" disabled=no
/interface bridge port add bridge=bridge interface=wifi1-clientes pvid=20 comment="WiFi Clientes 2.4G"
/interface bridge port add bridge=bridge interface=wifi2-clientes pvid=20 comment="WiFi Clientes 5G"
/interface bridge vlan set [find vlan-ids=20] untagged=wifi1-clientes,wifi2-clientes
/interface bridge set [find name=bridge] fast-forward=no comment="Desactivar fast-forward para que funcionen los límites"
/ip firewall filter add chain=input action=accept connection-state=established,related comment="Permitir establecidas"
/ip firewall filter add chain=input action=accept protocol=udp dst-port=53 comment="Permitir DNS"
/ip firewall filter add chain=input action=accept protocol=udp dst-port=67-68 comment="Permitir DHCP"
/ip firewall filter add chain=input action=accept src-address=192.168.88.0/24 comment="Permitir red staff/admin"
/ip firewall filter add chain=forward action=accept connection-state=established,related comment="Forward establecidas"
/ip firewall filter add chain=forward action=accept src-address=192.168.88.0/24 out-interface=ether1 comment="Staff a Internet"
/ip firewall filter add chain=forward action=accept in-interface=vlan20-clientes out-interface=ether1 comment="Clientes a Internet"
/ip firewall filter add chain=forward action=drop in-interface=vlan20-clientes dst-address=192.168.88.0/24 comment="Bloquear Clientes->Staff"
/ip firewall filter disable [find action=fasttrack-connection]
/queue simple add name="Limite-Clientes" target=192.168.20.0/24 max-limit=300M/300M comment="Limite 300Mbps para red clientes"
```

---

## 🔥 MEGA-BLOQUE 5: HORARIOS RED CLIENTES
### Ejecutar TODO este bloque de una vez (Scripts + Schedulers para horarios):
```bash
/system clock set time-zone-name=America/Mexico_City
/system ntp client set enabled=yes servers=time.google.com,time.cloudflare.com
/system script add name="Activar-Clientes" source={/interface wifi enable [find name~"clientes"]; /log info "Red de clientes ACTIVADA"}
/system script add name="Desactivar-Clientes" source={/interface wifi disable [find name~"clientes"]; /log info "Red de clientes DESACTIVADA"}
/system scheduler add name="Clientes-ON-MarSab" start-time=17:00:00 on-event="Activar-Clientes" interval=1d start-date=jan/01/2025 comment="Activar red clientes Mar-Sab 5PM" policy=read,write,test
/system scheduler add name="Clientes-OFF-MarSab" start-time=00:00:00 on-event="Desactivar-Clientes" interval=1d start-date=jan/01/2025 comment="Desactivar red clientes Mar-Sab 12AM" policy=read,write,test
/system scheduler add name="Clientes-ON-Domingo" start-time=13:00:00 on-event="Activar-Clientes" interval=1w start-date=jan/05/2025 comment="Activar red clientes Domingo 1PM" policy=read,write,test
/system scheduler add name="Clientes-OFF-Domingo" start-time=00:00:00 on-event="Desactivar-Clientes" interval=1w start-date=jan/06/2025 comment="Desactivar red clientes Domingo 12AM" policy=read,write,test
/system scheduler add name="Clientes-OFF-Lunes" start-time=00:01:00 on-event="Desactivar-Clientes" interval=1w start-date=jan/06/2025 comment="Asegurar red clientes OFF los Lunes" policy=read,write,test
```

---

## ⚠️ ACTIVAR VLAN FILTERING (OPCIONAL - ÚLTIMO PASO)
### ⚡ ADVERTENCIA: Asegúrate de tener acceso por cable ethernet ANTES de ejecutar:
```bash
/interface bridge set [find name=bridge] vlan-filtering=yes
```

---

## ✅ COMANDOS DE VERIFICACIÓN
```bash
/ip address print
/ip dhcp-server lease print
/interface wifi print
/system scheduler print
/ping google.com count=2
```

---

## 🔧 COMANDOS ÚTILES

### Forzar estado de red de clientes según horario actual:
```bash
# Desactivar (fuera de horario)
/interface wifi disable [find name~"clientes"]

# Activar (en horario)
/interface wifi enable [find name~"clientes"]
```

### Ver logs del sistema:
```bash
/log print where message~"clientes"
```

---

## 📊 TABLA DE REFERENCIA RÁPIDA

| Red | VLAN | IP Range | Gateway | WiFi SSID | Contraseña | Horario |
|-----|------|----------|---------|-----------|------------|---------|
| Staff/Principal | - | 192.168.88.0/24 | 192.168.88.1 | LaLena-Staff | lalenastaff2025 | 24/7 |
| Clientes | 20 | 192.168.20.0/24 | 192.168.20.1 | LaLena-Clientes | pizzatoto123 | Mar-Sab 5PM-12AM, Dom 1PM-12AM |

| Puerto | VLAN | Uso |
|--------|------|-----|
| ether1 | - | WAN (ISP) |
| ether2 | - | Staff (Bridge principal) |
| ether3 | - | Staff (Bridge principal) |
| ether4 | - | Staff (Bridge principal) |
| ether5 | - | Staff (Bridge principal) |

---

## 🆘 RECUPERACIÓN DE EMERGENCIA
1. Conecta cable a **cualquier puerto ethernet (ether2-ether5)**
2. Configura IP manual: **192.168.88.100**
3. Accede por Winbox: **192.168.88.1**
4. Si necesitas desactivar vlan-filtering:
```bash
/interface bridge set [find name=bridge] vlan-filtering=no
```