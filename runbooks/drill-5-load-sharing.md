# Drill 5 — Load-sharing VRRP: los dos DIST activos

| Campo | Valor |
|-------|-------|
| Mecanismo | VRRP vrid 10 master en DIST-1, vrid 20 master en DIST-2 |
| Ejecuta | R5 (hosts) + R4 (DIST) |
| Falla inyectada | DIST-2 pierde la LAN SERVERS (`ether4`) |
| Fecha / hora | ____ |

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
| Pings perdidos en SRV | ____ |
| Pings perdidos en PC-USER (debería ser 0) | ____ |

## Post-mortem

- Ventaja frente a un solo master para todo: con los dos DIST sanos se usa la capacidad de ambos, y una falla afecta solo a la LAN cuyo master cayó.
- Límite: si cae un DIST, el otro carga con las dos LANs. Hay que dimensionar cada uno para el 100 % del tráfico.
- Observación: ____
