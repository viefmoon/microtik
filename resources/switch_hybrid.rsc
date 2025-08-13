###############################################################################
# Topic:		Using RouterOS to VLAN your network
# Example:		Hybrid Ports Example for Switch with a separate router (RoaS)
# Web:			https://forum.mikrotik.com/viewtopic.php?t=143620
# RouterOS:		6.47.10
# Date:			February 17, 2023
# Notes:		Start with a reset (/system reset-configuration)
# Thanks:		mkx, sindy
###############################################################################

#######################################
# Naming
#######################################

# name the device being configured
/system identity set name="SwitchHybrid"


#######################################
# VLAN Overview
#######################################

# 10 = BLUE
# 20 = GREEN
# 30 = RED
# 99 = BASE (MGMT) VLAN


#######################################
# Bridge
#######################################

# create one bridge, set VLAN mode off while we configure
/interface bridge add name=BR1 protocol-mode=none vlan-filtering=no


#######################################
#
# -- Access Ports --
#
#######################################

# ingress behavior
/interface bridge port

# Blue VLAN
add bridge=BR1 interface=ether1 pvid=10
add bridge=BR1 interface=ether2 pvid=10
add bridge=BR1 interface=ether3 pvid=10
add bridge=BR1 interface=ether4 pvid=10
add bridge=BR1 interface=ether5 pvid=10
add bridge=BR1 interface=ether6 pvid=10
add bridge=BR1 interface=ether7 pvid=10
add bridge=BR1 interface=ether8 pvid=10

# Green VLAN
add bridge=BR1 interface=ether9  pvid=20
add bridge=BR1 interface=ether10 pvid=20
add bridge=BR1 interface=ether11 pvid=20
add bridge=BR1 interface=ether12 pvid=20
add bridge=BR1 interface=ether13 pvid=20
add bridge=BR1 interface=ether14 pvid=20
add bridge=BR1 interface=ether15 pvid=20
add bridge=BR1 interface=ether16 pvid=20

# Red VLAN
add bridge=BR1 interface=ether17 pvid=30
add bridge=BR1 interface=ether18 pvid=30
add bridge=BR1 interface=ether19 pvid=30
add bridge=BR1 interface=ether20 pvid=30
add bridge=BR1 interface=ether21 pvid=30
add bridge=BR1 interface=ether22 pvid=30
add bridge=BR1 interface=ether23 pvid=30
add bridge=BR1 interface=ether24 pvid=30

# egress behavior, handled automatically


#######################################
#
# -- Trunk Ports --
#
#######################################

# ingress behavior
/interface bridge port

# Purple Trunk. Leave pvid set to default of 1
add bridge=BR1 interface=sfp1
add bridge=BR1 interface=sfp2

# egress behavior
/interface bridge vlan

# Purple Trunk. L2 switching only, Bridge not needed as tagged member (except BASE_VLAN 99)
add bridge=BR1 tagged=sfp1,sfp2 vlan-ids=10
add bridge=BR1 tagged=sfp1,sfp2 vlan-ids=20
add bridge=BR1 tagged=sfp1,sfp2 vlan-ids=30
add bridge=BR1 tagged=BR1,sfp1,sfp2 vlan-ids=99


#######################################
#
# -- Hybrid Ports --
#
#######################################

# egress behavior
/interface bridge vlan

# Change Blue VLAN ports Hybrid by setting a Green egress on them
set bridge=BR1 tagged=sfp1,sfp2,ether1,ether2,ether3,ether4,ether5,ether6,ether7,ether8 [find vlan-ids=20]


#######################################
# IP Addressing & Routing
#######################################

# LAN facing Switch's IP address on a BASE_VLAN
/interface vlan add interface=BR1 name=BASE_VLAN vlan-id=99
/ip address add address=192.168.0.2/24 interface=BASE_VLAN

# The Router's IP this switch will use
/ip route add distance=1 gateway=192.168.0.1


#######################################
# IP Services
#######################################
# We have a router that will handle this. Nothing to set here.


#######################################
# VLAN Security
#######################################

# Access Ports: Only allow untagged ingress packets
/interface bridge port
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether9]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether10]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether11]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether12]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether13]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether14]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether15]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether16]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether17]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether18]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether19]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether20]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether21]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether22]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether23]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged [find interface=ether24]

# Trunk Ports: Only allow ingress packets WITH tags
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-vlan-tagged [find interface=sfp1]
set bridge=BR1 ingress-filtering=yes frame-types=admit-only-vlan-tagged [find interface=sfp2]

# Hybrid: Set to allow ingress packets with or without tags
# The Ingress-filtering option ensures that only the list of tags we have specified are allowed.
set bridge=BR1 ingress-filtering=yes frame-types=admit-all [find interface=ether1]
set bridge=BR1 ingress-filtering=yes frame-types=admit-all [find interface=ether2]
set bridge=BR1 ingress-filtering=yes frame-types=admit-all [find interface=ether3]
set bridge=BR1 ingress-filtering=yes frame-types=admit-all [find interface=ether4]
set bridge=BR1 ingress-filtering=yes frame-types=admit-all [find interface=ether5]
set bridge=BR1 ingress-filtering=yes frame-types=admit-all [find interface=ether6]
set bridge=BR1 ingress-filtering=yes frame-types=admit-all [find interface=ether7]
set bridge=BR1 ingress-filtering=yes frame-types=admit-all [find interface=ether8]


#######################################
# MAC Server settings
#######################################

# Ensure only visibility and availability from BASE_VLAN, the MGMT network
/interface list add name=BASE
/interface list member add interface=BASE_VLAN list=BASE
/ip neighbor discovery-settings set discover-interface-list=BASE
/tool mac-server mac-winbox set allowed-interface-list=BASE
/tool mac-server set allowed-interface-list=BASE


#######################################
# Turn on VLAN mode
#######################################
/interface bridge set BR1 vlan-filtering=yes


