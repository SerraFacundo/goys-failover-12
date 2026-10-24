# 2026-10-24 00:01:09 by RouterOS 7.23.8
# system id = koCxSKn9a0I
#
/interface bridge add comment="loopback / router-id" name=loopback
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface ethernet set [ find default-name=ether2 ] disable-running-check=no
/interface ethernet set [ find default-name=ether3 ] disable-running-check=no
/interface ethernet set [ find default-name=ether4 ] disable-running-check=no
/interface list add name=WAN
/routing bgp instance add as=65000 name=bgp1 router-id=10.255.0.1
/routing ospf instance add name=ospf1 originate-default=if-installed router-id=10.255.0.1
/routing ospf area add instance=ospf1 name=backbone
/snmp community set [ find default=yes ] disabled=yes
/snmp community add addresses=192.168.20.10/32,10.255.0.0/24 authentication-protocol=SHA1 encryption-protocol=AES name=goys12 security=private
/ip neighbor discovery-settings set discover-interface-list=none
/interface list member add interface=ether1 list=WAN
/interface list member add interface=ether2 list=WAN
/ip address add address=203.0.113.2/30 comment=ISP-1 interface=ether1 network=203.0.113.0
/ip address add address=203.0.113.6/30 comment=ISP-2 interface=ether2 network=203.0.113.4
/ip address add address=10.0.0.1/30 comment=CORE-1 interface=ether3 network=10.0.0.0
/ip address add address=10.0.0.5/30 comment=CORE-2 interface=ether4 network=10.0.0.4
/ip address add address=10.255.0.1 interface=loopback network=10.255.0.1
/ip firewall address-list add address=192.168.20.10 list=mgmt
/ip firewall address-list add address=10.255.0.0/24 list=mgmt
/ip firewall address-list add address=10.0.0.0/8 list=bogons
/ip firewall address-list add address=172.16.0.0/12 list=bogons
/ip firewall address-list add address=192.168.0.0/16 list=bogons
/ip firewall address-list add address=127.0.0.0/8 list=bogons
/ip firewall address-list add address=0.0.0.0/8 list=bogons
/ip firewall address-list add address=192.168.10.0/24 list=lans
/ip firewall address-list add address=192.168.20.0/24 list=lans
/ip firewall filter add action=accept chain=input comment="in #1" connection-state=established,related
/ip firewall filter add action=drop chain=input comment="in #2" connection-state=invalid
/ip firewall filter add action=accept chain=input comment="in #3 BGP ISP-1" dst-port=179 in-interface=ether1 protocol=tcp src-address=203.0.113.1
/ip firewall filter add action=accept chain=input comment="in #3 BGP ISP-2" dst-port=179 in-interface=ether2 protocol=tcp src-address=203.0.113.5
/ip firewall filter add action=accept chain=input comment="in #4" in-interface=ether3 protocol=ospf
/ip firewall filter add action=accept chain=input comment="in #4" in-interface=ether4 protocol=ospf
/ip firewall filter add action=accept chain=input comment="in #5 ssh" dst-port=22 protocol=tcp src-address-list=mgmt
/ip firewall filter add action=accept chain=input comment="in #5 snmp" dst-port=161 protocol=udp src-address-list=mgmt
/ip firewall filter add action=accept chain=input comment="in #6" limit=10,20:packet protocol=icmp
/ip firewall filter add action=drop chain=input comment="in #7"
/ip firewall filter add action=accept chain=forward comment="fw #1" connection-state=established,related
/ip firewall filter add action=drop chain=forward comment="fw #2" connection-state=invalid
/ip firewall filter add action=drop chain=forward comment="fw #3 anti-spoofing" in-interface-list=WAN src-address-list=bogons
/ip firewall filter add action=accept chain=forward comment="fw #4" connection-state=new out-interface-list=WAN src-address-list=lans
/ip firewall filter add action=accept chain=forward comment="fw #5" in-interface-list=WAN protocol=icmp
/ip firewall filter add action=drop chain=forward comment="fw #6" in-interface-list=WAN
/ip route add check-gateway=ping comment=chk-ISP1 distance=30 dst-address=0.0.0.0/0 gateway=203.0.113.1
/ip route add check-gateway=ping comment=chk-ISP2 distance=31 dst-address=0.0.0.0/0 gateway=203.0.113.5
/ip service set ftp disabled=yes
/ip service set ssh address=192.168.20.10/32,10.255.0.0/24
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set reverse-proxy disabled=yes
/ip service set winbox disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/routing bgp connection add as=65000 input.filter=from-isp1 instance=bgp1 local.address=203.0.113.2 .role=ebgp name=ISP-1 output.filter-chain=to-isp .redistribute=ospf remote.address=203.0.113.1 .as=65001
/routing bgp connection add as=65000 input.filter=from-isp2 instance=bgp1 local.address=203.0.113.6 .role=ebgp name=ISP-2 output.filter-chain=to-isp .redistribute=ospf remote.address=203.0.113.5 .as=65002
/routing filter rule add chain=from-isp1 rule="if (dst == 0.0.0.0/0) { set bgp-local-pref 200; accept }"
/routing filter rule add chain=from-isp1 rule="if (dst in 198.51.100.0/24 && dst-len == 32) { set bgp-local-pref 200; accept }"
/routing filter rule add chain=from-isp1 rule=reject
/routing filter rule add chain=from-isp2 rule="if (dst == 0.0.0.0/0) { set bgp-local-pref 100; accept }"
/routing filter rule add chain=from-isp2 rule="if (dst in 198.51.100.0/24 && dst-len == 32) { set bgp-local-pref 100; accept }"
/routing filter rule add chain=from-isp2 rule=reject
/routing filter rule add chain=to-isp rule="if (dst == 192.168.10.0/24) { accept }"
/routing filter rule add chain=to-isp rule="if (dst == 192.168.20.0/24) { accept }"
/routing filter rule add chain=to-isp rule=reject
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 interfaces=ether3,ether4 type=ptp
/routing ospf interface-template add area=backbone interfaces=loopback passive
/snmp set contact="Grupo 12 GOYS" enabled=yes location="GNS3 lab failover" trap-version=3
/system identity set name=EDGE
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
/tool netwatch add comment=ISP-1 down-script=":log warning \"NETWATCH ISP-1 down\"" host=203.0.113.1 interval=5s type=icmp up-script=":log info \"NETWATCH ISP-1 up\""
/tool netwatch add comment=ISP-2 down-script=":log warning \"NETWATCH ISP-2 down\"" host=203.0.113.5 interval=5s type=icmp up-script=":log info \"NETWATCH ISP-2 up\""
/tool netwatch add comment=CORE-1 down-script=":log warning \"NETWATCH CORE-1 down\"" host=10.0.0.2 interval=5s type=icmp up-script=":log info \"NETWATCH CORE-1 up\""
/tool netwatch add comment=CORE-2 down-script=":log warning \"NETWATCH CORE-2 down\"" host=10.0.0.6 interval=5s type=icmp up-script=":log info \"NETWATCH CORE-2 up\""
