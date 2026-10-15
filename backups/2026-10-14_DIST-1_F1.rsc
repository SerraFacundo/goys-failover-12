# 2026-10-14 23:14:49 by RouterOS 7.23.8
# system id = aLK0CNpkqfJ
#
/interface bridge add comment="loopback / router-id" name=loopback
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface ethernet set [ find default-name=ether2 ] disable-running-check=no
/interface ethernet set [ find default-name=ether3 ] disable-running-check=no
/interface ethernet set [ find default-name=ether4 ] disable-running-check=no
/ip neighbor discovery-settings set discover-interface-list=none
/ip address add address=10.0.0.14/30 comment=CORE-1 interface=ether1 network=10.0.0.12
/ip address add address=10.0.0.22/30 comment=CORE-2 interface=ether2 network=10.0.0.20
/ip address add address=192.168.10.2/24 comment=USERS interface=ether3 network=192.168.10.0
/ip address add address=192.168.20.2/24 comment=SERVERS interface=ether4 network=192.168.20.0
/ip address add address=10.255.0.4 interface=loopback network=10.255.0.4
/ip service set ftp disabled=yes
/ip service set ssh address=192.168.20.10/32,10.255.0.0/24
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set winbox disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/system identity set name=DIST-1
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
