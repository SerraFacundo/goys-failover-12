# goys-failover-12

**Laboratorio:** Failover Routing, la red que no se cae
**Materia:** Gestión Operativa y Seguridad en Redes (GOYS), UTN FRLP
**Grupo:** 12

## Integrantes y roles

| Integrante | Rol | Routers |
|-----------|-----|---------|
| Serra Facundo | R1, Líder / Edge-WAN | EDGE |
| Espamer Martín | R2, Proveedores | ISP-1, ISP-2 |
| Rebol Manuel | R3, Core | CORE-1, CORE-2 |
| Molteni Baltazar | R4, Distribución | DIST-1, DIST-2 |
| Manrique Agustín | R5, Hosts / QA / Operación | PC-USER, SRV |

## Resumen

Red empresarial jerárquica de 5 capas en GNS3 con MikroTik CHR (RouterOS 7), con redundancia en tres niveles:

- **Primer salto:** VRRP en distribución (DIST-1 master del grupo 10, DIST-2 master del grupo 20).
- **IGP:** OSPF área 0 con MD5, incluido el enlace core-core.
- **Proveedor:** eBGP multi-homing del EDGE (AS 65000) contra ISP-1 (AS 65001) e ISP-2 (AS 65002), con TCP-MD5.

```
[ INTERNET ]     ISP-1 (AS 65001)      ISP-2 (AS 65002)      eBGP
[ EDGE ]              EDGE (AS 65000)                        eBGP multi-homing + OSPF
[ CORE ]         CORE-1 ─── core-core ─── CORE-2             OSPF área 0 (tránsito puro)
[ DISTRIBUTION ]   DIST-1               DIST-2               VRRP + OSPF
[ ACCESS ]       SW-USERS + PC-USER    SW-SERVERS + SRV      USERS / SERVERS
```

El diseño (IPAM, corrección del diagrama, seguridad y operación) está en [`docs/F0.md`](docs/F0.md).

## Estado

| Fase | Contenido | Vence | Estado |
|------|-----------|:-----:|--------|
| F0 | Diseño + políticas + repo | 2/10 | Aprobado |
| F1 | Topología + hardening + backup | 9/10 | Entregado 14/10, restore probado 15/10 |
| F2 | VRRP + OSPF | 16/10 | Hecho 15/10 |
| F3 | BGP + firewall | 16/10 | Hecho 15/10 |
| F4 | Drills + monitoreo | 20/10 | Hecho 23/10 |
| F5 | Memoria + defensa | 23/10 | Memoria entregada 24/10; defensa en clase |

El detalle por tarea está en [`backlog.md`](backlog.md) y la memoria completa en [`docs/memoria.md`](docs/memoria.md).

## Estructura

| Carpeta | Contenido |
|---------|-----------|
| `docs/` | F0, [memoria](docs/memoria.md), monitoreo, prueba de clave incorrecta y plantilla F4 |
| `configs/` | `.rsc` por router, separados en bloques F1 a F4, con claves como `<KEY>` |
| `backups/` | `/export` de cada router, `AAAA-MM-DD_<ROUTER>_<FASE>.rsc` |
| `runbooks/` | Un `.md` por drill, con tiempos medidos y post-mortem |
| `capturas/` | Evidencia por fase (`F1/` a `F4/`) |

`backup.py` saca el `/export terse` de los 7 routers por la consola de GNS3:

```
python3 backup.py ~/GNS3/projects/<proyecto>/<proyecto>.gns3 F2
```

Las claves reales no se suben al repo (ver `.gitignore` y F0 3.1).
