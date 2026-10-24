# EDGE (AS 65000) - dueno R1
# ===== F1: identidad + IPs =====
/system identity set name=EDGE
/ip address add address=203.0.113.2/30 interface=ether1 comment=ISP-1
/ip address add address=203.0.113.6/30 interface=ether2 comment=ISP-2
/ip address add address=10.0.0.1/30 interface=ether3 comment=CORE-1
/ip address add address=10.0.0.5/30 interface=ether4 comment=CORE-2
/interface bridge add name=loopback comment="loopback / router-id"
/ip address add address=10.255.0.1/32 interface=loopback

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

# ===== F2: OSPF area 0 con MD5 (F0 2.4 y 3.4) =====
/routing ospf instance add name=ospf1 version=2 router-id=10.255.0.1 originate-default=if-installed
/routing ospf area add name=backbone area-id=0.0.0.0 instance=ospf1
/routing ospf interface-template add area=backbone interfaces=ether3,ether4 type=ptp auth=md5 auth-id=1 auth-key="<K-OSPF-12>"
/routing ospf interface-template add area=backbone interfaces=loopback passive

# ===== F3: eBGP multi-homing + redistribucion OSPF->BGP (F0 2.5) =====
/routing filter rule
add chain=from-isp1 rule="if (dst == 0.0.0.0/0) { set bgp-local-pref 200; accept }"
add chain=from-isp1 rule="if (dst in 198.51.100.0/24 && dst-len == 32) { set bgp-local-pref 200; accept }"
add chain=from-isp1 rule="reject"
add chain=from-isp2 rule="if (dst == 0.0.0.0/0) { set bgp-local-pref 100; accept }"
add chain=from-isp2 rule="if (dst in 198.51.100.0/24 && dst-len == 32) { set bgp-local-pref 100; accept }"
add chain=from-isp2 rule="reject"
add chain=to-isp rule="if (dst == 192.168.10.0/24) { accept }"
add chain=to-isp rule="if (dst == 192.168.20.0/24) { accept }"
add chain=to-isp rule="reject"
/routing bgp instance add name=bgp1 as=65000 router-id=10.255.0.1
/routing bgp connection
add name=ISP-1 as=65000 instance=bgp1 local.role=ebgp local.address=203.0.113.2 remote.address=203.0.113.1 remote.as=65001 tcp-md5-key="<K-BGP-ISP1>" input.filter=from-isp1 output.redistribute=ospf output.filter-chain=to-isp
add name=ISP-2 as=65000 instance=bgp1 local.role=ebgp local.address=203.0.113.6 remote.address=203.0.113.5 remote.as=65002 tcp-md5-key="<K-BGP-ISP2>" input.filter=from-isp2 output.redistribute=ospf output.filter-chain=to-isp

# ===== F3: firewall EDGE (F0 3.5) =====
/interface list add name=WAN
/interface list member add list=WAN interface=ether1
/interface list member add list=WAN interface=ether2
/ip firewall address-list
add list=mgmt address=192.168.20.10
add list=mgmt address=10.255.0.0/24
add list=bogons address=10.0.0.0/8
add list=bogons address=172.16.0.0/12
add list=bogons address=192.168.0.0/16
add list=bogons address=127.0.0.0/8
add list=bogons address=0.0.0.0/8
add list=lans address=192.168.10.0/24
add list=lans address=192.168.20.0/24
/ip firewall filter
add chain=input connection-state=established,related action=accept comment="in #1"
add chain=input connection-state=invalid action=drop comment="in #2"
add chain=input protocol=tcp dst-port=179 src-address=203.0.113.1 in-interface=ether1 action=accept comment="in #3 BGP ISP-1"
add chain=input protocol=tcp dst-port=179 src-address=203.0.113.5 in-interface=ether2 action=accept comment="in #3 BGP ISP-2"
add chain=input protocol=ospf in-interface=ether3 action=accept comment="in #4"
add chain=input protocol=ospf in-interface=ether4 action=accept comment="in #4"
add chain=input protocol=tcp dst-port=22 src-address-list=mgmt action=accept comment="in #5 ssh"
add chain=input protocol=udp dst-port=161 src-address-list=mgmt action=accept comment="in #5 snmp"
add chain=input protocol=icmp limit=10/1s,20:packet action=accept comment="in #6"
add chain=input action=drop comment="in #7"
add chain=forward connection-state=established,related action=accept comment="fw #1"
add chain=forward connection-state=invalid action=drop comment="fw #2"
add chain=forward in-interface-list=WAN src-address-list=bogons action=drop comment="fw #3 anti-spoofing"
add chain=forward src-address-list=lans out-interface-list=WAN connection-state=new action=accept comment="fw #4"
add chain=forward in-interface-list=WAN protocol=icmp action=accept comment="fw #5"
add chain=forward in-interface-list=WAN action=drop comment="fw #6"

# ===== F4: SNMP v3 authPriv (F0 3.3) - LOS 7 ROUTERS (dueno: cada rol) =====
/snmp community set [find name=public] disabled=yes
/snmp community add name=goys12 security=private authentication-protocol=SHA1 encryption-protocol=AES authentication-password="<K-SNMP-AUTH>" encryption-password="<K-SNMP-PRIV>" addresses=192.168.20.10/32,10.255.0.0/24 read-access=yes write-access=no
/snmp set enabled=yes contact="Grupo 12 GOYS" location="GNS3 lab failover" trap-version=3
/snmp set trap-community=goys12

# ===== F4: netwatch (chequeos activos) - EDGE (dueno R2 por rotacion) =====
/tool netwatch
add host=203.0.113.1 type=icmp interval=5s comment=ISP-1 up-script=":log info \"NETWATCH ISP-1 up\"" down-script=":log warning \"NETWATCH ISP-1 down\""
add host=203.0.113.5 type=icmp interval=5s comment=ISP-2 up-script=":log info \"NETWATCH ISP-2 up\"" down-script=":log warning \"NETWATCH ISP-2 down\""
add host=10.0.0.2 type=icmp interval=5s comment=CORE-1 up-script=":log info \"NETWATCH CORE-1 up\"" down-script=":log warning \"NETWATCH CORE-1 down\""
add host=10.0.0.6 type=icmp interval=5s comment=CORE-2 up-script=":log info \"NETWATCH CORE-2 up\"" down-script=":log warning \"NETWATCH CORE-2 down\""

# ===== F4: floating static con check-gateway - EDGE (dueno R2 por rotacion) =====
# Distancia 30/31: quedan detras de BGP (20). Solo se usan si BGP no aporta default.
/ip route add dst-address=0.0.0.0/0 gateway=203.0.113.1 distance=30 check-gateway=ping comment="chk-ISP1"
/ip route add dst-address=0.0.0.0/0 gateway=203.0.113.5 distance=31 check-gateway=ping comment="chk-ISP2"
