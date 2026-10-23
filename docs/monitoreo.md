# Monitoreo — SNMP v3 + netwatch

Config: `docs/plantillas/F4.rsc`.

## SNMP v3 (los 7 routers)

- `authPriv`: autenticación SHA1 y cifrado AES, claves `<K-SNMP-AUTH>` y `<K-SNMP-PRIV>`.
- Comunidad `public` deshabilitada (v1/v2c mandan la comunidad en claro).
- Solo acepta consultas de `192.168.20.10` (SRV, colector previsto) y de las loopbacks `10.255.0.0/24`.
- El firewall de input ya permite UDP 161 solo desde la lista `mgmt` (F3).

Verificación:
```
/snmp print
/snmp community print
/ip firewall filter print stats where dst-port=161
```
Capturas: `capturas/F4/snmp_<ROUTER>.png` (al menos EDGE, un CORE y un DIST).

Limitación del lab: SRV es un VPCS y no puede correr un cliente SNMP (snmpwalk). En producción el colector sería un NMS (Zabbix, LibreNMS) en esa IP. Lo dejamos documentado.

## Netwatch (chequeos activos)

| Router | Vigila | Para qué |
|--------|--------|----------|
| EDGE | ISP-1, ISP-2, CORE-1, CORE-2 | Detectar caída de proveedor o de camino interno antes que BGP/OSPF |
| DIST-1 | DIST-2 por la LAN USERS | Detectar caída del par VRRP |
| DIST-2 | DIST-1 por la LAN USERS | Ídem |

Cada caída o vuelta queda en el log:
```
/tool netwatch print
/log print where message~"NETWATCH"
```
En los drills 1 a 4 el log de netwatch es parte de la evidencia de la fase de detección.
