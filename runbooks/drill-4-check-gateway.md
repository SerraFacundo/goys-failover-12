# Drill 4 — check-gateway: failover estático de enlace (sin BGP)

| Campo | Valor |
|-------|-------|
| Mecanismo | Rutas default estáticas con `check-gateway=ping`, distancia 30 (ISP-1) y 31 (ISP-2) |
| Ejecuta | R5 (hosts) + R2 en EDGE + R1 en ISP (rotación F4) |
| Falla inyectada | Sin BGP, se corta el enlace EDGE ↔ ISP-1 |
| Fecha / hora | ____ |

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
| Pings perdidos | ____ |
| Tiempo de corte | ____ s |

Valor de referencia: check-gateway hace ping cada 10 s y marca el gateway caído tras dos fallas seguidas, o sea entre 10 y 20 s.

## Post-mortem

- Diferencia con el drill 3: acá no hay protocolo de routing, el router solo verifica que el próximo salto responda. Detecta el corte del enlace, pero no un problema más adelante en la red del ISP. ____
- ¿Fue más rápido o más lento que BGP con timers por defecto? ____
- Por qué quedan como respaldo detrás de BGP (distancia 30/31): si BGP funciona, manda BGP; si se caen las dos sesiones, la salida no depende de que BGP vuelva.
