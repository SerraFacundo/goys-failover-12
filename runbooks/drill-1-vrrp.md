# Drill 1 — VRRP: se cae el gateway de USERS

| Campo | Valor |
|-------|-------|
| Mecanismo | VRRP v2, vrid 10 (USERS) |
| Ejecuta | R5 (opera los hosts) + R4 (DIST) |
| Falla inyectada | DIST-1 pierde la LAN USERS (`ether3`) |
| Fecha / hora | 2026-10-23 21:14 (hora local; los routers marcan 2026-10-24 00:14) |

## Estado previo (verificar antes de romper)

```
DIST-1> /interface vrrp print        # vrrp10 = M (master), vrrp20 = backup
DIST-2> /interface vrrp print        # vrrp10 = backup, vrrp20 = M
DIST-1> /log print where message~"NETWATCH"
```
Captura: `capturas/F4/drill1_antes.png`

## Detección

Indicadores de que el gateway de USERS cayó:
- `/interface vrrp print` en DIST-2: `vrrp10` pasa a `M`.
- `/log print where topics~"vrrp"` en DIST-2: transición a master.
- Netwatch en DIST-2: `NETWATCH PAR-DIST down`.
- En PC-USER: el ping continuo muestra `timeout` y después vuelve.

## Respuesta (inyectar la falla)

1. PC-USER: `ping 198.51.100.100 -t` (dejar corriendo).
2. DIST-1: `/interface disable ether3`
3. Mirar el ping hasta que vuelva a responder. No tocar nada más.

## Recuperación

1. DIST-1: `/interface enable ether3`
2. Verificar que DIST-1 recupera `vrrp10` como master (preemption, prioridad 200 > 100).
3. `/interface vrrp print` en los dos DIST igual al estado previo.

Captura: `capturas/F4/drill1_falla.png` (ping + vrrp de DIST-2) y `drill1_recuperado.png`.

## Tiempo medido

Tiempo de corte = cantidad de `timeout` seguidos × 1 s (VPCS manda un ping por segundo).

| Medición | Valor |
|----------|-------|
| Pings perdidos al caer DIST-1 | 2 |
| Tiempo de corte | 2 s |
| Pings perdidos en la vuelta (preemption) | 0 |

Valor de referencia: VRRP v2 con advertisement de 1 s declara caído al master a los ~3 s (3 × advert + skew).

## Post-mortem

- ¿El host cambió de gateway? No: sigue apuntando a `192.168.10.1`. Lo que cambia es qué router responde por la IP y la MAC virtual (`00:00:5E:00:01:0A`).
- ¿Coincide el tiempo con el de referencia? Sí: DIST-2 pasó vrrp10 a MASTER a los 4 s de bajar ether3 (log 00:14:25 → 00:14:29, hora router), cerca de los ~3 s + skew. El conteo da 2 s porque en VPCS cada timeout tarda ~2 s: entre la última respuesta y la siguiente pasaron ~5 s de reloj.
- Variante: si en vez de bajar `ether3` se apaga el nodo DIST-1 entero, la vuelta del tráfico desde el core puede tardar hasta el dead interval de OSPF (40 s), porque los CORE siguen viendo a DIST-1 como vecino. Probado: no. Resultado: no medido: la variante no se ejecutó en esta corrida.
- Mejora posible: con lo medido no hizo falta. Observado en la vuelta: DIST-1 entró como BACKUP y retomó vrrp10 a los 10 s (log 00:14:43 → 00:14:53) sin perder pings.
