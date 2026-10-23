# Drill 3 — BGP: se cae el proveedor primario (ISP-1)

| Campo | Valor |
|-------|-------|
| Mecanismo | eBGP multi-homing, local-pref 200 (ISP-1) / 100 (ISP-2) |
| Ejecuta | R5 (hosts) + R2 en EDGE y R1 en ISP (rotación F4 R1↔R2) |
| Falla inyectada | Se corta el enlace EDGE `ether1` ↔ ISP-1 |
| Fecha / hora | ____ |

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
| Netwatch marca ISP-1 down a los | ____ s |
| BGP da de baja la sesión a los | ____ s |
| Tiempo de corte total del host | ____ s |
| Tiempo hasta volver a ISP-1 | ____ s |

Valor de referencia: con el link arriba pero sin tráfico, BGP espera al hold-time (180 s por defecto en RouterOS 7).

## Post-mortem

- ¿Por qué netwatch detectó antes que BGP? ____
- ¿Qué pasa con el tráfico que entra desde Internet hacia las LANs durante el corte? ISP-1 sigue teniendo la ruta BGP hasta su propio hold-time. ____
- Mejora posible: `hold-time=9s keepalive-time=3s` en las dos conexiones, o BFD. Probado: sí / no. Resultado: ____
