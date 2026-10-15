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
- [ ] [R4] VRRP vrid 10 en DIST-1 (master, prio 200) y DIST-2 (backup, prio 100)
- [ ] [R4] VRRP vrid 20 en DIST-2 (master, prio 200) y DIST-1 (backup, prio 100)
- [ ] [R4] auth `ah` (VRRPv2) en ambos grupos + filtro protocolo 112
- [ ] [R5] verificar master/backup con `/interface vrrp print`

### OSPF área 0 (con MD5, incluido core–core)
- [ ] [R3] OSPF en CORE-1 y CORE-2 (4 vecinos cada uno)
- [ ] [R1] OSPF en EDGE + `originate-default=if-installed`
- [ ] [R4] OSPF en DIST-1 y DIST-2 (LANs pasivas)
- [ ] [R5] verificar 7 adyacencias FULL con `/routing ospf neighbor print`

### Verificación L3 (ping intra-LAN + gateway virtual)
- [ ] [R5] PC-USER → 192.168.10.1 y SRV → 192.168.20.1
- [ ] [R5] PC-USER → SRV (cruza el core)
- [ ] [R1..R4] backups `_F2`

---

## Epic F3 — BGP + firewall · *vence vie 16/10*

### eBGP multi-homing (2 sesiones, TCP-MD5)
- [ ] [R2] sesiones en ISP-1 e ISP-2 (default-originate + /32 de "Internet")
- [ ] [R1] sesiones en EDGE con filtros `from-isp1` (lp 200) y `from-isp2` (lp 100)
- [ ] [R5] verificar 2 sesiones established

### Redistribución OSPF→BGP
- [ ] [R1] `output.redistribute=ospf` + filtro `to-isp` (solo las 2 LANs)
- [ ] [R2] verificar LANs aprendidas en ISP-1 e ISP-2

### Salida a "Internet" (host → loopback ISP)
- [ ] [R5] PC-USER → 198.51.100.100 + trace (captura)

### Firewall edge (filtro + plano de gestión)
- [ ] [R1] firewall input/forward en EDGE (F0 §3.5)
- [ ] [R3] firewall input en CORE-1 y CORE-2
- [ ] [R4] firewall input en DIST-1 y DIST-2
- [ ] [R5] pruebas negativas (SSH desde ISP, origen bogon) + `print stats`
- [ ] [R1..R4] backups `_F3`

---

## Epic F4 — Drills + monitoreo · *vence mar 20/10*

### Los 5 drills (runbook + post-mortem + tiempo)
- [ ] [R5] drill 1 VRRP · drill 2 OSPF · drill 3 BGP · drill 4 check-gateway · drill 5 load-sharing

### Monitoreo (SNMP/chequeos)
- [ ] <!-- [R#] tarea -->

### Verificación de seguridad (clave incorrecta falla)
- [ ] <!-- [R#] tarea -->

---

## Epic F5 — Memoria + defensa · *vence vie 23/10*

### Memoria (plantilla completa)
- [ ] <!-- [R#] tarea -->

### Backlog cerrado (todo en "hecho")
- [ ] [R5] revisar estado final

### Defensa oral (parte propia + ajena)
- [ ] [R1..R5] ensayo cruzado
