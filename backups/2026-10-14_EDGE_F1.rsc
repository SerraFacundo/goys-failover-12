# 2026-10-14 23:14:34 by RouterOS 7.23.8
# system id = koCxSKn9a0I
#
/interface bridge add comment="loopback / router-id" name=loopback
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface ethernet set [ find default-name=ether2 ] disable-running-check=no
/interface ethernet set [ find default-name=ether3 ] disable-running-check=no
/interface ethernet set [ find default-name=ether4 ] disable-running-check=no
/ip neighbor discovery-settings set discover-interface-list=none
/ip address add address=203.0.113.2/30 comment=ISP-1 interface=ether1 network=203.0.113.0
/ip address add address=203.0.113.6/30 comment=ISP-2 interface=ether2 network=203.0.113.4
/ip address add address=10.0.0.1/30 comment=CORE-1 interface=ether3 network=10.0.0.0
/ip address add address=10.0.0.5/30 comment=CORE-2 interface=ether4 network=10.0.0.4
/ip address add address=10.255.0.1 interface=loopback network=10.255.0.1
/ip service set ftp disabled=yes
/ip service set ssh address=192.168.20.10/32,10.255.0.0/24
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set winbox disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/system identity set name=EDGE
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
