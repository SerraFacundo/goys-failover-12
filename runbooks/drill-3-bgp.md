# Drill 3 — BGP: se cae el proveedor primario (ISP-1)

| Campo | Valor |
|-------|-------|
| Mecanismo | eBGP multi-homing, local-pref 200 (ISP-1) / 100 (ISP-2) |
| Ejecuta | R5 (hosts) + R2 en EDGE y R1 en ISP (rotación F4 R1↔R2) |
| Falla inyectada | Se corta el enlace EDGE `ether1` ↔ ISP-1 |
| Fecha / hora | 2026-10-23 21:51 (hora local; los routers marcan 2026-10-24 00:51) |

## Estado previo

```
EDGE> /routing bgp session print                         # ISP-1 e ISP-2 established
EDGE> /ip route print where dst-address=0.0.0.0/0        # activa vía 203.0.113.1
PC-USER> trace 198.51.100.100                            # pasa por 203.0.113.1
```
Captura: `capturas/F4/drill3_antes.png`

## Detección

- `/routing bgp session print` en EDGE: la sesión ISP-1 deja de estar established.
- `/ip route print where dst-address=0.0.0.0/0`: la default activa pasa a `203.0.113.5`.
- Netwatch en EDGE: `NETWATCH ISP-1 down` (aparece antes que la caída de BGP).
- `/log print where topics~"bgp"`.

## Respuesta (inyectar la falla)

1. PC-USER: `ping 198.51.100.100 -t`
2. GNS3: cable EDGE–ISP-1 > **Suspend**.
3. Esperar a que el ping vuelva. Cronometrar aparte: puede tardar minutos.

## Recuperación

1. GNS3: cable EDGE–ISP-1 > **Resume**.
2. Esperar la sesión ISP-1 established.
3. La default vuelve a `203.0.113.1` por local-pref 200. Verificar con `trace 198.51.100.100`.

Capturas: `drill3_falla.png` (sesiones + default por ISP-2 + ping), `drill3_recuperado.png`.

## Tiempo medido

| Medición | Valor |
|----------|-------|
| Netwatch marca ISP-1 down a los | 3 s |
| BGP da de baja la sesión a los | 170 s |
| Tiempo de corte total del host | 1 s |
| Tiempo hasta volver a ISP-1 | 5 s |

Valor de referencia: con el link arriba pero sin tráfico, BGP espera al hold-time (180 s por defecto en RouterOS 7).

## Post-mortem

- ¿Por qué netwatch detectó antes que BGP? Netwatch hace ping cada 5 s y marcó down a los 3 s; BGP solo da de baja la sesión por hold-time (HoldTimer expired a los 170 s). Igual el host cortó 1 s: el Suspend baja el link, la ruta BGP vía 203.0.113.1 quedó inactiva al instante por next-hop inalcanzable (con la sesión todavía established) y la default pasó a 203.0.113.5. Al volver, la sesión ISP-1 quedó established a los 3 s del link up y la default volvió a 203.0.113.1 a los 5 s.
- ¿Qué pasa con el tráfico que entra desde Internet hacia las LANs durante el corte? ISP-1 sigue teniendo la ruta BGP hasta su propio hold-time. No medido: no se generó tráfico desde Internet hacia las LANs. Observado: ISP-1 también registró ether1 link down a las 00:51:54 (hora router), el mismo segundo que EDGE.
- Mejora posible: `hold-time=9s keepalive-time=3s` en las dos conexiones, o BFD. Probado: no. Resultado: no medido: no se probó en esta corrida.

## Corrida 2 (falla del lado lejano)

Fecha / hora: 2026-10-23 22:36 (hora local; los routers marcan 2026-10-24 01:36).
Falla inyectada: `ISP-1> /interface disable ether1`. EDGE `ether1` siguió `running` durante toda la falla.
Evidencia: `capturas/F4/drill3_v2_antes.txt`, `drill3_v2_falla.txt`, `drill3_v2_recuperado.txt`.

| Medición | Valor |
|----------|-------|
| Netwatch marca ISP-1 down a los | 3 s (log) |
| BGP da de baja la sesión a los | 143 s (log: `HoldTimer expired`) |
| Default activa pasa a 203.0.113.5 | +145 s (sondeo) |
| Pings perdidos en PC-USER | 88 |
| Tiempo de corte total del host (timeouts × 1 s) | 88 s |
| Tiempo de corte de reloj (última respuesta → primera respuesta) | 144,5 s |
| Tiempo hasta volver a ISP-1 (`/interface enable ether1` en ISP-1) | 4 s |

Post-mortem:
- Con el link de EDGE arriba, la ruta BGP vía 203.0.113.1 siguió activa: el next-hop es directamente conectado y la interfaz no cayó. El tráfico se perdió hasta que expiró el hold-time.
- La sesión cayó a los 143 s y no a los 180 s porque el hold-time corre desde el último keepalive recibido, que llegó unos 37 s antes del disable.
- Netwatch vio la falla a los 3 s, pero solo escribe en el log: no cambia rutas. Con BGP solo, el corte del host es el hold-time.
- El conteo de timeouts (88) subestima el corte: en VPCS cada timeout tarda unos 1,6 s. El corte real fue de 144,5 s.
- Mejora posible (no probada): `hold-time=9s keepalive-time=3s` o BFD; o un `down-script` de netwatch que deshabilite la conexión ISP-1.
