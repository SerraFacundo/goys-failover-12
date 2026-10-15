# ISP-1 (AS 65001) - dueno R2
# ===== F1: identidad + IPs =====
/system identity set name=ISP-1
/ip address add address=203.0.113.1/30 interface=ether1
/interface bridge add name=loopback comment="loopback / router-id"
/ip address add address=10.255.0.11/32 interface=loopback
/ip address add address=198.51.100.1/32 interface=loopback
/ip address add address=198.51.100.100/32 interface=loopback

# ===== F1: hardening (F0 3.1 y 3.3) =====
# Reemplazar <ADMIN_PASS> y <MONITOR_PASS> antes de pegar. Nunca commitear valores reales.
/user set admin password="<ADMIN_PASS>"
/user add name=monitor group=read password="<MONITOR_PASS>"
/ip service disable telnet,ftp,www,www-ssl,api,api-ssl,winbox
/ip service set ssh address=192.168.20.10/32,10.255.0.0/24
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
/ip neighbor discovery-settings set discover-interface-list=none
/tool bandwidth-server set enabled=no
/ip dns set allow-remote-requests=no
/ip dhcp-client remove [find]

# ===== F3: eBGP hacia EDGE con TCP-MD5 =====
/ip firewall address-list add list=bgp-out address=198.51.100.1/32
/ip firewall address-list add list=bgp-out address=198.51.100.100/32
/routing filter rule add chain=from-edge rule="if (dst == 192.168.10.0/24) { accept }"
/routing filter rule add chain=from-edge rule="if (dst == 192.168.20.0/24) { accept }"
/routing filter rule add chain=from-edge rule="reject"
/routing bgp connection add name=EDGE as=65001 router-id=10.255.0.11 local.role=ebgp local.address=203.0.113.1 remote.address=203.0.113.2 remote.as=65000 tcp-md5-key="<K-BGP-ISP1>" input.filter=from-edge output.network=bgp-out output.default-originate=always
