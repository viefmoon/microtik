# CONFIGURACIÓN SIMPLE - WiFi hAP ax3

## RESET A CONFIGURACIÓN DE FÁBRICA
```bash
# Reset completo a valores de fábrica
/system reset-configuration
# Responder "y"

# El equipo reiniciará con:
# - WiFi por defecto funcionando
# - SSID: MikroTik-XXXXXX (los X son parte del MAC)
# - Sin contraseña
# - IP: 192.168.88.1
```

## CONFIGURACIÓN DESPUÉS DEL RESET
```bash
# Paso 1: Identidad y contraseña admin
/system identity set name="LaLena-Admin"
/user set admin password=LaLenadmin2025

# Paso 2: Zona horaria
/system clock set time-zone-name=America/Mexico_City

# Paso 3: Cambiar nombre del WiFi
/interface wifi set wifi1 configuration.ssid="LaLena-admin"
/interface wifi set wifi2 configuration.ssid="LaLena-admin"

# Paso 4: Poner contraseña al WiFi
/interface wifi set wifi1 security.passphrase="LaLenadmin2025"
/interface wifi set wifi2 security.passphrase="LaLenadmin2025"

# Paso 5: Configurar país para máxima potencia (USA permite más potencia)
/interface wifi configuration set [find default=yes] country="United States"
/interface wifi set wifi1 configuration.country="United States"
/interface wifi set wifi2 configuration.country="United States"

# Paso 6: Reiniciar WiFi para aplicar cambios
/interface wifi disable wifi1,wifi2
/delay 3
/interface wifi enable wifi1,wifi2
```

## OPTIMIZAR DHCP (OPCIONAL)
```bash
# Eliminar pool por defecto
/ip pool remove [find name=default-dhcp]

# Crear pool optimizado
/ip pool add name=pool-admin ranges=192.168.88.10-192.168.88.200

# Actualizar servidor DHCP
/ip dhcp-server set [find interface=bridge] address-pool=pool-admin lease-time=7d name=dhcp-admin

# Guardar leases en disco
/ip dhcp-server config set store-leases-disk=5m
```

## VERIFICACIÓN
```bash
# Ver estado del WiFi
/interface wifi print

# Verificar que esté transmitiendo
/interface wifi monitor wifi1 once
/interface wifi monitor wifi2 once

# Ver dispositivos conectados
/interface wifi registration-table print

# Ver configuración DHCP
/ip dhcp-server print
```

## CONFIGURACIÓN FINAL
- **WiFi SSID**: LaLena-admin
- **Contraseña WiFi**: LaLenadmin2025
- **Contraseña Admin**: LaLenadmin2025
- **Red LAN**: 192.168.88.0/24
- **DHCP**: 192.168.88.10-200 (lease 7 días)
- **País**: United States (máxima potencia)

## NOTA IMPORTANTE
El hAP ax3 ajusta la potencia automáticamente según el país. Con "United States" obtienes:
- 2.4GHz: hasta 27dBm
- 5GHz: hasta 28dBm