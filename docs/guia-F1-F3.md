# Guía F1 → F3 — Grupo 12 (Failover Routing)

Base: `docs/F0.md` aprobado. Todo lo de abajo respeta ese IPAM, esas claves y esa política. Configs listas en `configs/<ROUTER>.rsc`, separadas por bloques `F1` / `F2` / `F3`.

Antes de arrancar, dos huecos en el repo: F0 promete `backlog.md` y `.gitignore` y no están. Crearlos primero (`chore: agrego backlog y gitignore`). En `.gitignore` como mínimo: `*.backup`, `secrets*`, `.env`.

Diferencias con la imagen del docente (prio 150, hosts `.100`, router-id 4.4.4.4/5.5.5.5): manda el F0 aprobado (prio 200/100, hosts `.10`, router-id = loopback `10.255.0.x`). Dejarlo dicho en la memoria.

---

## 0. Instalar GNS3 en Bazzite (rpm-ostree)

Bazzite es inmutable: los paquetes se agregan como capa con `rpm-ostree` y se aplican al reiniciar.

### 0.1 Chequeos previos

```bash
ls -l /dev/kvm            # tiene que existir; si no, activar VT-x/AMD-V en la BIOS
rpm-ostree status         # que no haya un deployment pendiente a medias
```

### 0.2 Instalar y reiniciar

```bash
rpm-ostree install gns3-gui gns3-server qemu-kvm qemu-img telnet
systemctl reboot
```

Si dice que algún paquete ya está en la imagen base (por ejemplo `qemu-kvm`), sacarlo de la lista y repetir.

### 0.3 VPCS

```bash
rpm-ostree install vpcs && systemctl reboot
```

Si `vpcs` no existe en el repo, compilarlo sin tocar el sistema y dejarlo en tu home:

```bash
toolbox create && toolbox enter
sudo dnf install -y git gcc make
cd ~ && { [ -d vpcs ] || git clone https://github.com/GNS3/vpcs; }
cd ~/vpcs/src && ./mk.sh
mkdir -p ~/.local/bin && cp vpcs ~/.local/bin/
exit
```

En GNS3, `Edit > Preferences > VPCS`: `/home/<usuario>/.local/bin/vpcs`.

### 0.4 Primer arranque

Abrir GNS3 desde el menú. Asistente: "Run appliances on my local computer", server path `/usr/bin/gns3server`. En `Preferences > QEMU` dejar "Enable KVM".

`ubridge` viene como dependencia de `gns3-server`. Para enlaces entre VMs (todo este lab) alcanza así. Si GNS3 se queja de permisos de ubridge, ver `getcap /usr/bin/ubridge`.

### 0.5 Revertir

```bash
rpm-ostree uninstall gns3-gui gns3-server qemu-kvm qemu-img telnet
systemctl reboot
```

---

## 1. Template MikroTik CHR

1. Bajar de mikrotik.com/download → Cloud Hosted Router → **Raw disk image** v7 estable (`chr-7.xx.img.zip`). Descomprimir.
2. GNS3: `Edit > Preferences > QEMU VMs > New`:
   - Nombre `CHR7`, binario `qemu-system-x86_64`
   - RAM **256 MB**, 1 vCPU, consola **telnet**
   - Disco: el `.img`
3. Editar el template: `Network > Adapters = 4`, tipo `virtio-net-pci`.

Mapeo de interfaces: adaptador `eN` de GNS3 = `ether(N+1)` en RouterOS. `e0`=ether1, `e1`=ether2, `e2`=ether3, `e3`=ether4.

Primer login en cada CHR: usuario `admin`, sin clave. RouterOS 7 pide clave nueva en el primer login: poner la `<ADMIN_PASS>` del grupo.

`<ADMIN_PASS>` (y `<MONITOR_PASS>`, `<K-OSPF-12>`, `<K-BGP-ISP1>`, etc.) son marcadores: no hay un valor fijo, lo define el grupo. Según F0 3.1, una clave distinta por usuario y por protocolo, guardada en un archivo local excluido por `.gitignore` (por ejemplo `secrets.txt`) y compartida por un canal privado. Nunca en el repo ni en la memoria.

---

## 2. F1 — Topología + hardening + backup (vence 9/10, ya vencida: cerrar YA)

Si el docente pasó el proyecto `topologia_failover_routing` (.gns3project), importarlo (`File > Import portable project`) y saltar a 2.2, verificando que los cables coincidan con la tabla.

### 2.1 Despliegue (R5 + R1)

Nodos: 7× CHR7, 2× Ethernet switch (built-in de GNS3), 2× VPCS.

| Enlace | A | B |
|---|---|---|
| ISP-1 ↔ EDGE | ISP-1 e0 | EDGE e0 |
| ISP-2 ↔ EDGE | ISP-2 e0 | EDGE e1 |
| EDGE ↔ CORE-1 | EDGE e2 | CORE-1 e0 |
| EDGE ↔ CORE-2 | EDGE e3 | CORE-2 e0 |
| core-core | CORE-1 e1 | CORE-2 e1 |
| CORE-1 ↔ DIST-1 | CORE-1 e2 | DIST-1 e0 |
| CORE-1 ↔ DIST-2 | CORE-1 e3 | DIST-2 e0 |
| CORE-2 ↔ DIST-1 | CORE-2 e2 | DIST-1 e1 |
| CORE-2 ↔ DIST-2 | CORE-2 e3 | DIST-2 e1 |
| USERS | DIST-1 e2, DIST-2 e2 | SW-ACC-USERS puertos 0 y 1 |
| SERVERS | DIST-1 e3, DIST-2 e3 | SW-ACC-SERVERS puertos 0 y 1 |
| hosts | PC-USER e0 → SW-USERS p2 | SRV e0 → SW-SERVERS p2 |

15 enlaces. Switches con todos los puertos en VLAN 1 (default).

### 2.2 IPs + hardening (cada rol su router)

Abrir consola (doble click), pegar del `.rsc` correspondiente **solo los bloques `F1`**. Pegar de a bloques chicos: la consola serie a veces come caracteres en pegados largos.

Antes de pegar, reemplazar `<ADMIN_PASS>` y `<MONITOR_PASS>` en el editor, no en el archivo del repo.

| Rol | Routers |
|---|---|
| R1 | EDGE |
| R2 | ISP-1, ISP-2 |
| R3 | CORE-1, CORE-2 |
| R4 | DIST-1, DIST-2 |

Hosts (R5), en la consola VPCS:

```
PC-USER> ip 192.168.10.10/24 192.168.10.1
PC-USER> save
SRV> ip 192.168.20.10/24 192.168.20.1
SRV> save
```

### 2.3 Verificación F1 (criterio: ping entre vecinos OK)

```
/ip address print
/ping 10.0.0.2 count=3        # desde EDGE a CORE-1, etc.
/ip service print             # solo ssh habilitado
/user print                   # admin + monitor (read)
```

Hacer los ping de cada /30 desde un extremo. Captura de cada uno a `capturas/F1/`. Desde PC-USER: `ping 192.168.10.2` y `ping 192.168.10.3`.

### 2.4 Snapshot BASE

`Edit > Manage snapshots > Create` → nombre `BASE`. Captura + mencionarlo en la memoria.

### 2.5 Backup inicial (R5 coordina, cada rol el suyo)

En cada router:

```
/export terse
```

Copiar la salida a `backups/2026-10-1X_<ROUTER>_F1.rsc`. RouterOS 7 oculta claves por defecto, igual revisar antes de commitear.

---

## 3. F2 — VRRP + OSPF (vence 16/10)

Pegar los bloques `F2` de cada `.rsc`. Orden sugerido: CORE → EDGE → DIST (así las adyacencias suben de a una y se ve quién falla).

Claves: reemplazar `<K-OSPF-12>`, `<K-VRRP-10>`, `<K-VRRP-20>` con las reales del grupo (misma clave OSPF en las 7 puntas activas).

### 3.1 Verificación OSPF (criterio: FULL con MD5, incluido core-core)

```
/routing ospf neighbor print
```

| Router | Vecinos FULL esperados |
|---|---|
| EDGE | 2 (CORE-1, CORE-2) |
| CORE-1 / CORE-2 | 4 (EDGE, el otro core, DIST-1, DIST-2) |
| DIST-1 / DIST-2 | 2 (CORE-1, CORE-2) |

Total: 7 adyacencias. Revisar también `/ip route print where ospf` en EDGE: tienen que aparecer `192.168.10.0/24` y `192.168.20.0/24`.

### 3.2 Verificación VRRP (criterio: load-sharing con auth)

```
/interface vrrp print
```

DIST-1: `vrrp10` con flag **M** (master), `vrrp20` backup. DIST-2: al revés.

Desde hosts:

```
PC-USER> ping 192.168.10.1
SRV> ping 192.168.20.1
PC-USER> ping 192.168.20.10     # intra-red, cruza el core
```

Backup `_F2` de cada router al cerrar.

---

## 4. F3 — BGP + firewall (vence 16/10)

### 4.1 BGP

Pegar bloque `F3` de BGP: primero ISP-1 e ISP-2 (R2), después EDGE (R1). Reemplazar `<K-BGP-ISP1>` / `<K-BGP-ISP2>` (la misma clave en ambas puntas de cada sesión).

Qué hace:
- ISPs mandan default (`default-originate=always`) + sus /32 de "Internet" (`198.51.100.x`).
- EDGE acepta solo default + /32 de `198.51.100.0/24`, pone `local-pref 200` a ISP-1 y `100` a ISP-2.
- EDGE redistribuye OSPF en BGP, pero el filtro `to-isp` deja salir solo las dos LANs.
- EDGE mete la default en OSPF (`originate-default=if-installed`): recién cuando BGP sube, CORE y DIST reciben salida.

Verificación (criterio: 2 sesiones established + LANs anunciadas + host llega al ISP):

```
# EDGE
/routing bgp session print                       # 2 sesiones, established
/ip route print where dst-address=0.0.0.0/0      # activa via 203.0.113.1 (ISP-1)
# ISP-1 / ISP-2
/ip route print where bgp                        # 192.168.10.0/24 y 192.168.20.0/24
# DIST
/ip route print where dst-address=0.0.0.0/0      # default aprendida por OSPF
```

```
PC-USER> ping 198.51.100.100
PC-USER> trace 198.51.100.100
SRV> ping 198.51.100.2          # llega por ISP-2 (su /32 solo lo anuncia ISP-2)
```

### 4.2 Firewall

Pegar bloque `F3` de firewall: EDGE (R1), CORE (R3), DIST (R4). **Pegar al final**, con OSPF y BGP ya andando: las reglas terminan en `drop`.

Verificación:

```
/ip firewall filter print stats      # contadores subiendo en las reglas accept
```

Pruebas negativas (capturar):
- Desde ISP-1: `/system ssh 203.0.113.2` → timeout (gestión cerrada desde afuera).
- Desde ISP-1: `/ping 192.168.10.10 src-address=10.255.0.11` → no responde (origen bogon, regla `fw #3`). Sin `src-address` sí responde (regla `fw #5`).
- Sesiones BGP y adyacencias OSPF siguen arriba después de cargar el firewall.

Backup `_F3` al cerrar.

---

## 5. Git: un commit por cambio, cada rol el suyo

Cada integrante sube su `.rsc` desde su cuenta:

```
feat(configs): EDGE IPs y hardening F1
feat(configs): VRRP vrid10/20 con auth AH en DIST-1 y DIST-2
feat(ospf): OSPF area 0 con MD5 en CORE-1 y CORE-2
feat(bgp): eBGP multi-homing con TCP-MD5 en EDGE
feat(firewall): filtro input/forward en EDGE
ops(backup): backups post-F1
docs(memoria): verificación F2
```

`configs/` va con `<KEY>` en vez de claves reales (como dice F0 3.4). Cada commit = una fila del change log (F0 4.1).

Atraso: F1 venció el 9/10. Hoy 13/10 y F2/F3 vencen el 16/10. Dividir en paralelo: R5+R1 cablean hoy, cada rol pega F1 mañana, F2/F3 el 15/10, el 16/10 solo verificación y capturas.

---

## 6. Problemas típicos

| Síntoma | Causa probable | Arreglo |
|---|---|---|
| GNS3 "KVM not available" | Virtualización apagada | Activar VT-x/AMD-V en BIOS; `ls -l /dev/kvm` |
| OSPF queda en `Init`/`ExStart` | Clave MD5 distinta, o `type=ptp` solo en una punta | `/routing ospf interface-template print`, comparar |
| Ambos DIST master del mismo VRID | Switch mal cableado o clave VRRP distinta | `/interface vrrp print`, revisar cable a SW y `password` |
| `password` VRRP rechazado | Largo de clave en VRRPv2 | Probar clave de 8 caracteres o menos |
| BGP en `Active`/`Connect` | Clave TCP-MD5 distinta o firewall antes de BGP | Comparar clave; desactivar regla `in #7` y probar |
| Host no sale a "Internet" | Sin default en DIST | Sesión BGP caída en EDGE, `originate-default=if-installed` sin default instalada |
| No puedo entrar por consola | Nunca: la consola GNS3 es serie, el firewall no la toca | — |
