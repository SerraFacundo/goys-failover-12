# 2026-10-16 00:43:33 by RouterOS 7.23.8
# system id = oIDiz1vKLnI
#
/interface bridge add comment="loopback / router-id" name=loopback
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface ethernet set [ find default-name=ether2 ] disable-running-check=no
/interface ethernet set [ find default-name=ether3 ] disable-running-check=no
/interface ethernet set [ find default-name=ether4 ] disable-running-check=no
/routing bgp instance add as=65001 name=bgp1 router-id=10.255.0.11
/ip neighbor discovery-settings set discover-interface-list=none
/ip address add address=203.0.113.1/30 interface=ether1 network=203.0.113.0
/ip address add address=10.255.0.11 interface=loopback network=10.255.0.11
/ip address add address=198.51.100.1 interface=loopback network=198.51.100.1
/ip address add address=198.51.100.100 interface=loopback network=198.51.100.100
/ip firewall address-list add address=198.51.100.1 list=bgp-out
/ip firewall address-list add address=198.51.100.100 list=bgp-out
/ip service set ftp disabled=yes
/ip service set ssh address=192.168.20.10/32,10.255.0.0/24
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set reverse-proxy disabled=yes
/ip service set winbox disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/routing bgp connection add as=65001 input.filter=from-edge instance=bgp1 local.address=203.0.113.1 .role=ebgp name=EDGE output.default-originate=always .network=bgp-out remote.address=203.0.113.2 .as=65000
/routing filter rule add chain=from-edge rule="if (dst == 192.168.10.0/24) { accept }"
/routing filter rule add chain=from-edge rule="if (dst == 192.168.20.0/24) { accept }"
/routing filter rule add chain=from-edge rule=reject
/system identity set name=ISP-1
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
