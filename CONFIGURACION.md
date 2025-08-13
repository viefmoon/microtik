# 📖 GUÍA CONFIGURACIÓN DESDE CERO - LaLena MikroTik
## Punto de partida: Configuración de fábrica con IP 192.168.88.1

## 🔍 ESTADO INICIAL ESPERADO
```
- Bridge: configurado con todos los puertos (ether2-5)
- IP LAN: 192.168.88.1/24 en bridge
- IP WAN: DHCP del ISP (192.168.1.x) en ether1
- WiFi: wifi1 y wifi2 disponibles pero sin configurar
- VLANs: No existen
```

## 🔐 PASO 1: CONFIGURAR CONTRASEÑA ADMIN
```bash
/user set admin password=LaLena2025
```

## 🌐 PASO 2: CREAR VLANs E IPs (GRUPO 1)

### Ejecutar estos 4 comandos juntos (crear VLANs y asignar IPs):
```bash
/interface vlan add interface=bridge name=vlan10-staff vlan-id=10 comment="Red Staff LaLena"
/interface vlan add interface=bridge name=vlan20-clientes vlan-id=20 comment="Red Clientes LaLena"
/ip address add address=192.168.10.1/24 interface=vlan10-staff comment="Gateway Staff"
/ip address add address=192.168.20.1/24 interface=vlan20-clientes comment="Gateway Clientes"
```

### NOTA: La red 192.168.88.x se mantiene para administración (no necesita VLAN)

### Verificar:
```bash
/interface vlan print
/ip address print
```

## 🌍 PASO 3: CONFIGURAR WAN Y DNS (GRUPO 2)

### Ejecutar estos 5 comandos juntos (configurar WAN estática):
```bash
/ip dhcp-client disable [find interface=ether1]
/ip address add address=192.168.1.2/24 interface=ether1 comment="WAN DMZ"
/ip address remove [find dynamic=yes interface=ether1]
/ip dns set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes
/ip route add gateway=192.168.1.254 distance=1 comment="Gateway ISP"
```

### Verificar conectividad:
```bash
/ping 8.8.8.8 count=2
```

## 📊 PASO 4: CONFIGURAR DHCP COMPLETO (GRUPO 3)

### Ejecutar estos 6 comandos juntos (pools, servidores y redes DHCP):
```bash
/ip pool add name=pool-staff ranges=192.168.10.10-192.168.10.200 comment="Pool Staff"
/ip pool add name=pool-clientes ranges=192.168.20.10-192.168.20.200 comment="Pool Clientes"
/ip dhcp-server add name=dhcp-staff interface=vlan10-staff address-pool=pool-staff lease-time=8h disabled=no
/ip dhcp-server add name=dhcp-clientes interface=vlan20-clientes address-pool=pool-clientes lease-time=2h disabled=no
/ip dhcp-server network add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=8.8.8.8,8.8.4.4 comment="Red Staff"
/ip dhcp-server network add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=8.8.8.8,8.8.4.4 comment="Red Clientes"
```

### NOTA: El DHCP original del bridge (192.168.88.x) sigue funcionando para administración

## 🔗 PASO 5: CONFIGURAR NAT (GRUPO 4)

### Ejecutar estos 3 comandos juntos (configurar NAT para todas las redes):
```bash
/ip firewall nat add chain=srcnat src-address=192.168.10.0/24 out-interface=ether1 action=masquerade comment="NAT Staff"
/ip firewall nat add chain=srcnat src-address=192.168.20.0/24 out-interface=ether1 action=masquerade comment="NAT Clientes"
/ip firewall nat add chain=srcnat src-address=192.168.88.0/24 out-interface=ether1 action=masquerade comment="NAT Admin/Bridge"
```

### Verificar:
```bash
/ip firewall nat print
```

## 🔌 PASO 6: ASIGNAR PUERTOS A VLANs (GRUPO 5)

### Ver configuración actual de puertos:
```bash
/interface bridge port print
```

### Ejecutar estos 3 comandos juntos (asignar VLANs a puertos):
```bash
/interface bridge port set [find interface=ether2] pvid=10 comment="Puerto Staff"
/interface bridge port set [find interface=ether3] pvid=10 comment="Puerto Staff"
/interface bridge port set [find interface=ether4] pvid=20 comment="Puerto Clientes"
```

### NOTA: ether5 se mantiene en la red principal 192.168.88.x para administración

## 🌉 PASO 7: CONFIGURAR VLANs EN BRIDGE (GRUPO 6)

### IMPORTANTE: El bridge DEBE estar tagged en todas las VLANs

### Ejecutar estos 2 comandos juntos (configurar VLANs en bridge):
```bash
/interface bridge vlan add bridge=bridge tagged=bridge untagged=ether2,ether3 vlan-ids=10 comment="VLAN Staff"
/interface bridge vlan add bridge=bridge tagged=bridge untagged=ether4 vlan-ids=20 comment="VLAN Clientes"
```

### NOTA: ether5 permanece sin VLAN para acceso administrativo por 192.168.88.1

### Verificar configuración:
```bash
/interface bridge vlan print
```

## 🛡️ PASO 8: FIREWALL BÁSICO

### GRUPO 7 - Reglas INPUT (ejecutar estos 4 comandos juntos):
```bash
/ip firewall filter add chain=input action=accept connection-state=established,related comment="Permitir establecidas"
/ip firewall filter add chain=input action=accept protocol=udp dst-port=53 comment="Permitir DNS"
/ip firewall filter add chain=input action=accept protocol=udp dst-port=67-68 comment="Permitir DHCP"
/ip firewall filter add chain=input action=accept src-address=192.168.88.0/24 comment="Permitir red admin"
```

### GRUPO 8 - Reglas FORWARD permitir Internet (ejecutar estos 4 comandos juntos):
```bash
/ip firewall filter add chain=forward action=accept connection-state=established,related comment="Forward establecidas"
/ip firewall filter add chain=forward action=accept in-interface=vlan10-staff out-interface=ether1 comment="Staff a Internet"
/ip firewall filter add chain=forward action=accept in-interface=vlan20-clientes out-interface=ether1 comment="Clientes a Internet"
/ip firewall filter add chain=forward action=accept src-address=192.168.88.0/24 out-interface=ether1 comment="Admin a Internet"
```

### GRUPO 9 - Bloquear comunicación entre VLANs:
```bash
/ip firewall filter add chain=forward action=drop in-interface=vlan20-clientes out-interface=vlan10-staff comment="Bloquear Clientes->Staff"
```

### NOTA: La red 192.168.88.x (admin) puede acceder a todo

## 🚄 PASO 9: LIMITAR VELOCIDAD RED CLIENTES (GRUPO 10)

### Crear queue para limitar red de clientes a 100Mbps:
```bash
/queue simple add name="Limite-Clientes" target=192.168.20.0/24 max-limit=100M/100M comment="Limite 100Mbps para red clientes"
```

### Verificar:
```bash
/queue simple print
```

### OPCIONAL - Limitar por cliente individual (10Mbps cada uno):
```bash
/queue simple add name="Limite-Por-Cliente" target=192.168.20.0/24 max-limit=10M/10M burst-limit=15M/15M burst-time=10s/10s comment="10Mbps por cliente"
```

## 📡 PASO 10: CONFIGURAR WiFi DUAL - STAFF Y CLIENTES

### IMPORTANTE: Ejecutar DESPUÉS de configurar VLANs y puertos

### Configurar WiFi principal para Staff (método directo más confiable):
```bash
/interface wifi set wifi1 configuration.ssid="LaLena-Staff" security.authentication-types=wpa2-psk security.passphrase="lalenastaff2025" disabled=no
/interface wifi set wifi2 configuration.ssid="LaLena-Staff" security.authentication-types=wpa2-psk security.passphrase="lalenastaff2025" disabled=no
```

### Crear configuración para red Clientes:
```bash
/interface wifi configuration add name=cfg-clientes ssid="LaLena-Clientes" mode=ap comment="Config Clientes"
```

### Crear interfaces virtuales para Clientes:
```bash
/interface wifi add name=wifi1-clientes configuration=cfg-clientes master=wifi1 security.authentication-types=wpa2-psk security.passphrase="pizzatoto123" disabled=no
/interface wifi add name=wifi2-clientes configuration=cfg-clientes master=wifi2 security.authentication-types=wpa2-psk security.passphrase="pizzatoto123" disabled=no
```

### Asignar WiFi al bridge con VLANs correctas (CRÍTICO - verificar PVID):
```bash
/interface bridge port set [find interface=wifi1] pvid=10 comment="WiFi Staff 2.4G"
/interface bridge port set [find interface=wifi2] pvid=10 comment="WiFi Staff 5G"
/interface bridge port add bridge=bridge interface=wifi1-clientes pvid=20 comment="WiFi Clientes 2.4G"
/interface bridge port add bridge=bridge interface=wifi2-clientes pvid=20 comment="WiFi Clientes 5G"
```

### ⚠️ SOLUCIÓN DE PROBLEMAS WiFi:
- Si la contraseña no funciona: Usar método directo con security.passphrase
- Si Staff obtiene IP 192.168.88.x: Verificar que pvid=10 en wifi1/wifi2
- Si Clientes no tiene límite: Verificar que fast-forward=no y fasttrack desactivado

### Actualizar VLANs para incluir interfaces WiFi:
```bash
/interface bridge vlan set [find vlan-ids=10] untagged=ether2,ether3,wifi1,wifi2
/interface bridge vlan set [find vlan-ids=20] untagged=ether4,wifi1-clientes,wifi2-clientes
```

### Verificar configuración WiFi:
```bash
/interface wifi print
/interface bridge port print where interface~"wifi"
/ip dhcp-server lease print
```

### 🎆 RESULTADO ESPERADO:
| Red WiFi | Contraseña | VLAN | Rango IP | Límite |
|----------|------------|------|----------|--------|
| LaLena-Staff | lalenastaff2025 | 10 | 192.168.10.x | Sin límite |
| LaLena-Clientes | pizzatoto123 | 20 | 192.168.20.x | 100Mbps |

## ⚠️ PASO 11: VLAN FILTERING - OPCIONAL (USAR CON PRECAUCIÓN)

**🚨 ADVERTENCIA: Sin vlan-filtering=yes, las VLANs NO funcionan correctamente y todos los puertos dan la misma IP (192.168.88.x)**

### PREPARACIÓN ANTES DE ACTIVAR:

#### 1. Asegurar acceso de emergencia - Configurar puerto ether5 para administración:
```bash
/interface bridge port set [find interface=ether5] frame-types=admit-all ingress-filtering=no
```

#### 2. Verificar que el bridge esté tagged en todas las VLANs:
```bash
/interface bridge vlan print
# Debe mostrar el bridge como "tagged" en VLANs 10, 20
```

#### 3. ACTIVAR VLAN FILTERING (con precaución):
```bash
# Conecta un cable a ether5 ANTES de ejecutar esto
/interface bridge set [find name=bridge] vlan-filtering=yes
```

### SI PIERDES ACCESO:
1. Conecta cable a **ether5** 
2. Configura IP manual: 192.168.88.100
3. Accede a Winbox: 192.168.88.1

### ALTERNATIVA: Si no quieres arriesgarte, usa bridges separados (ver siguiente sección)

## ✅ VERIFICACIÓN FINAL

### Verificar todas las IPs:
```bash
/ip address print
```

### Ver clientes DHCP conectados:
```bash
/ip dhcp-server lease print
```

### Probar conectividad a Internet:
```bash
/ping google.com count=2
```

### Ver logs del sistema:
```bash
/log print
```

## 🆘 RECUPERACIÓN SI ALGO FALLA

### Si pierdes acceso:
1. Conecta cable a **ether5** (puerto administración)
2. Tu PC debería obtener IP automática 192.168.88.x
3. Si no, configura IP manual: 192.168.88.100
4. Máscara: 255.255.255.0
5. Gateway: 192.168.88.1
6. Conecta a Winbox: **192.168.88.1**

### Para desactivar VLAN filtering:
```bash
/interface bridge set [find name=bridge] vlan-filtering=no
```

### Para ver qué está mal:
```bash
/log print where topics~"error|warning"
```

## 📋 RESUMEN DE CONFIGURACIÓN

| VLAN | ID | Red | Gateway | Puertos | Uso |
|------|----|----|---------|---------|-----|
| Staff | 10 | 192.168.10.0/24 | 192.168.10.1 | ether2-3 | Empleados |
| Clientes | 20 | 192.168.20.0/24 | 192.168.20.1 | ether4 | Clientes |
| Admin | - | 192.168.88.0/24 | 192.168.88.1 | ether5, bridge | Administración |

## 📝 NOTAS IMPORTANTES

1. **Siempre mantén acceso por 192.168.88.1** como backup (puerto 5)
2. **Configura DMZ en router ISP** apuntando a 192.168.1.2
3. **El puerto ether1 es WAN** - no lo agregues al bridge
4. **Los comandos están agrupados** - puedes ejecutar cada grupo completo
5. **NO actives vlan-filtering** hasta estar seguro del acceso
6. **El aislamiento se hace con firewall**, no solo con vlan-filtering
7. **CRÍTICO para queues**: Desactivar fast-forward Y fasttrack
8. **WiFi**: Usar método directo con security.passphrase
9. **WiFi PVID**: Verificar que wifi1/wifi2 tengan pvid=10 para Staff
10. **Sin desactivar fast-forward/fasttrack**, los límites NO funcionan

## 🚀 RESUMEN DE GRUPOS DE COMANDOS

| Grupo | Descripción | Comandos | Seguro |
|-------|-------------|----------|--------|
| 1 | Crear VLANs e IPs | 4 | ✅ Sí |
| 2 | WAN y DNS | 5 | ✅ Sí |
| 3 | DHCP completo | 6 | ✅ Sí |
| 4 | NAT | 3 | ✅ Sí |
| 5 | Asignar puertos | 3 | ✅ Sí |
| 6 | VLANs en bridge | 2 | ✅ Sí |
| 7 | Firewall INPUT | 4 | ✅ Sí |
| 8 | Firewall FORWARD | 4 | ✅ Sí |
| 9 | Bloquear VLANs | 1 | ✅ Sí |
| 10 | Limitar velocidad clientes | 3 | ✅ Sí |
| 11 | Configurar WiFi dual | 9 | ✅ Sí |

**Total: 44 comandos en 11 grupos** (más fácil que ejecutar individualmente)