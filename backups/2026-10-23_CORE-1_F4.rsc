# 2026-10-24 00:01:14 by RouterOS 7.23.8
# system id = 2Gaomp2UzNF
#
/interface bridge add comment="loopback / router-id" name=loopback
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface ethernet set [ find default-name=ether2 ] disable-running-check=no
/interface ethernet set [ find default-name=ether3 ] disable-running-check=no
/interface ethernet set [ find default-name=ether4 ] disable-running-check=no
/routing ospf instance add name=ospf1 router-id=10.255.0.2
/routing ospf area add instance=ospf1 name=backbone
/snmp community set [ find default=yes ] disabled=yes
/snmp community add addresses=192.168.20.10/32,10.255.0.0/24 authentication-protocol=SHA1 encryption-protocol=AES name=goys12 security=private
/ip neighbor discovery-settings set discover-interface-list=none
/ip address add address=10.0.0.2/30 comment=EDGE interface=ether1 network=10.0.0.0
/ip address add address=10.0.0.9/30 comment=CORE-2 interface=ether2 network=10.0.0.8
/ip address add address=10.0.0.13/30 comment=DIST-1 interface=ether3 network=10.0.0.12
/ip address add address=10.0.0.17/30 comment=DIST-2 interface=ether4 network=10.0.0.16
/ip address add address=10.255.0.2 interface=loopback network=10.255.0.2
/ip firewall address-list add address=192.168.20.10 list=mgmt
/ip firewall address-list add address=10.255.0.0/24 list=mgmt
/ip firewall filter add action=accept chain=input connection-state=established,related
/ip firewall filter add action=drop chain=input connection-state=invalid
/ip firewall filter add action=accept chain=input protocol=ospf
/ip firewall filter add action=accept chain=input dst-port=22 protocol=tcp src-address-list=mgmt
/ip firewall filter add action=accept chain=input dst-port=161 protocol=udp src-address-list=mgmt
/ip firewall filter add action=accept chain=input limit=10,20:packet protocol=icmp
/ip firewall filter add action=drop chain=input comment="drop resto"
/ip service set ftp disabled=yes
/ip service set ssh address=192.168.20.10/32,10.255.0.0/24
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set reverse-proxy disabled=yes
/ip service set winbox disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 interfaces=ether1,ether2,ether3,ether4 type=ptp
/routing ospf interface-template add area=backbone interfaces=loopback passive
/snmp set contact="Grupo 12 GOYS" enabled=yes location="GNS3 lab failover" trap-version=3
/system identity set name=CORE-1
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
