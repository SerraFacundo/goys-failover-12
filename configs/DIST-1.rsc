# DIST-1 - dueno R4
# ===== F1: identidad + IPs =====
/system identity set name=DIST-1
/ip address add address=10.0.0.14/30 interface=ether1 comment=CORE-1
/ip address add address=10.0.0.22/30 interface=ether2 comment=CORE-2
/ip address add address=192.168.10.2/24 interface=ether3 comment=USERS
/ip address add address=192.168.20.2/24 interface=ether4 comment=SERVERS
/interface bridge add name=loopback comment="loopback / router-id"
/ip address add address=10.255.0.4/32 interface=loopback

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

# ===== F2: VRRP v2 con auth AH (F0 2.2 y 3.4) =====
/interface vrrp add name=vrrp10 interface=ether3 vrid=10 version=2 priority=200 authentication=ah password="<K-VRRP-10>"
/interface vrrp add name=vrrp20 interface=ether4 vrid=20 version=2 priority=100 authentication=ah password="<K-VRRP-20>"
/ip address add address=192.168.10.1/32 interface=vrrp10
/ip address add address=192.168.20.1/32 interface=vrrp20

# ===== F2: OSPF area 0 con MD5 (F0 2.4 y 3.4) =====
/routing ospf instance add name=ospf1 version=2 router-id=10.255.0.4
/routing ospf area add name=backbone area-id=0.0.0.0 instance=ospf1
/routing ospf interface-template add area=backbone interfaces=ether1,ether2 type=ptp auth=md5 auth-id=1 auth-key="<K-OSPF-12>"
/routing ospf interface-template add area=backbone interfaces=loopback,ether3,ether4 passive

# ===== F3: firewall input (F0 3.5, ultimo parrafo) =====
# Con authentication=ah el VRRP viaja como IP 51 (AH), no como 112: el filtro va por ipsec-ah.
/ip firewall address-list add list=mgmt address=192.168.20.10
/ip firewall address-list add list=mgmt address=10.255.0.0/24
/ip firewall filter
add chain=input connection-state=established,related action=accept
add chain=input connection-state=invalid action=drop
add chain=input protocol=ospf action=accept
add chain=input protocol=ipsec-ah src-address=192.168.10.3 in-interface=ether3 action=accept comment="VRRP (AH) solo del otro DIST"
add chain=input protocol=ipsec-ah src-address=192.168.20.3 in-interface=ether4 action=accept
add chain=input protocol=ipsec-ah action=drop
add chain=input protocol=tcp dst-port=22 src-address-list=mgmt action=accept
add chain=input protocol=udp dst-port=161 src-address-list=mgmt action=accept
add chain=input protocol=icmp limit=10/1s,20:packet action=accept
add chain=input action=drop comment="drop resto"

# ===== F4: SNMP v3 authPriv (F0 3.3) - LOS 7 ROUTERS (dueno: cada rol) =====
/snmp community set [find name=public] disabled=yes
/snmp community add name=goys12 security=private authentication-protocol=SHA1 encryption-protocol=AES authentication-password="<K-SNMP-AUTH>" encryption-password="<K-SNMP-PRIV>" addresses=192.168.20.10/32,10.255.0.0/24 read-access=yes write-access=no
/snmp set enabled=yes contact="Grupo 12 GOYS" location="GNS3 lab failover" trap-version=3
/snmp set trap-community=goys12

# ===== F4: netwatch - DIST-1 y DIST-2 (dueno R4) =====
/tool netwatch add host=192.168.10.3 type=icmp interval=5s comment=PAR-DIST up-script=":log info \"NETWATCH PAR-DIST up\"" down-script=":log warning \"NETWATCH PAR-DIST down\""
