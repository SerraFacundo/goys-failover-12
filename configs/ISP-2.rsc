# ISP-2 (AS 65002) - dueno R2
# ===== F1: identidad + IPs =====
/system identity set name=ISP-2
/ip address add address=203.0.113.5/30 interface=ether1
/interface bridge add name=loopback comment="loopback / router-id"
/ip address add address=10.255.0.12/32 interface=loopback
/ip address add address=198.51.100.2/32 interface=loopback
/ip address add address=198.51.100.100/32 interface=loopback

# ===== F1: hardening (F0 3.1 y 3.3) =====
# Reemplazar <ADMIN_PASS> y <MONITOR_PASS> antes de pegar. Nunca commitear valores reales.
/user set admin password="<ADMIN_PASS>"
/user add name=monitor group=read password="<MONITOR_PASS>"
/ip service disable telnet,ftp,www,www-ssl,api,api-ssl,winbox,reverse-proxy
/ip service set ssh address=192.168.20.10/32,10.255.0.0/24
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
/ip neighbor discovery-settings set discover-interface-list=none
/tool bandwidth-server set enabled=no
/ip dns set allow-remote-requests=no
/ip dhcp-client remove [find]

# ===== F3: eBGP hacia EDGE con TCP-MD5 =====
/ip firewall address-list add list=bgp-out address=198.51.100.2/32
/ip firewall address-list add list=bgp-out address=198.51.100.100/32
/routing filter rule add chain=from-edge rule="if (dst == 192.168.10.0/24) { accept }"
/routing filter rule add chain=from-edge rule="if (dst == 192.168.20.0/24) { accept }"
/routing filter rule add chain=from-edge rule="reject"
/routing bgp instance add name=bgp1 as=65002 router-id=10.255.0.12
/routing bgp connection add name=EDGE as=65002 instance=bgp1 local.role=ebgp local.address=203.0.113.5 remote.address=203.0.113.6 remote.as=65000 tcp-md5-key="<K-BGP-ISP2>" input.filter=from-edge output.network=bgp-out output.default-originate=always

# ===== F4: SNMP v3 authPriv (F0 3.3) - LOS 7 ROUTERS (dueno: cada rol) =====
/snmp community set [find name=public] disabled=yes
/snmp community add name=goys12 security=private authentication-protocol=SHA1 encryption-protocol=AES authentication-password="<K-SNMP-AUTH>" encryption-password="<K-SNMP-PRIV>" addresses=192.168.20.10/32,10.255.0.0/24 read-access=yes write-access=no
/snmp set enabled=yes contact="Grupo 12 GOYS" location="GNS3 lab failover" trap-version=3

# ===== F4: ruta de vuelta hacia las LANs - ISP-1 e ISP-2 (dueno R1 por rotacion) =====
# Sin BGP el ISP no conoce las LANs. Distancia 30, detras de la ruta BGP (20).
/ip route add dst-address=192.168.10.0/24 gateway=203.0.113.6 distance=30 comment="vuelta LAN USERS"
/ip route add dst-address=192.168.20.0/24 gateway=203.0.113.6 distance=30 comment="vuelta LAN SERVERS"
