# Drill 4 — check-gateway: failover estático de enlace (sin BGP)

| Campo | Valor |
|-------|-------|
| Mecanismo | Rutas default estáticas con `check-gateway=ping`, distancia 30 (ISP-1) y 31 (ISP-2) |
| Ejecuta | R5 (hosts) + R2 en EDGE + R1 en ISP (rotación F4) |
| Falla inyectada | Sin BGP, se corta el enlace EDGE ↔ ISP-1 |
| Fecha / hora | 2026-10-23 22:15 (hora local; los routers marcan 2026-10-24 01:15). Suspend a las 22:19:15 |

Prerrequisito: bloque F4 de floating static aplicado en EDGE y rutas de vuelta en ISP-1 e ISP-2 (`docs/plantillas/F4.rsc`).

## Estado previo

```
EDGE> /routing bgp connection disable ISP-1,ISP-2
EDGE> /ip route print where dst-address=0.0.0.0/0     # activa chk-ISP1 (distancia 30)
PC-USER> ping 198.51.100.100                          # responde
```
Captura: `capturas/F4/drill4_antes.png`

## Detección

- `/ip route print where dst-address=0.0.0.0/0`: `chk-ISP1` queda inactiva por gateway inalcanzable y se activa `chk-ISP2`.
- Netwatch en EDGE: `NETWATCH ISP-1 down`.

## Respuesta (inyectar la falla)

1. PC-USER: `ping 198.51.100.100 -t`
2. GNS3: cable EDGE–ISP-1 > **Suspend**.
3. Esperar a que el ping vuelva.

## Recuperación

1. GNS3: cable EDGE–ISP-1 > **Resume**. `chk-ISP1` vuelve a quedar activa.
2. EDGE: `/routing bgp connection enable ISP-1,ISP-2`
3. Verificar sesiones established y default activa vía BGP otra vez (distancia 20).

Capturas: `drill4_falla.png`, `drill4_recuperado.png`.

## Tiempo medido

| Medición | Valor |
|----------|-------|
| Pings perdidos | 1 |
| Tiempo de corte | 1 s |

Valor de referencia: check-gateway hace ping cada 10 s y marca el gateway caído tras dos fallas seguidas, o sea entre 10 y 20 s.

## Post-mortem

- Diferencia con el drill 3: acá no hay protocolo de routing, el router solo verifica que el próximo salto responda. Detecta el corte del enlace, pero no un problema más adelante en la red del ISP. Observado: chk-ISP1 quedó inactiva y se activó chk-ISP2 a los ~2 s del link down (sondeo). Como el Suspend baja el carrier, la ruta cayó por interfaz caída antes de que check-gateway fallara sus pings, así que la detección propia de check-gateway (referencia 10–20 s) no se midió.
- ¿Fue más rápido o más lento que BGP con timers por defecto? Corte del host igual: 1 s en los dos drills. La sesión BGP tardó 170 s en caer (drill 3) contra ~2 s del cambio de ruta acá, pero en los dos casos lo que movió el tráfico fue el link down.
- Por qué quedan como respaldo detrás de BGP (distancia 30/31): si BGP funciona, manda BGP; si se caen las dos sesiones, la salida no depende de que BGP vuelva.

## Corrida 2 (falla del lado lejano)

Fecha / hora: 2026-10-23 22:43 (hora local; los routers marcan 2026-10-24 01:43). BGP deshabilitado como pide el estado previo.
Falla inyectada: `ISP-1> /interface disable ether1`. EDGE `ether1` siguió `running` durante toda la falla.
Evidencia: `capturas/F4/drill4_v2_antes.txt`, `drill4_v2_falla.txt`, `drill4_v2_recuperado.txt`.

| Medición | Valor |
|----------|-------|
| `NETWATCH ISP-1 down` | +2 s (log) |
| `chk-ISP1` queda inactiva por check-gateway | +24 s (sondeo cada ~1 s) |
| Pings perdidos | 11 |
| Tiempo de corte (timeouts × 1 s) | 11 s |
| Tiempo de corte de reloj (última respuesta → primera respuesta) | 23,0 s |
| `chk-ISP1` activa de nuevo tras `/interface enable ether1` | 5 s |
| BGP 2 established tras `/routing bgp connection enable ISP-1,ISP-2` | 7 s |

Post-mortem:
- Esta vez la ruta cayó por check-gateway y no por link down: tardó 24 s, unos segundos más que la referencia de 10–20 s (la diferencia probablemente sea la espera de cada ping fallido; no medido).
- Se corrió dos veces. En la primera, la consulta del estado de `chk-ISP1` no funcionó (`get ... active` vuelve vacío con la ruta inactiva); el host perdió 11 pings con 22,5 s de corte de reloj y la default pasó a ISP-2 entre +22 s y +26 s. La segunda, con la consulta corregida, es la de la tabla.
- Comparado con la corrida 2 del drill 3: check-gateway cortó 23 s contra 144,5 s de BGP con timers por defecto.
- Al terminar, BGP quedó habilitado con las dos sesiones established y la default por 203.0.113.1 (distancia 20).
