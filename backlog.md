# Backlog — Laboratorio Failover Routing

> **Grupo:** 12 · **Vencimiento final:** vie 23/10

## Leyenda de estado

- `[ ]` pendiente · `[~]` en curso · `[x]` hecho
- Cada tarea lleva **dueño** (rol): `[R1]` … `[R5]`.
- **"Hecho" = criterio de aceptación cumplido** (ver spec, sección 6). No "más o menos".

---

## Epic F0 — Diseño y gestión de cambio · *vence vie 2/10*

### IPAM / direccionamiento
- [x] [R1] tabla de enlaces, LANs, VRRP y router-ids sin solapamiento (`docs/F0.md` §2)

### Corrección del diagrama (≥ 3 defectos)
- [x] [R1] documentar los 5 defectos con corrección y justificación (`docs/F0.md` §1)

### Política de seguridad
- [x] [R1] usuarios, servicios, auth del plano de control y firewall (`docs/F0.md` §3)

### Política de operación (change log + backup)
- [x] [R5] formato de change log y política de backup (`docs/F0.md` §4)

### Repositorio git
- [x] [R1] estructura de carpetas + README
- [x] [R1] `backlog.md` + `.gitignore`

---

## Epic F1 — Topología + hardening + backup · *vence vie 9/10*

### Despliegue (7 CHR + 2 switches + 2 hosts)
- [x] [R1] instalar GNS3 + template CHR7 (adaptadores 4, virtio, telnet)
- [x] [R5] crear nodos y cablear los 15 enlaces según `docs/guia-F1-F3.md` §2.1

### IPs de enlace + loopbacks
- [x] [R1] EDGE: bloque F1 de `configs/EDGE.rsc`
- [x] [R2] ISP-1 e ISP-2: bloque F1
- [x] [R3] CORE-1 y CORE-2: bloque F1
- [x] [R4] DIST-1 y DIST-2: bloque F1
- [x] [R5] hosts VPCS + ping entre vecinos de cada /30 (`capturas/edge_prueba.png`, `core_1.png`, `core_2.png`, `pc_prueba.png`, `sever_prueba.png`)

### Snapshot BASE
- [x] [R5] snapshot `BASE` en GNS3 (`BASE_141026_233041`, 14/10 23:30, dentro del proyecto)

### Hardening (los 7 routers)
- [x] [R1] definir claves del grupo y compartir por canal privado
- [x] [R1..R4] admin + `monitor` (read) + servicios apagados en sus routers
- [x] [R1..R4] quitar el `dhcp-client` de fábrica en los 7 routers
- [x] [R5] verificar `/ip service print` y `/user print` en los 7 (`capturas/F1/verif_<router>.png`)

### Backup inicial (`/export`)
- [x] [R1..R4] `/export terse` de cada router a `backups/AAAA-MM-DD_<router>_F1.rsc`
- [x] [R5] revisar que no haya claves y commitear `ops(backup): backups post-F1`
- [x] [R5] restore probado: reset de un router + `/import` de su `.rsc` + captura (F0 4.2) — DIST-2, `capturas/F1/restore_*.png`
- [x] [R5] cargar el change log con las entradas de F0 y F1 (F0 4.1)

---

## Epic F2 — VRRP + OSPF · *vence vie 16/10*

### VRRP (2 grupos, load-sharing, auth)
- [x] [R1] warm-up `laboratorio-vrrp.md`: failover R1/R2 probado (`capturas/ping_failover.png`)
- [x] [R4] VRRP vrid 10 en DIST-1 (master, prio 200) y DIST-2 (backup, prio 100)
- [x] [R4] VRRP vrid 20 en DIST-2 (master, prio 200) y DIST-1 (backup, prio 100)
- [x] [R4] auth `ah` (VRRPv2) en ambos grupos + filtro VRRP (con `ah` el paquete es IP 51, no 112: el filtro va por `ipsec-ah`)
- [x] [R5] verificar master/backup con `/interface vrrp print` (`capturas/F2/vrrp_DIST-*.png`)

### OSPF área 0 (con MD5, incluido core–core)
- [x] [R3] OSPF en CORE-1 y CORE-2 (4 vecinos cada uno)
- [x] [R1] OSPF en EDGE + `originate-default=if-installed`
- [x] [R4] OSPF en DIST-1 y DIST-2 (LANs pasivas)
- [x] [R5] verificar 7 adyacencias FULL con `/routing ospf neighbor print` (`capturas/F2/ospf_*.png`)

### Verificación L3 (ping intra-LAN + gateway virtual)
- [x] [R5] PC-USER → 192.168.10.1 y SRV → 192.168.20.1 (`capturas/F2/ping_*.png`)
- [x] [R5] PC-USER → SRV (lo rutea directo el DIST master, que tiene las dos LANs; ver `trace` en `capturas/F2/ping_PC-USER.png`)
- [x] [R1..R4] backups `_F2`

---

## Epic F3 — BGP + firewall · *vence vie 16/10*

### eBGP multi-homing (2 sesiones, TCP-MD5)
- [x] [R2] sesiones en ISP-1 e ISP-2 (default-originate + /32 de "Internet")
- [x] [R1] sesiones en EDGE con filtros `from-isp1` (lp 200) y `from-isp2` (lp 100)
- [x] [R5] verificar 2 sesiones established con TCP-MD5 (`capturas/F3/bgp_EDGE.png`, `capturas/F3/bgp_tcp-md5.png`)

### Redistribución OSPF→BGP
- [x] [R1] `output.redistribute=ospf` + filtro `to-isp` (solo las 2 LANs)
- [x] [R2] verificar LANs aprendidas en ISP-1 e ISP-2 (`capturas/F3/bgp_ISP-*.png`)

### Salida a "Internet" (host → loopback ISP)
- [x] [R5] PC-USER → 198.51.100.100 + trace (`capturas/F3/internet_*.png`)

### Firewall edge (filtro + plano de gestión)
- [x] [R1] firewall input/forward en EDGE (F0 §3.5)
- [x] [R3] firewall input en CORE-1 y CORE-2
- [x] [R4] firewall input en DIST-1 y DIST-2
- [x] [R5] pruebas negativas (SSH desde ISP, origen bogon) + `print stats` (`capturas/F3/firewall_*.png`)
- [x] [R1..R4] backups `_F3`

---

## Epic F4 — Drills + monitoreo · *vence mar 20/10* · completado 23/10 (atrasado)

### Los 5 drills (runbook + post-mortem + tiempo)
- [x] [R1] runbooks de los 5 drills (`runbooks/drill-*.md`)
- [x] [R5] drill 1 VRRP: corte 2 s (`capturas/F4/drill1_*`)
- [x] [R5] drill 2 OSPF: corte 1 s (`capturas/F4/drill2_*`)
- [x] [R5] drill 3 BGP: corrida 1 corte 1 s; corrida 2 corte 144,5 s por hold-time (`capturas/F4/drill3_*`)
- [x] [R5] drill 4 check-gateway: corrida 1 corte 1 s; corrida 2 corte 23 s (`capturas/F4/drill4_*`)
- [x] [R5] drill 5 load-sharing: SRV 2 pings, PC-USER 0 (`capturas/F4/drill5_*`)
- [x] [R3/R2] drills 2-4 con falla del lado lejano (corrida 2): OSPF 0 s, BGP 144,5 s, check-gateway 23 s (`capturas/F4/drillN_v2_*`)
- [x] [R5] evidencia de drills en texto (capturas/F4/*.txt)

### Monitoreo (SNMP/chequeos)
- [x] [R1..R4] SNMP v3 authPriv en los 7 routers, `public` deshabilitada
- [x] [R1..R4] `trap-community=goys12` en los 7 routers
- [x] [R2] netwatch en EDGE (ISP-1, ISP-2, CORE-1, CORE-2) — rotación F4
- [x] [R4] netwatch en DIST-1 y DIST-2 (vigilan al par VRRP)
- [x] [R2] floating static con check-gateway en EDGE (distancia 30/31) — rotación F4
- [x] [R1] rutas de vuelta a las LANs en ISP-1 e ISP-2 — rotación F4
- [x] [R5] documentar monitoreo (`docs/monitoreo.md`)

### Verificación de seguridad (clave incorrecta falla)
- [x] [R3] OSPF con clave incorrecta en DIST-2: adyacencia cae a los 40 s, `md5 mismatch` (`capturas/F4/seg_ospf_*`)
- [x] [R1] BGP con clave incorrecta en ISP-2: sesión no establece (`capturas/F4/seg_bgp_*`)
- [x] [R1..R4] backups `_F4`

---

## Epic F5 — Memoria + defensa · *vence vie 23/10* · en curso 24/10 (atrasado)

### Memoria (plantilla completa)
- [x] [R1] borrador de `docs/memoria.md` con todas las secciones de la plantilla
- [x] [R1..R5] resolver los `[PENDIENTE]` de la memoria
- [x] [R5] change log con las entradas de F4 y F5

### Backlog cerrado (todo en "hecho")
- [ ] [R5] revisar estado final

### Defensa oral (parte propia + ajena)
- [ ] [R1..R5] ensayo cruzado: cada uno explica su parte y la del rol asignado (R1↔R2, R3↔R4, R5↔R1)
