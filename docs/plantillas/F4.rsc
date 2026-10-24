# F4 - monitoreo + floating static con check-gateway
# Claves como marcador. Valores reales en secrets.txt (fuera del repo).

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

# ===== F4: netwatch - DIST-1 y DIST-2 (dueno R4) =====
# Vigila al otro DIST por la LAN USERS. En DIST-1 host=192.168.10.3, en DIST-2 host=192.168.10.2
/tool netwatch add host=192.168.10.3 type=icmp interval=5s comment=PAR-DIST up-script=":log info \"NETWATCH PAR-DIST up\"" down-script=":log warning \"NETWATCH PAR-DIST down\""

# ===== F4: floating static con check-gateway - EDGE (dueno R2 por rotacion) =====
# Distancia 30/31: quedan detras de BGP (20). Solo se usan si BGP no aporta default.
/ip route add dst-address=0.0.0.0/0 gateway=203.0.113.1 distance=30 check-gateway=ping comment="chk-ISP1"
/ip route add dst-address=0.0.0.0/0 gateway=203.0.113.5 distance=31 check-gateway=ping comment="chk-ISP2"

# ===== F4: ruta de vuelta hacia las LANs - ISP-1 e ISP-2 (dueno R1 por rotacion) =====
# Sin BGP el ISP no conoce las LANs. Distancia 30, detras de la ruta BGP (20).
# ISP-1: gateway=203.0.113.2   ISP-2: gateway=203.0.113.6
/ip route add dst-address=192.168.10.0/24 gateway=203.0.113.2 distance=30 comment="vuelta LAN USERS"
/ip route add dst-address=192.168.20.0/24 gateway=203.0.113.2 distance=30 comment="vuelta LAN SERVERS"
