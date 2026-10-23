# Drill 2 — OSPF: se corta el camino EDGE ↔ CORE-1

| Campo | Valor |
|-------|-------|
| Mecanismo | OSPF área 0, enlaces ptp, dos caminos EDGE → CORE |
| Ejecuta | R5 (hosts) + R3 (CORE) |
| Falla inyectada | Se cae el enlace EDGE `ether3` ↔ CORE-1 `ether1` |
| Fecha / hora | ____ |

## Estado previo

```
EDGE>   /routing ospf neighbor print       # 2 vecinos Full: CORE-1 y CORE-2
CORE-1> /routing ospf neighbor print       # 4 vecinos Full
EDGE>   /ip route print where ospf
```
Captura: `capturas/F4/drill2_antes.png`

## Detección

- `/routing ospf neighbor print` en EDGE: desaparece CORE-1 (`10.255.0.2`).
- `/ip route print where ospf` en EDGE: las LANs pasan a salir solo por `10.0.0.6` (CORE-2).
- Netwatch en EDGE: `NETWATCH CORE-1 down`.
- `/log print where topics~"ospf"`.

## Respuesta (inyectar la falla)

1. PC-USER: `ping 198.51.100.100 -t`
2. Cortar el enlace en GNS3: clic derecho sobre el cable EDGE–CORE-1 > **Suspend**.
3. Mirar el ping hasta que vuelva.

Se usa Suspend del cable y no `/interface disable`, porque así ninguno de los dos routers ve caer la interfaz: es el caso real de un enlace que deja de pasar tráfico sin perder link, y OSPF lo tiene que detectar por falta de hellos.

## Recuperación

1. GNS3: clic derecho sobre el cable > **Resume**.
2. Esperar adyacencia Full de nuevo en EDGE y CORE-1.
3. Rutas OSPF de EDGE iguales al estado previo.

Capturas: `drill2_falla.png`, `drill2_recuperado.png`.

## Tiempo medido

| Medición | Valor |
|----------|-------|
| Pings perdidos | ____ |
| Tiempo de corte | ____ s |
| Tiempo hasta Full al volver | ____ s |

Valor de referencia: con los timers por defecto (hello 10 s, dead 40 s) el corte puede llegar a 40 s.

## Post-mortem

- ¿Por qué tardó lo que tardó? ____
- ¿Se perdió todo el tráfico o solo una parte? Los DIST reparten entre CORE-1 y CORE-2; solo el tráfico que pasaba por CORE-1 → EDGE queda cortado hasta el dead interval. ____
- Mejora posible: bajar hello/dead (por ejemplo 1 s / 4 s) en los enlaces ptp, o usar BFD. Costo: más tráfico de control y más sensibilidad a pérdidas puntuales.
