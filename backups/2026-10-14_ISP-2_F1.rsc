# 2026-10-14 23:14:28 by RouterOS 7.23.8
# system id = HWf0h4oyolJ
#
/interface bridge add comment="loopback / router-id" name=loopback
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface ethernet set [ find default-name=ether2 ] disable-running-check=no
/interface ethernet set [ find default-name=ether3 ] disable-running-check=no
/interface ethernet set [ find default-name=ether4 ] disable-running-check=no
/ip neighbor discovery-settings set discover-interface-list=none
/ip address add address=203.0.113.5/30 interface=ether1 network=203.0.113.4
/ip address add address=10.255.0.12 interface=loopback network=10.255.0.12
/ip address add address=198.51.100.2 interface=loopback network=198.51.100.2
/ip address add address=198.51.100.100 interface=loopback network=198.51.100.100
/ip service set ftp disabled=yes
/ip service set ssh address=192.168.20.10/32,10.255.0.0/24
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set winbox disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/system identity set name=ISP-2
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
