# 2026-10-16 00:43:59 by RouterOS 7.23.8
# system id = i2pdENR+lnP
#
/interface bridge add comment="loopback / router-id" name=loopback
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface ethernet set [ find default-name=ether2 ] disable-running-check=no
/interface ethernet set [ find default-name=ether3 ] disable-running-check=no
/interface ethernet set [ find default-name=ether4 ] disable-running-check=no
/interface vrrp add authentication=ah interface=ether3 name=vrrp10 priority=200 version=2 vrid=10
/interface vrrp add authentication=ah interface=ether4 name=vrrp20 version=2 vrid=20
/routing ospf instance add name=ospf1 router-id=10.255.0.4
/routing ospf area add instance=ospf1 name=backbone
/ip neighbor discovery-settings set discover-interface-list=none
/ip address add address=10.0.0.14/30 comment=CORE-1 interface=ether1 network=10.0.0.12
/ip address add address=10.0.0.22/30 comment=CORE-2 interface=ether2 network=10.0.0.20
/ip address add address=192.168.10.2/24 comment=USERS interface=ether3 network=192.168.10.0
/ip address add address=192.168.20.2/24 comment=SERVERS interface=ether4 network=192.168.20.0
/ip address add address=10.255.0.4 interface=loopback network=10.255.0.4
/ip address add address=192.168.10.1 interface=vrrp10 network=192.168.10.1
/ip address add address=192.168.20.1 interface=vrrp20 network=192.168.20.1
/ip firewall address-list add address=192.168.20.10 list=mgmt
/ip firewall address-list add address=10.255.0.0/24 list=mgmt
/ip firewall filter add action=accept chain=input connection-state=established,related
/ip firewall filter add action=drop chain=input connection-state=invalid
/ip firewall filter add action=accept chain=input protocol=ospf
/ip firewall filter add action=accept chain=input comment="VRRP (AH) solo del otro DIST" in-interface=ether3 protocol=ipsec-ah src-address=192.168.10.3
/ip firewall filter add action=accept chain=input in-interface=ether4 protocol=ipsec-ah src-address=192.168.20.3
/ip firewall filter add action=drop chain=input protocol=ipsec-ah
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
/routing ospf interface-template add area=backbone auth=md5 auth-id=1 interfaces=ether1,ether2 type=ptp
/routing ospf interface-template add area=backbone interfaces=loopback,ether3,ether4 passive
/system identity set name=DIST-1
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
