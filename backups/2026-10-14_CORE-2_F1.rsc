# 2026-10-14 23:14:44 by RouterOS 7.23.8
# system id = KTYlB7p1FVA
#
/interface bridge add comment="loopback / router-id" name=loopback
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface ethernet set [ find default-name=ether2 ] disable-running-check=no
/interface ethernet set [ find default-name=ether3 ] disable-running-check=no
/interface ethernet set [ find default-name=ether4 ] disable-running-check=no
/ip neighbor discovery-settings set discover-interface-list=none
/ip address add address=10.0.0.6/30 comment=EDGE interface=ether1 network=10.0.0.4
/ip address add address=10.0.0.10/30 comment=CORE-1 interface=ether2 network=10.0.0.8
/ip address add address=10.0.0.21/30 comment=DIST-1 interface=ether3 network=10.0.0.20
/ip address add address=10.0.0.25/30 comment=DIST-2 interface=ether4 network=10.0.0.24
/ip address add address=10.255.0.3 interface=loopback network=10.255.0.3
/ip service set ftp disabled=yes
/ip service set ssh address=192.168.20.10/32,10.255.0.0/24
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set winbox disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/system identity set name=CORE-2
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
