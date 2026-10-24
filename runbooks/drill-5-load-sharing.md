# Drill 5 — Load-sharing VRRP: los dos DIST activos

| Campo | Valor |
|-------|-------|
| Mecanismo | VRRP vrid 10 master en DIST-1, vrid 20 master en DIST-2 |
| Ejecuta | R5 (hosts) + R4 (DIST) |
| Falla inyectada | DIST-2 pierde la LAN SERVERS (`ether4`) |
| Fecha / hora | 2026-10-23 21:15 (hora local; los routers marcan 2026-10-24 00:15) |

## Estado previo: los dos DIST trabajan a la vez

```
DIST-1> /interface vrrp print      # vrrp10 M, vrrp20 backup
DIST-2> /interface vrrp print      # vrrp10 backup, vrrp20 M
PC-USER> trace 198.51.100.100      # primer salto 192.168.10.2 (DIST-1)
SRV>     trace 198.51.100.100      # primer salto 192.168.20.3 (DIST-2)
```
Captura: `capturas/F4/drill5_antes.png`. Es la evidencia principal del drill: cada LAN sale por un DIST distinto.

## Detección

- `/interface vrrp print` en DIST-1: `vrrp20` pasa a `M`. DIST-1 queda master de los dos grupos.
- `trace 198.51.100.100` desde SRV: el primer salto pasa a `192.168.20.2`.

## Respuesta (inyectar la falla)

1. SRV: `ping 198.51.100.100 -t`
2. DIST-2: `/interface disable ether4`
3. Verificar que PC-USER sigue sin cortes (su master es DIST-1 y no cambió).

## Recuperación

1. DIST-2: `/interface enable ether4`
2. DIST-2 recupera `vrrp20` como master. Vuelve el reparto original.
3. `trace` desde los dos hosts igual al estado previo.

Capturas: `drill5_falla.png`, `drill5_recuperado.png`.

## Tiempo medido

| Medición | Valor |
|----------|-------|
| Pings perdidos en SRV | 2 |
| Pings perdidos en PC-USER (debería ser 0) | 0 |

## Post-mortem

- Ventaja frente a un solo master para todo: con los dos DIST sanos se usa la capacidad de ambos, y una falla afecta solo a la LAN cuyo master cayó.
- Límite: si cae un DIST, el otro carga con las dos LANs. Hay que dimensionar cada uno para el 100 % del tráfico.
- Observación: DIST-1 tomó vrrp20 a los 4 s (log 00:15:51 → 00:15:55) y el trace de SRV pasó a 192.168.20.2. Al habilitar ether4, DIST-2 retomó vrrp20 a los 11 s (00:16:18 → 00:16:29) sin pérdidas en ningún host, y los trace volvieron a 192.168.10.2 (PC-USER) y 192.168.20.3 (SRV).
